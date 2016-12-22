#!/usr/bin/python
import os
import sys
import pdb
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

def RemoveIntervalOverlap(intervals):
   last_end_idx = -1
   for i in range(intervals.shape[0]):
      if intervals[i,0] <= last_end_idx:
         intervals[i,0] = last_end_idx+1
      last_end_idx = intervals[i,1]
   return intervals


def DoWarpSignal(signal_csv, intervals_csv, interval_values_csv, output_file):
   if not os.path.isdir(os.path.basename(output_file)):
      os.makedirs(os.path.basename(output_file))

   signal = pd.read_csv(signal_csv, header=None).as_matrix()
   intervals = pd.read_csv(intervals_csv, header=None).as_matrix()
   interval_values = pd.read_csv(interval_values_csv, header=None).as_matrix()

   # For each interval, compute the average signal value
   signal_mean = np.zeros(intervals.shape[0])
   for i in range(intervals.shape[0]):
      interval = intervals[i,:]
      signal_mean[i] = np.mean(signal[interval[0]:interval[1]])

   # Create one matrix for interval bounds and target values
   # Make sure the intervals are sorted ascending by the lower bound
   intervals = np.hstack((intervals, interval_values))
   intervals = intervals[intervals[:,0].argsort()]
   interval_values = intervals[:,-1].astype(float)
   intervals = intervals[:,0:2].astype(int)
   intervals = RemoveIntervalOverlap(intervals)

   # Warp the signal
   warped_signal = np.copy(signal)
   current_frame = 0
   interval_idx = 0
   #last_value = signal[0]
   while current_frame < len(signal):
      # Shift the next interval
      if interval_idx < intervals.shape[0]:
         interval_shift = interval_values[interval_idx] - signal_mean[interval_idx]
         warped_signal[intervals[interval_idx,0]:intervals[interval_idx,1]+1] += interval_shift
         end_frame = intervals[interval_idx,0]-1
      else:
         end_frame = len(signal)-1

      # If not inside the interval just shifted, skew the frames
      # leading up to it
      if current_frame < end_frame:
         if current_frame > 0:
            bias = (warped_signal[current_frame-1] - warped_signal[current_frame]) - (signal[current_frame-1] - signal[current_frame])
         else:
            bias = 0
         scale = warped_signal[end_frame]+interval_shift - (warped_signal[current_frame]+bias)
         warped_signal[current_frame:end_frame+1] = (warped_signal[current_frame:end_frame+1] - warped_signal[current_frame])/(warped_signal[end_frame]-warped_signal[current_frame])*scale + warped_signal[current_frame]+bias
         #for frame_idx in range(current_frame, end_frame):
         #   lerp_scalar = float(end_frame-frame_idx)/(end_frame-current_frame)
         #   warped_signal[frame_idx] = warped_signal[frame_idx] + lerp_scalar*bias + (1.0-lerp_scalar)*interval_shift

      if interval_idx < intervals.shape[0]:
         #last_value = warped_signal[intervals[interval_idx,1]]
         current_frame = intervals[interval_idx,1]+1
         interval_idx += 1
      else:
         current_frame = len(signal)

   # TEMP hack
   ot_signal = pd.read_csv('/USC/2016_Continuous_Annotations/gt_objective.csv', header=None).as_matrix()
   plt.plot(ot_signal, 'k-')

   # Plot the results
   plt.plot(signal, 'b-')
   plt.plot(warped_signal, 'r-')
   plt.xlabel('Time(s)')
   plt.ylabel('Green Saturation')

   # TEMP hack again
   intervals = pd.read_csv('/USC/2016_Continuous_Annotations/intervals.csv', header=None).as_matrix()
   intervals_values = pd.read_csv('/USC/2016_Continuous_Annotations/intervals_embedding.csv', header=None).as_matrix()
   for i in range(intervals.shape[0]):
      interval = intervals[i]
      values = 2*[intervals_values[i]]
      plt.plot(interval, values, 'g-o')

   #plt.legend(['Signal', 'Warped Signal'])
   plt.legend(['Objective', 'Signal', 'Warped Signal', 'Intervals'])
   plt.show()

   np.savetxt(output_file, warped_signal, delimiter=',')

   return warped_signal

if __name__=='__main__':
   if len(sys.argv) > 4:
      signal_csv = sys.argv[1]
      intervals_csv = sys.argv[2]
      interval_values_csv = sys.argv[3]
      output_file = sys.argv[4]
      DoWarpSignal(signal_csv, intervals_csv, interval_values_csv, output_file)
   else:
      print 'Please provide the following arguments:\n1) Path to csv containing signal data\n2) Path to csv containing interval pairs (Nx2 matrix with [left_idx, right_idx] rows)\n3) Path to csv containing new mean values for each interval\n4) Output file'
