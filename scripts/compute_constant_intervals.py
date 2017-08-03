#!/usr/bin/python

import os
import sys
import csv
import pdb
import math
import numpy as np
import pandas as pd
# import matplotlib as mpl
# mpl.use('TkAgg')
import matplotlib.pyplot as plt
from pretty_plotter import pretty
from matplotlib2tikz import save as tikz_save

def ComputeConstantIntervals(signal_csv, output_constant_csv, do_show_plot=True):
   max_height_threshold = 0.003
   min_const_frames = 18
    
   signal = pd.read_csv(signal_csv).as_matrix().astype(float)
   # signal = pd.read_csv(signal_csv).as_matrix().astype(float)[0:-1:30]

   if signal.ndim != 1 and (signal.ndim != 2 or min(signal.shape) != 1):
      print 'Input signal must be one dimensional.  Exiting...'
      return

   signal = signal.flatten()
   
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
            if (sig_idx-left_edge_idx) >= min_const_frames:
               if constant_intervals is None:
                  constant_intervals = np.array([left_edge_idx, sig_idx-1])
               else:
                  constant_intervals = np.vstack((constant_intervals, [left_edge_idx, sig_idx-1]))
            left_edge_idx = None

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
         if (right_idx - left_idx) < min_const_frames:
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
      plt.plot(np.array(range(len(signal)))/30.0, signal, color='black', linestyle='-.')
      for interval in constant_intervals:
         plt.plot(np.array(interval)/30.0, signal[interval], 'g-o')

      plt.xlabel('Time(s)', fontsize=24)
      plt.ylabel('Green Value', fontsize=24)
      plt.gca().set_xlim([0,len(signal)/30])
      pretty(plt)
      plt.legend(['TV Denoised', 'Constant Intervals'], loc='upper left', bbox_to_anchor=(1,1), frameon=False, prop={'size':24})
      plt.savefig('./test.svg', transparent=True)
      # plt.show()
      tikz_save('mytikz.tex')

   with open(output_constant_csv, 'wb') as outfile:
      csv_writer = csv.writer(outfile)
      csv_writer.writerows(constant_intervals)
   

if __name__=='__main__':
   if len(sys.argv) > 2:
      signal_csv = sys.argv[1]
      output_constant_csv = sys.argv[2]
      ComputeConstantIntervals(signal_csv, output_constant_csv)
   else:
      print 'Please provide the following command line arguments:\n1) Path to signal csv file\n2) Output constant intervals csv file'
