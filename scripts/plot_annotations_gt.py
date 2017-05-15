#!/usr/bin/python
import os
import sys
import pdb
import glob
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from pretty_plotter import pretty

def PlotAnnotationsAndGroundTruth(annotations_folder, ground_truth_csv_path):
   annotation_files = glob.glob(os.path.join(annotations_folder,'*.csv'))
   gt_objective_dataframe = pd.read_csv(ground_truth_csv_path)
   gt_objective = gt_objective_dataframe.as_matrix()

   for idx in range(len(annotation_files)):
      annotation_file = annotation_files[idx]
      annotation_sig_dataframe = pd.read_csv(annotation_file)
      annotation_sig = annotation_sig_dataframe.as_matrix()
      plt.plot(annotation_sig[:,0], annotation_sig[:,1])

   plt.plot(gt_objective[:,0], gt_objective[:,1], 'm-', linewidth=4)
   
   plt.xlabel('Time(s)', fontsize=24)
   plt.ylabel('Green Value', fontsize=24)

   pretty(plt)

   legend_list = []
   for idx in range(len(annotation_files)):
      legend_list.append('Annotator %d'%(idx+1))
   plt.legend(legend_list+['Objective Truth'], loc='upper left', bbox_to_anchor=(1,1), frameon=False, prop={'size':24})

   plt.show()

if __name__=='__main__':
   if len(sys.argv) > 2:
      annotations_folder = sys.argv[1]
      ground_truth_csv_path = sys.argv[2]
      PlotAnnotationsAndGroundTruth(annotations_folder, ground_truth_csv_path)
   else:
      print 'Please provide the following arguments:\n1) Path to folder containing annotation csv files\n2) Path to ground truth csv file'
