# Continuous Annotation Fusion Correction for Better Ground Truth Estimation

An overview of the methods in this codebase are presented in our paper:

Booth B, Mundnich K, Narayanan S. Continuous real-time annotation fusion correction via rank-based spatial warping. PLOS One Journal [submitted]. 2017.

## Quick Start

From the scripts subfolder run this in a shell:

- python run_pipeline.py -p

This runs all of the steps explained in the paper and generates and caches all of the intermediate stages of the pipeline.  If you do not want to see plots of intermediate results, omit the "-p" flag.

### Prerequisites

- Matlab must be installed a runnable from a shell.  Make sure the matlab executable folder is in the system path.
- TFOCS library requires Matlab R2013b.  If you run with a later version of matlab, you will see errors.
- Python's matplotlib2tikz library
  - sudo -H pip install matplotlib2tikz

## Other Notes

- The annotations were collected using a custom tool build on top of [ROS](http://www.ros.org).  The raw annotation data is stored in *.bag* files, but for convenience we have extracted and pre-processed the data.  For example, TaskA's bags are in the TaskA/AnnotationBags and the extracted time series data can be found in TaskA/AnnotationData.  The raw data is available along with the pre-processed (removed duplicate time stamps) and resampled (10hz or 30hz) data.
- Some of this code is clean and easy to read and reuse while other parts are hastily written for our own experimentation.  If you find this code useful and have questions please let us know! If you wish to borrow portions and find them difficult to reuse or read, please don't hesitate to file an "issue" on github for us to clean up.

## License

Unless otherwise noted in README files in various source code subfolders, all code and data is made available under the MIT license:

Copyright (c) 2017 Brandon M. Booth, Karel Mundnich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
