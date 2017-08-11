#!/usr/bin/env python

import os
import sys
import csv
import pdb
import math
import numpy as np
from CsvFileIO import GetCsvData, SaveCsvData

max_hits_per_batch = 5000

def GenerateTripletsMechanicalTurk(source_video_path, constant_intervals_csv_path, frame_rate, output_mturk_path, url_prefix):
   header = ['ref_video_url', 'a_video_url', 'b_video_url', 'ref_start', 'ref_end', 'a_start', 'a_end', 'b_start', 'b_end']
   url_prefix += os.path.basename(source_video_path)

   dummy_header, intervals = GetCsvData(constant_intervals_csv_path, first_line_header=False)

   n = intervals.shape[0]
   num_triplets = n*(n-1)*(n-2)/2
   data = np.zeros((num_triplets, len(header))).astype(object)
   row_idx = 0
   for i in range(intervals.shape[0]):
      for j in range(intervals.shape[0]):
         if i == j:
            continue
         for k in range(j+1, intervals.shape[0]):
            if i == k:
               continue
            ref_start = '%f'%(intervals[i,0]/frame_rate)
            ref_end = '%f'%(intervals[i,1]/frame_rate)
            a_start = '%f'%(intervals[j,0]/frame_rate)
            a_end = '%f'%(intervals[j,1]/frame_rate)
            b_start = '%f'%(intervals[k,0]/frame_rate)
            b_end = '%f'%(intervals[k,1]/frame_rate)
            data[row_idx] = [url_prefix, url_prefix, url_prefix, ref_start, ref_end, a_start, a_end, b_start, b_end]
            row_idx += 1

   num_batches = int(math.ceil(float(data.shape[0])/max_hits_per_batch))
   for i in range(num_batches):
      output_mturk_folder = os.path.dirname(output_mturk_path)
      output_mturk_file_name = os.path.basename(output_mturk_path)
      if len(output_mturk_file_name.split('.')) > 1:
         (file_name, ext) = output_mturk_file_name.split('.')
         output_mturk_batch_file = os.path.join(output_mturk_folder, file_name+'_batch_'+str(i)+'.'+ext)
      else:
         output_mturk_batch_file = os.path.join(output_mturk_folder, output_mturk_file_name+'_batch_'+str(i))
      start_row = i*max_hits_per_batch
      end_row = min((i+1)*max_hits_per_batch, data.shape[0])
      SaveCsvData(output_mturk_batch_file, header, data[start_row:end_row])
   return

if __name__=='__main__':
   if len(sys.argv) > 5:
      source_video_path = sys.argv[1]
      constant_intervals_csv_path = sys.argv[2]
      frame_rate = float(sys.argv[3])
      output_mturk_path = sys.argv[4]
      url_prefix = sys.argv[5]
      GenerateTripletsMechanicalTurk(source_video_path, constant_intervals_csv_path, frame_rate, output_mturk_path, url_prefix)
   else:
      print 'Please provide the following command line arguments:\n1) Path to source video file\n2) Path to constant intervals csv\n3) The frame rate of the constant intervals file\n4) Output Mechanical Turk file\n5) Url prefix, for example: http://my.server:1234/'
