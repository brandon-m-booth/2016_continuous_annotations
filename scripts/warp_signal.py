#!/usr/bin/python
import os
import sys
import pdb
import glob
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from pretty_plotter import pretty

do_show_plot = True

def RemoveIntervalOverlap(intervals):
   last_end_idx = -1
   for i in range(intervals.shape[0]):
      if intervals[i,0] <= last_end_idx:
         intervals[i,0] = last_end_idx+1
      last_end_idx = intervals[i,1]
   return intervals


def GetWildcardMatch(wildcard_str, inflated_str):
   if '*' in wildcard_str:
      match_str = inflated_str
      idx = wildcard_str.index('*')
      match_str = match_str.replace(wildcard_str[idx+1:], '')
      match_str = match_str.replace(wildcard_str[0:idx], '')
      return match_str
   else:
      return wildcard_str


def DoWarpSignal(signal_csv, intervals_csv, interval_values_glob, objective_csv, output_file):
   if not os.path.isdir(os.path.basename(output_file)):
      os.makedirs(os.path.basename(output_file))

   interval_values_globs = glob.glob(interval_values_glob)
   for interval_values_csv in interval_values_globs:
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
         if current_frame <= end_frame:
            if current_frame > 0:
               bias = warped_signal[current_frame-1] - signal[current_frame-1]
            else:
               bias = 0
            scale = warped_signal[end_frame]+interval_shift - (warped_signal[current_frame]+bias)
            if end_frame > current_frame:
               warped_signal[current_frame:end_frame+1] = (warped_signal[current_frame:end_frame+1] - warped_signal[current_frame])/(warped_signal[end_frame]-warped_signal[current_frame])*scale + warped_signal[current_frame]+bias
            else:
               warped_signal[current_frame:end_frame+1] = warped_signal[current_frame]+(bias+interval_shift)/2.0
            #for frame_idx in range(current_frame, end_frame+1):
            #   if end_frame > current_frame:
            #      lerp_scalar = float(frame_idx-current_frame)/(end_frame-current_frame)
            #   else:
            #      lerp_scalar = 0.5
            #   warped_signal[frame_idx] = warped_signal[frame_idx] + (1.0-lerp_scalar)*bias + lerp_scalar*interval_shift

         if interval_idx < intervals.shape[0]:
            #last_value = warped_signal[intervals[interval_idx,1]]
            current_frame = intervals[interval_idx,1]+1
            interval_idx += 1
         else:
            current_frame = len(signal)

      sampling_rate = 30.0
      ot_signal = pd.read_csv(objective_csv, header=None).as_matrix()
      plt.plot(np.array(range(0,len(ot_signal)))/sampling_rate, ot_signal, 'm-', linewidth=4)

      # Plot the results
      if do_show_plot:
         plt.plot(np.array(range(0,len(signal)))/sampling_rate, signal, 'c--')
         plt.xlabel('Time(s)', fontsize=24)
         plt.ylabel('Green Value', fontsize=24)

         intervals = pd.read_csv(intervals_csv, header=None).as_matrix()
         for i in range(intervals.shape[0]):
            interval = intervals[i]/sampling_rate
            values = 2*[interval_values[i]]
            if i > 0:
               plt.plot(interval, values, 'g-o', label='_nolegend_')
            else:
               plt.plot(interval, values, 'g-o')

         plt.plot(np.array(range(0,len(warped_signal)))/sampling_rate, warped_signal, 'r-')
         
         pretty(plt)

         plt.axis([0,300,0,1])
         legend_list = ['Objective Truth', 'Average Signal', 'Embedded Intervals', 'Warped Signal']
         plt.legend(legend_list, loc='upper left', bbox_to_anchor=(1,1), frameon=False, prop={'size':24})
         plt.show()

      if '*' in output_file:
         wildcard_match = GetWildcardMatch(interval_values_glob, interval_values_csv)
         outfile = output_file.replace('*', wildcard_match)
      else:
         outfile = output_file
      np.savetxt(outfile, warped_signal, delimiter=',')

if __name__=='__main__':
   if len(sys.argv) > 5:
      signal_csv = sys.argv[1]
      intervals_csv = sys.argv[2]
      interval_values_csv = sys.argv[3]
      objective_csv = sys.argv[4]
      output_file = sys.argv[5]
      DoWarpSignal(signal_csv, intervals_csv, interval_values_csv, objective_csv, output_file)
   else:
      print 'Please provide the following arguments:\n1) Path to csv containing signal data\n2) Path to csv containing interval pairs (Nx2 matrix with [left_idx, right_idx] rows)\n3) Path to csv containing new mean values for each interval\n4) Path to csv containing the objective truth signal\n5) Output file'
