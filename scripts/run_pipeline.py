#!/usr/bin/env python

import os
import sys
import pdb
import subprocess
from compute_constant_intervals import ComputeConstantIntervals
from warp_signal import DoWarpSignal

def GetOutputDir(task):
   scripts_path = os.path.dirname(os.path.realpath(__file__))
   output_dir = os.path.join(scripts_path, '../annotation_tasks/'+task+'/AnnotationData/pipeline_results')
   return output_dir

def GetGroundTruthFilePath(task, ground_truth_name, frequency):
   gt_file_name = ground_truth_name+'_ground_truth_'+str(frequency)+'hz.csv'
   scripts_path = os.path.dirname(os.path.realpath(__file__))
   gt_file_path = os.path.join(scripts_path, '../annotation_tasks/'+task+'/AnnotationData/ground_truth_baselines/'+ground_truth_name, gt_file_name)
   return gt_file_path

def GetObjectiveTruthFilePath(task, frequency):
   obj_file_name = task+'_normalized_'+str(frequency)+'hz.csv'
   scripts_path = os.path.dirname(os.path.realpath(__file__))
   obj_file_path = os.path.join(scripts_path, '../annotation_tasks/'+task+'/AnnotationData/objective_truth/', obj_file_name)
   return obj_file_path

def RunPipeline(do_show_plots):
   tasks = ['TaskA', 'TaskB', 'TaskAvecArousalTrain1', 'TaskAvecArousalTrain2', 'TaskAvecArousalTrain3', 'TaskAvecArousalTrain4', 'TaskAvecArousalTrain5', 'TaskAvecArousalTrain6', 'TaskAvecArousalTrain7', 'TaskAvecArousalTrain8', 'TaskAvecArousalTrain9', 'TaskAvecArousalDev1', 'TaskAvecArousalDev2', 'TaskAvecArousalDev3', 'TaskAvecArousalDev4', 'TaskAvecArousalDev5', 'TaskAvecArousalDev6', 'TaskAvecArousalDev7', 'TaskAvecArousalDev8', 'TaskAvecArousalDev9', 'TaskAvecValenceTrain1', 'TaskAvecValenceTrain2', 'TaskAvecValenceTrain3', 'TaskAvecValenceTrain4', 'TaskAvecValenceTrain5', 'TaskAvecValenceTrain6', 'TaskAvecValenceTrain7', 'TaskAvecValenceTrain8', 'TaskAvecValenceTrain9', 'TaskAvecValenceDev1', 'TaskAvecValenceDev2', 'TaskAvecValenceDev3', 'TaskAvecValenceDev4', 'TaskAvecValenceDev5', 'TaskAvecValenceDev6', 'TaskAvecValenceDev7', 'TaskAvecValenceDev8', 'TaskAvecValenceDev9']
   ground_truth_names = ['simple_average', 'eval_dep', 'distort']
   constant_interval_param_list = [(0.003,17), (0.003,17), (0.003, 17)]
   frequencies = [10, 25]

   scripts_path = os.path.dirname(os.path.realpath(__file__))
   os.chdir(scripts_path)

   # Run Matlab script to generate baseline ground truths and TV denoise them.
   # The tasks, gt names, and frequencies are specified in the matlab script
   print('Generating ground truth baselines and TV denoised signals...')
   matlab_pipeline_func = 'run_pipeline_gt_tv'
   subprocess.call(['matlab', '-nosplash -nodesktop -r '+matlab_pipeline_func])

   # Extract constant intervals
   for task in tasks:
      output_dir = GetOutputDir(task)
      for i in range(len(ground_truth_names)):
         ground_truth_name = ground_truth_names[i]
         constant_interval_params = constant_interval_param_list[i]
         for frequency in frequencies:
            tv_file_name = ground_truth_name+'_tv_'+str(frequency)+'hz.csv'
            constant_intervals_file_name = ground_truth_name+'_constant_intervals_'+str(frequency)+'hz.csv'

            # Compute constant intervals from the TV-denoised signals
            tv_file_path = os.path.join(output_dir, tv_file_name)
            output_constant_csv = os.path.join(output_dir, constant_intervals_file_name)
            print('Computing constant intervals: '+task+', '+ground_truth_name+', '+str(frequency)+' hz');
            ComputeConstantIntervals(tv_file_path, output_constant_csv, do_show_plot=do_show_plots, *constant_interval_params)

   # Run Matlab script to construct an embedding from simulated triplets
   # The tasks, gt names, and frequencies are specified in the matlab script
   print('Generating embedding over constant intervals in the signal...')
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
            print('Warping baseline fused signal using interval embedding: '+task+', '+ground_truth_name+', '+str(frequency)+' hz');
            DoWarpSignal(ground_truth_file_path, constant_intervals_file_path, intervals_embedding_file_path, obj_truth_file_path, warped_signal_file_path, do_show_plot=do_show_plots)
            

   print('Finished!')
   return

if __name__=='__main__':
   show_plots=False
   if len(sys.argv) > 1:
      if '-p' in str(sys.argv[1]).lower():
         show_plots=True
   RunPipeline(show_plots)
