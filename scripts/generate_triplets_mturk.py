#!/usr/bin/env python

import os
import sys
import csv
import pdb
import numpy as np
from CsvFileIO import GetCsvData, SaveCsvData

def GenerateTripletsMechanicalTurk(source_video_path, constant_intervals_csv_path, frame_rate, output_mturk_path, url_prefix):
   header = ['ref_video_url', 'a_video_url', 'b_video_url', 'ref_start', 'ref_end', 'a_start', 'a_end', 'b_start', 'b_end']
   url_prefix += os.path.basename(source_video_path)

   intervals = GetCsvData(constant_intervals_csv_path, first_line_header=False)

   n = intervals.shape[0]
   num_triplets = n*(n-1)*(n-2)/2
   data = np.zeros((num_triplets, len(header))).astype(str)
   row_idx = 0
   for i in range(intervals.shape[0]):
      for j in range(intervals.shape[0]):
         if i == j:
            continue
         for k in range(j+1, intervals.shape[0]):
            if i == k:
               continue
            ref_start = '%fs'%(intervals[i,0]/frame_rate)
            ref_end = '%fs'%(intervals[i,1]/frame_rate)
            a_start = '%fs'%(intervals[j,0]/frame_rate)
            a_end = '%fs'%(intervals[j,1]/frame_rate)
            b_start = '%fs'%(intervals[k,0]/frame_rate)
            b_end = '%fs'%(intervals[k,1]/frame_rate)
            data[row_idx] = [url_prefix, url_prefix, url_prefix, ref_start, ref_end, a_start, a_end, b_start, b_end]
            row_idx += 1

   SaveCsvData(output_mturk_path, header, data)
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
