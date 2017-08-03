#!/usr/bin/env python

import os
import sys
import pdb
import subprocess
from compute_constant_intervals import ComputeConstantIntervals
from warp_signal import DoWarpSignal

def GetOutputDir(task):
   scripts_path = os.path.dirname(os.path.realpath(__file__))
   output_dir = os.path.join(scripts_path, '../'+task+'/AnnotationData/pipeline_results')
   return output_dir

def GetGroundTruthFilePath(task, ground_truth_name, frequency):
   gt_file_name = ground_truth_name+'_ground_truth_'+str(frequency)+'hz.csv'
   scripts_path = os.path.dirname(os.path.realpath(__file__))
   gt_file_path = os.path.join(scripts_path, '../'+task+'/AnnotationData/ground_truth_baselines/'+ground_truth_name, gt_file_name)
   return gt_file_path

def GetObjectiveTruthFilePath(task, frequency):
   obj_file_name = task+'_normalized_'+str(frequency)+'hz.csv'
   scripts_path = os.path.dirname(os.path.realpath(__file__))
   obj_file_path = os.path.join(scripts_path, '../'+task+'/AnnotationData/objective_truth/', obj_file_name)
   return obj_file_path

def RunPipeline(do_show_plots):
   # Note: We ignore the 'distort' baseline because this ground truth estimate fills a tiny
   # portion of the full [0,1] output range.  TV denoising is tuned to signals that fill
   # the range.
   tasks = ['TaskA', 'TaskB']
   ground_truth_names = ['simple_average', 'eval_dep']
   frequencies = [10]

   scripts_path = os.path.dirname(os.path.realpath(__file__))
   os.chdir(scripts_path)

   # Run Matlab script to generate baseline ground truths and TV denoise them.
   # The tasks, gt names, and frequencies are specified in the matlab script
   matlab_pipeline_func = 'run_pipeline_gt_tv'
   subprocess.call(['matlab', '-nosplash -nodesktop -r '+matlab_pipeline_func])

   # Extract constant intervals
   for task in tasks:
      output_dir = GetOutputDir(task)
      for ground_truth_name in ground_truth_names:
         for frequency in frequencies:
            tv_file_name = ground_truth_name+'_tv_'+str(frequency)+'hz.csv'
            constant_intervals_file_name = ground_truth_name+'_constant_intervals_'+str(frequency)+'hz.csv'

            # Compute constant intervals from the TV-denoised signals
            tv_file_path = os.path.join(output_dir, tv_file_name)
            output_constant_csv = os.path.join(output_dir, constant_intervals_file_name)
            ComputeConstantIntervals(tv_file_path, output_constant_csv, do_show_plot=do_show_plots)

   # Run Matlab script to construct an embedding from simulated triplets
   # The tasks, gt names, and frequencies are specified in the matlab script
   matlab_embedding_func = 'run_pipeline_embedding'
   subprocess.call(['matlab', '-nosplash -nodesktop -r '+matlab_embedding_func])

   # Warp the baseline ground truth signals according to the interval embedding
   for task in tasks:
      output_dir = GetOutputDir(task)
      for ground_truth_name in ground_truth_names:
         for frequency in frequencies:
            tv_file_name = ground_truth_name+'_tv_'+str(frequency)+'hz.csv'
            constant_intervals_file_name = ground_truth_name+'_constant_intervals_'+str(frequency)+'hz.csv'
            intervals_embedding_file_name = ground_truth_name+'_constant_interval_embedding_retainp100_correctp100_'+str(frequency)+'hz.csv'
            warped_signal_file_name = ground_truth_name+'_warped_'+str(frequency)+'hz.csv'
            ground_truth_file_path = GetGroundTruthFilePath(task, ground_truth_name, frequency)
            obj_truth_file_path = GetObjectiveTruthFilePath(task, frequency)
            tv_file_path = os.path.join(output_dir, tv_file_name)
            constant_intervals_file_path = os.path.join(output_dir, constant_intervals_file_name)
            intervals_embedding_file_path = os.path.join(output_dir, intervals_embedding_file_name)
            warped_signal_file_path = os.path.join(output_dir, warped_signal_file_name)
            DoWarpSignal(ground_truth_file_path, constant_intervals_file_path, intervals_embedding_file_path, obj_truth_file_path, warped_signal_file_path, do_show_plot=do_show_plots)
            

   return

if __name__=='__main__':
   show_plots=False
   if len(sys.argv) > 1:
      if '-p' in str(sys.argv[1]).lower():
         show_plots=True
   RunPipeline(show_plots)
