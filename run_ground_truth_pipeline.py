#/usr/bin/env python

import os

def RunGroundTruthPipeline(tasks):
   os.chdir('scripts')
   os.system('matlab -r compute_ground_truths.m')
   return

if __name__ == '__main__':
   RunGroundTruthPipeline(tasks)
