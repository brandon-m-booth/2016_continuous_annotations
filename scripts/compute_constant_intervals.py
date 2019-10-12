#!/usr/bin/env python

import os
import sys
import pdb
import math
import numpy as np
import matplotlib.pyplot as plt
from PrettyPlotter import pretty
from FileIO import GetCsvData, SaveCsvData
from matplotlib2tikz import save as tikz_save

plot_tikz_tex_file = None
#plot_tikz_tex_file = './test.tex'

def ComputeConstantIntervals(signal_csv, output_constant_csv, max_height_threshold=0.003, min_const_time_sec=0.6, do_show_plot=True):
   # Data format checking
   try:
      csv_header, csv_data = GetCsvData(signal_csv)
   except IOError:
      return

   if csv_data.ndim == 1:
      times = range(len(signal))
      signal = csv_data.flatten()
   elif csv_data.ndim == 2 and 'time' in csv_header[0].lower():
      times = csv_data[:,0]
      signal = csv_data[:,1].flatten()
   else:
      print 'Input signal must be one dimensional.  Exiting...'
      return

   # Scan the signal looking for potential constant intervals
   constant_intervals = None
   left_edge_idx = None
   for sig_idx in range(len(signal)):
      if left_edge_idx is None:
         left_edge_idx = sig_idx
         continue
      else:
         height = np.max(signal[left_edge_idx:sig_idx+1]) - np.min(signal[left_edge_idx:sig_idx+1])
         if height < max_height_threshold:
            continue
         else:
            if (sig_idx - left_edge_idx) > 1 and (times[sig_idx]-times[left_edge_idx]) >= min_const_time_sec:
               if constant_intervals is None:
                  constant_intervals = np.array([left_edge_idx, sig_idx-1])
               else:
                  constant_intervals = np.vstack((constant_intervals, [left_edge_idx, sig_idx-1]))
            left_edge_idx = None

   if constant_intervals is None:
      constant_intervals = np.array([[0, len(signal)-1]])
   elif len(constant_intervals.shape) == 1:
      constant_intervals = constant_intervals.reshape(1,-1)

   # Because each constant interval was found scanning through the signal in the
   # forward direction, the interval may not yield the shallowest slope for the function.
   # Check other nearby intervals to see if it gives a better fit.
   for interval_idx in range(constant_intervals.shape[0]):
      left_idx = constant_intervals[interval_idx,0]
      right_idx = constant_intervals[interval_idx,1]
      height = np.max(signal[left_idx:right_idx+1]) - np.min(signal[left_idx:right_idx+1])

      new_height = height 
      offset_idx = 0
      while True:
         new_height = np.max(signal[left_idx:right_idx+1]) - np.min(signal[left_idx:right_idx+1])
         if new_height < height and right_idx+offset_idx < len(signal):
            offset_idx += 1
         else:
            break

      constant_intervals[interval_idx,:] = [left_idx+offset_idx, right_idx+offset_idx]

   # Shrink the intervals to be as small as possible while keeping the signal value as
   # constant as possible
   for interval_idx in range(constant_intervals.shape[0]):
      left_idx = constant_intervals[interval_idx,0]
      right_idx = constant_intervals[interval_idx,1]

      do_shrink = True
      while do_shrink:
         do_shrink = False # Exit if we fail to shrink successfully

         # Prevent intervals from shrinking too much
         if (right_idx - left_idx < 2) or(times[right_idx] - times[left_idx]) < min_const_time_sec:
            break

         abs_slope = math.fabs((signal[right_idx]-signal[left_idx])/(right_idx-left_idx))

         # Greedy approach: shrink the left, then right, then both sides
         if left_idx+1 < len(signal):
            shrink_left_abs_slope = math.fabs((signal[right_idx]-signal[left_idx+1])/(right_idx-(left_idx+1)))
            if shrink_left_abs_slope < abs_slope:
               left_idx += 1
               do_shrink = True
               continue
         if right_idx-1 > 0:
            shrink_right_abs_slope = math.fabs((signal[right_idx-1]-signal[left_idx])/((right_idx-1)-left_idx))
            if shrink_right_abs_slope < abs_slope:
               right_idx -= 1
               do_shrink = True
               continue
         if left_idx+1 < len(signal) and right_idx-1 > 0:
            shrink_both_abs_slope = math.fabs((signal[right_idx-1]-signal[left_idx+1])/(right_idx-left_idx-2))
            if shrink_both_abs_slope < abs_slope:
               left_idx += 1
               right_idx -= 1
               do_shrink = True
               continue

      constant_intervals[interval_idx,:] = [left_idx, right_idx]
      
   # Plot the results
   if do_show_plot:
      plt.plot(times, signal, color='black', linestyle='-.')
      for interval in constant_intervals:
         plt.plot(times[interval], signal[interval], 'g-o')

      plt.xlabel('Time(s)', fontsize=24)
      plt.ylabel('Green Intensity', fontsize=24)
      plt.gca().set_xlim([times[0], times[-1]])
      pretty(plt)
      plt.legend(['TV Denoised', 'Constant Intervals'], loc='upper left', bbox_to_anchor=(1,1), frameon=False, prop={'size':24})
      if plot_tikz_tex_file is not None:
         tikz_save(plot_tikz_tex_file)
      plt.show()

   SaveCsvData(output_constant_csv, None, constant_intervals)
   return


if __name__=='__main__':
   do_show_plot = False
   if len(sys.argv) > 2:
      signal_csv = sys.argv[1]
      output_constant_csv = sys.argv[2]
      if len(sys.argv) > 3 and sys.argv[3] == 'strict':
         max_height_threshold = 0.00001
         min_const_time_sec = 0.2
         ComputeConstantIntervals(signal_csv, output_constant_csv, min_const_time_sec=min_const_time_sec, max_height_threshold=max_height_threshold, do_show_plot=do_show_plot)
      else:
         ComputeConstantIntervals(signal_csv, output_constant_csv, do_show_plot=do_show_plot)
   else:
      print 'Please provide the following command line arguments:\n1) Path to signal csv file\n2) Output constant intervals csv file\n3) (OPTIONAL) Strictness level: "strict", "default"'
