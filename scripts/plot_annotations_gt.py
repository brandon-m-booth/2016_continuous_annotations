#!/usr/bin/env python
import os
import sys
import pdb
import glob
import numpy as np
import matplotlib as mpl
mpl.use('TkAgg')
import matplotlib.pyplot as plt
from PrettyPlotter import pretty
from FileIO import GetCsvData
from matplotlib2tikz import save as tikz_save

plot_tikz_tex_file = None
#plot_tikz_tex_file = './test.svg'

def PlotAnnotationsAndGroundTruth(annotations_folder, ground_truth_csv_path):
   annotation_files = glob.glob(os.path.join(annotations_folder,'*.csv'))
   gt_header, gt_data = GetCsvData(ground_truth_csv_path, first_line_header=True)

   for idx in range(len(annotation_files)):
      annotation_file = annotation_files[idx]
      dummy_header, annotation_sig_data = GetCsvData(annotation_file, first_line_header=True)
      plt.plot(annotation_sig_data[:,0], annotation_sig_data[:,1])
      #plt.plot(annotation_sig[0:-1:30,0], annotation_sig[0:-1:30,1]) # slices version for better use of memory in TikZ

   plt.plot(gt_data[:,0], gt_data[:,1], 'm-', linewidth=4)
   plt.xlabel('Time(s)', fontsize=24)
   plt.ylabel('Green Intensity', fontsize=24)

   pretty(plt)

   legend_list = []
   for idx in range(len(annotation_files)):
      legend_list.append('Annotator %d'%(idx+1))
   plt.legend(legend_list+['Objective Truth'], loc='upper left', bbox_to_anchor=(1,1), frameon=False, prop={'size':24})

   tikz_save('mytikz.tex')
   plt.show()
   if plot_tikz_tex_file is not None:
      tikz_save(plot_tikz_tex_file)
   plt.show()

if __name__=='__main__':
   if len(sys.argv) > 2:
      annotations_folder = sys.argv[1]
      ground_truth_csv_path = sys.argv[2]
      PlotAnnotationsAndGroundTruth(annotations_folder, ground_truth_csv_path)
   else:
      print 'Please provide the following arguments:\n1) Path to folder containing annotation csv files\n2) Path to ground truth csv file'
