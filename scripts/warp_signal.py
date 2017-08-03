#!/usr/bin/env python
import os
import sys
import pdb
import glob
import matplotlib.pyplot as plt
import numpy as np
from CsvFileIO import GetCsvData, SaveCsvData
from PrettyPlotter import pretty
from matplotlib2tikz import save as tikz_save

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


def DoWarpSignal(signal_csv, intervals_csv, interval_values_glob, objective_csv, output_file, do_show_plot=True):
   if not os.path.isdir(os.path.split(output_file)[0]):
      os.makedirs(os.path.split(output_file)[0])

   interval_values_globs = glob.glob(interval_values_glob)
   for interval_values_csv in interval_values_globs:
      signal_header, signal = GetCsvData(signal_csv)
      dummy_header, intervals = GetCsvData(intervals_csv, first_line_header=False)
      dummy_header, interval_values = GetCsvData(interval_values_csv, first_line_header=False)
      intervals = intervals.astype(int)

      # Separate times from signal
      times = signal[:,0]
      signal = signal[:,1]
      sampling_rate = 1.0/(times[1]-times[0])

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

      # Add time columns back
      signal = np.array((times, signal)).T
      warped_signal = np.array((times, warped_signal)).T

      # Plot the results
      if do_show_plot:
         ot_header, ot_signal = GetCsvData(objective_csv)
         plt.plot(ot_signal[:,0], ot_signal[:,1], 'm-', linewidth=4)

         plt.plot(signal[:,0], signal[:,1], 'c--')
         plt.xlabel('Time(s)', fontsize=24)
         plt.ylabel('Green Intensity', fontsize=24)

         dummy_header, intervals = GetCsvData(intervals_csv, first_line_header=False)
         for i in range(intervals.shape[0]):
            interval = intervals[i]/sampling_rate
            values = 2*[interval_values[i]]
            if i > 0:
               plt.plot(interval, values, 'g-o', label='_nolegend_')
            else:
               plt.plot(interval, values, 'g-o')

         plt.plot(warped_signal[:,0], warped_signal[:,1], 'r-')
         
         pretty(plt)

         plt.axis([times[0],times[-1],0,1])
         legend_list = ['Objective Truth', 'Average Signal', 'Embedded Intervals', 'Warped Signal']
         plt.legend(legend_list, loc='upper left', bbox_to_anchor=(1,1), frameon=False, prop={'size':24})
         if plot_tikz_tex_file is not None:
            tikz_save(plot_tikz_tex_file)
         plt.show()

      if '*' in output_file:
         wildcard_match = GetWildcardMatch(interval_values_glob, interval_values_csv)
         outfile = output_file.replace('*', wildcard_match)
      else:
         outfile = output_file

      SaveCsvData(outfile, ['Time_sec','Data'], warped_signal)

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
