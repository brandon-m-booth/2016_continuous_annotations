#!/usr/bin/env python

import os
import sys
import pdb
import math
import numpy as np
import matplotlib.pyplot as plt
from FileIO import GetCsvData
from numpy.linalg import norm
from sklearn.linear_model import OrthogonalMatchingPursuit
from sklearn.linear_model import OrthogonalMatchingPursuitCV

def BuildOMPDictionary(len_signal):
   templates = [('flat', 30, 50), ('line', 60, 100)]

   # TODO - trapezoid?

   num_atoms = 0
   for template in templates:
      min_atom_width = template[1]
      max_atom_width = template[2]
      n = len_signal
      w = min_atom_width
      m = max_atom_width
      num_atoms = num_atoms + -(m-w+1)*(m-2*n+w-2)/2

   atom_idx = 0
   omp_dict = np.zeros((len_signal, num_atoms))
   for template in templates:
      dict_type = template[0]
      min_atom_width = template[1]
      max_atom_width = template[2]
      for atom_width in range(min_atom_width,max_atom_width+1):
         for start_idx in range(len_signal-atom_width+1):
            end_idx = atom_width + start_idx
            if dict_type == 'flat':
               omp_dict[start_idx:end_idx,atom_idx] = 1
            elif dict_type == 'line':
               omp_dict[start_idx:end_idx,atom_idx] = range(start_idx,end_idx)
            else:
               print 'Error: Unknown dictionary element type'
               pdb.set_trace()
            atom_idx = atom_idx + 1
   return omp_dict
   

def ComputeOMP(signal_csv):
   # Data format checking
   try:
      csv_header, csv_data = GetCsvData(signal_csv)
   except IOError:
      print 'Error reading signal csv file'
      pdb.set_trace()
      return
   
   if csv_data.ndim == 1:
      times = range(len(signal))
      signal = csv_data.flatten()
   elif csv_data.ndim == 2 and 'time' in csv_header[0].lower():
      times = csv_data[:,0]
      signal = csv_data[:,1].flatten()
   else:
      print 'Input signal must be one dimensional. Exiting...'
      return
   times.reshape(-1,1)
   signal.reshape(-1,1)
   
   omp_dict = BuildOMPDictionary(len(signal))

   num_atoms_desired = 50
   tolerance = 0.01
   omp = OrthogonalMatchingPursuit(n_nonzero_coefs=num_atoms_desired, fit_intercept=True, normalize=True)
   #omp = OrthogonalMatchingPursuit(tol=tolerance, fit_intercept=True, normalize=True)
   omp.fit(omp_dict, signal)

   atom_indices = omp.coef_.nonzero()
   omp_signal = omp.intercept_
   for atom_index in atom_indices[0]:
      omp_signal = omp_signal + omp_dict[:,atom_index]*omp.coef_[atom_index]
   plt.plot(times, omp_signal, 'r-')
   plt.plot(times, signal, 'b')
   plt.show()


if __name__=='__main__':
   if len(sys.argv) > 1:
      signal_csv = sys.argv[1]
      ComputeOMP(signal_csv)
   else:
      print 'Please provide the following command line arguments:\n1)\n2)'
