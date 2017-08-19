#!/usr/bin/env python

###########################################
# WARNING - This code is old and deprecated
###########################################
import os
import sys
import pdb
import re
import glob
import matplotlib as mpl
mpl.use('TkAgg')
import matplotlib.pyplot as plt
import numpy as np
from scipy.stats import pearsonr
from PrettyPlotter import pretty
from FileIO import GetCsvData
from matplotlib2tikz import save as tikz_save

plot_tikz_tex_file = None
#plot_tikz_tex_file = './test.tex'

warp_file_prefix = 'gt_warped'
warp_file_prog = re.compile(warp_file_prefix+'_(\d+)_(\d+).csv')

def GetPercentageFromStr(percentage_str):
   if percentage_str[0] != '0':
      percentage = float(percentage_str)
   else:
      count_zeros = len(percentage_str) - len(str(int(percentage_str)))
      percentage = float(percentage_str)
      percentage *= 10**(-count_zeros)
   percentage /= 100.0
   return percentage

def PlotWarpCorrelations(input_path):
   warp_files = glob.glob(os.path.join(input_path,warp_file_prefix)+'*.csv')
   gt_objective = os.path.join(input_path,'gt_objective.csv')
   gt_objective = np.loadtxt(gt_objective)
   plot_points = {}
   for idx in range(len(warp_files)):
      warp_file = warp_files[idx]
      warp_match = re.search(warp_file_prog, warp_file)
      if not warp_match or len(warp_match.groups()) == 0:
         print 'Error: could not find warp percentage for file %s'%(warp_file)
         continue
      warp_percentage_str = warp_match.group(1)
      correct_percentage_str = warp_match.group(2)
      warp_percentage = GetPercentageFromStr(warp_percentage_str)
      correct_percentage = GetPercentageFromStr(correct_percentage_str)

      warp_sig = np.loadtxt(warp_file)
      min_len = min(len(warp_sig),len(gt_objective))
      warp_sig = warp_sig[0:min_len]
      gt_objective = gt_objective[0:min_len]
      warp_sig = warp_sig-np.mean(warp_sig)
      gt_objective = gt_objective-np.mean(gt_objective)
      p = pearsonr(warp_sig, gt_objective)[0]
      if correct_percentage in plot_points.keys():
         plot_points[correct_percentage] = np.vstack((plot_points[correct_percentage], [warp_percentage, p]))
      else:
         plot_points[correct_percentage] = np.array([warp_percentage, p])

   # Plot the results
   x_break = 0.20001
   legend_label = []
   for correct_percentage in sorted(plot_points.keys(), reverse=True):
      points = np.sort(plot_points[correct_percentage], axis=0)
      break_idx = (points[:,0] < x_break).tolist().index(False)
      plt.plot(points[0:break_idx,0], points[0:break_idx:,1])
      legend_label.append('%d%% Correct'%(correct_percentage*100.0))

   # Plot a dotted line at the baseline correlation value
   plt.plot([0.0,x_break],[0.906, 0.906],'k--')
   legend_label.append('Fused Annotation\nCorrelation')

   ax = plt.gca()
   # ax.set_autoscale_on(False)
   ax.set_autoscale_on(True)
   ax.axis([0,x_break, 0,1], fontsize='small')


   # plt.xlabel('Fraction of Complete Triplet Comparisons', fontsize=24)
   # plt.ylabel('Pearson Correlation', fontsize=24)
   plt.xlabel('Fraction of Complete Triplet Comparisons')
   plt.ylabel('Pearson Correlation')
   pretty(plt)

   # plt.legend(legend_label, loc='upper left', bbox_to_anchor=(1,1), frameon=False, prop={'size':24})
   plt.legend(legend_label)
   if plot_tikz_tex_file is not None:
      tikz_save(plot_tikz_tex_file)
   plt.show()

if __name__=='__main__':
   if len(sys.argv) > 1:
      input_path = sys.argv[1]
      PlotWarpCorrelations(input_path)
   else:
      print 'Please provide the following arguments:\n1) Path to folder containing gt_warped*.csv files'
