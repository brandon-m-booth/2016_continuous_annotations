# Continuous Annotation Fusion Correction for Better Ground Truth Estimation

An overview of the methods in this codebase are presented in our paper:

Booth B, Mundnich K, Narayanan S. Continuous real-time annotation fusion correction via rank-based spatial warping. PLOS One Journal [submitted]. 2017.

## Quick Start

From the scripts subfolder run this in a shell:

* python run_pipeline.py -p

This runs all of the steps explained in the paper and generates and caches all of the intermediate stages of the pipeline.  You must have matlab installed and added to the system path so it can be run from the command line.  If you do not want to see plots of intermediate results, omit the "-p" flag.

## Other Notes

- The annotations were collected using a custom tool build on top of [ROS](http://www.ros.org).  The raw annotation data is stored in *.bag* files, but for convenience we have extracted and pre-processed the data.  For example, TaskA's bags are in the TaskA/AnnotationBags and the extracted time series data can be found in TaskA/AnnotationData.  The raw data is available along with the pre-processed (removed duplicate time stamps) and resampled (10hz or 30hz) data.
- Some of this code is clean and easy to read and reuse while other parts are hastily written for our own experimentation.  If you find this code useful and have questions please let us know! If you wish to borrow portions and find them difficult to reuse or read, please don't hesitate to file an "issue" on github for us to clean up.
