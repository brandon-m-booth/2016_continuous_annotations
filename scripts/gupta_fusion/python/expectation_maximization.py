#!/usr/bin/python

import os
import re
import sys
import pdb
import glob
import math
import signal
import numpy as np
from scipy import stats
from lsqnonneg import lsqnonneg
sys.path.insert(0, os.path.join(sys.path[0], '../..'))
import CsvFileIO

w = 8

def debug_signal_handler(signal, frame):
   pdb.set_trace()

def ExtractTimeshiftedMatrixFromVec(vec, m, n):
   X = np.zeros((m,n))
   for i in range(m):
      temp_vec = np.zeros(n)
      num_elements = min(i+1,n)
      start_idx = max(i-num_elements+1, 0)
      end_idx = i+1
      element_vec = vec[start_idx:end_idx]
      start_idx = n-num_elements
      end_idx = n+2
      temp_vec[start_idx:end_idx] = element_vec
      X[i,:] = temp_vec
   return X

def ExtractTkFromVec(t_vec, t):
   w = len(t_vec)
   t_k = np.zeros((t,t))
   for i in range(t):
      temp_vec = np.zeros(t);
      num_elements = min(i+1,w)
      start_idx = w-num_elements
      end_idx = w
      element_vec = t_vec[start_idx:end_idx]
      start_idx = max(i-w+1,0)
      end_idx = i+1
      temp_vec[start_idx:end_idx] = element_vec
      t_k[i,:] = temp_vec

   return t_k

def FindNormPDF(X, mu, sigma):
   return math.log(stats.norm.pdf(X, mu, sigma))

def ComputeLikelihood(feature_dict, annotation_dict, unique_annotator_ids, unique_session_ids, a_star, theta, sigma_m, t_k, sigma_k):
   log_likelihood = 0
   num_annotation_dimensions = annotation_dict.itervalues().next()['annotation'].shape[1]
   num_annotator_ids = len(unique_annotator_ids)
   for annotation_key in annotation_dict.keys():
      prob_An_given_a_star = 0
      prob_a_star_given_X = 0
      session_id = annotation_dict[annotation_key]['session_id']
      cur_annotator_id = annotation_dict[annotation_key]['annotator_id']
      cur_annotation = annotation_dict[annotation_key]['annotation']
      cur_annotation_flat = cur_annotation.flatten()
      num_frames = cur_annotation.shape[0]
      mat = np.zeros((num_frames, num_annotation_dimensions))
      cur_a_star = a_star[session_id]

      for annotation_dim_idx in range(num_annotation_dimensions):
         cur_T_k = ExtractTkFromVec(t_k[:,annotation_dim_idx,cur_annotator_id], num_frames)
         mat[:,annotation_dim_idx] = np.dot(cur_T_k, cur_a_star[:,annotation_dim_idx])
      mat_flat = mat.flatten()

      for i in range(len(cur_annotation_flat)):
         prob_An_given_a_star += FindNormPDF(cur_annotation_flat[i]-mat_flat[i], 0, sigma_k[cur_annotator_id])

      features_mat = np.dot(feature_dict[session_id], theta)
      features_mat_flat = features_mat.flatten()
      
      for i in range(len(cur_a_star)):
         session_idx = unique_session_ids.tolist().index(session_id)
         prob_a_star_given_X += FindNormPDF(cur_a_star[i]-features_mat_flat[i], 0, sigma_m[session_idx])

      log_likelihood += prob_An_given_a_star + prob_a_star_given_X

   return log_likelihood


def MaximizationStep(feature_dict, a_star, theta, annotation_dict, t_k, unique_annotator_ids, unique_session_ids):
   eps = 1e-15
   num_sessions = len(unique_session_ids)
   num_annotator_ids = len(unique_annotator_ids)
   num_features = feature_dict.itervalues().next().shape[1]
   num_annotation_dimensions = annotation_dict.itervalues().next()['annotation'].shape[1]
   sigma_k = np.zeros(num_annotator_ids)
   sigma_m = np.zeros(num_sessions)

   for session_index in range(len(unique_session_ids)):
      session_id = unique_session_ids[session_index]
      cur_a_star = a_star[session_id]
      cur_features_mat = feature_dict[session_id]

      # Find the first annotation matching the session_id
      num_frames = None
      num_annotation_dimensions = None
      for annotation_key in annotation_dict.keys():
         if annotation_dict[annotation_key]['session_id'] == session_id:
            (num_frames, num_annotation_dimensions) = annotation_dict[annotation_key]['annotation'].shape
            break
      sigma_m[session_index] = math.sqrt(np.sum(np.square(cur_a_star - np.dot(cur_features_mat,theta.reshape(-1,1))))/(num_frames*num_annotation_dimensions-1))

   for annotator_id in unique_annotator_ids:
      # Get list of all annotations from this annotator
      annotator_files = []
      for annotation_key in annotation_dict.keys():
         if annotation_dict[annotation_key]['annotator_id'] == annotator_id:
            annotator_files.append(annotation_key)

      for dimension_idx in range(num_annotation_dimensions):
         t_k_X = np.array([])
         t_k_y = np.array([])

         num_noise_terms = 0
         for annotation_file in annotator_files:
            session_id = annotation_dict[annotation_file]['session_id']
            cur_a_star = a_star[session_id]
            cur_annotation = annotation_dict[annotation_file]['annotation']
            num_frames = cur_annotation.shape[0]

            temp_vec = cur_a_star[:,dimension_idx]
            M = ExtractTimeshiftedMatrixFromVec(temp_vec, num_frames, w)
            if t_k_X.shape[0]:
               t_k_X = np.vstack((t_k_X, M))
               t_k_y = np.vstack((t_k_y, cur_annotation[:,dimension_idx]))
            else:
               t_k_X = M
               t_k_y = cur_annotation[:,dimension_idx]

            cur_T_k = ExtractTkFromVec(t_k[:,dimension_idx,annotator_id], num_frames)
            sigma_k[annotator_id] += np.sum(np.square(np.sum(cur_annotation[:,dimension_idx].reshape(-1,1) - np.dot(cur_T_k,cur_a_star[:,dimension_idx].reshape(-1,1)), axis=0)))
            num_noise_terms += num_frames
            
         t_k[:,dimension_idx,annotator_id] = lsqnonneg(t_k_X,t_k_y)[0]

      sigma_k[annotator_id] = math.sqrt(sigma_k[annotator_id]/(num_noise_terms-1))

   XbarX = np.zeros((num_features, num_features))
   Xbary = np.zeros((num_features, num_annotation_dimensions))

   # Estimate theta
   for session_id in unique_session_ids:
      cur_a_star = a_star[session_id]
      cur_features_mat = feature_dict[session_id]
      XbarX += np.dot(cur_features_mat.T, cur_features_mat)
      Xbary += np.dot(cur_features_mat.T, cur_a_star)

   if math.fabs(1.0/np.linalg.cond(XbarX)) < eps:
      XbarX += np.identity(num_features)

   theta = np.dot(np.linalg.inv(XbarX), Xbary)
   return (t_k, sigma_k, theta, sigma_m)


def ExpectationStep(feature_dict, a_star, annotation_dict, unique_annotator_ids, unique_session_ids, t_k, theta):
   eps = 1e-15
   num_sessions = len(unique_session_ids)
   num_annotator_ids = len(unique_annotator_ids)
   (num_frames,num_annotation_dimensions) = annotation_dict[annotation_dict.keys()[0]]['annotation'].shape
   a_star = {}

   for session_id in unique_session_ids:
      # Get list of annotations pertaining to this session
      session_files = []
      for annotation_key in annotation_dict.keys():
         if annotation_dict[annotation_key]['session_id'] == session_id:
            session_files.append(annotation_key)

      # Get length of annotation for this session (should be the same length for all files)
      num_feature_dimensions = feature_dict[session_id].shape[1]
      (num_frames,num_annotation_dimensions) = annotation_dict[session_files[0]]['annotation'].shape
      cur_a_star = np.ones((num_frames,num_annotation_dimensions))

      for dimension_idx in range(num_annotation_dimensions):
         XTX = np.zeros((num_frames,num_frames))
         XTy = np.zeros((num_frames,1))

         for annotation_file in session_files:
            annotation_mat = annotation_dict[annotation_file]['annotation']
            annotator_id = annotation_dict[annotation_file]['annotator_id']
            
            y = annotation_mat[:,dimension_idx].reshape(-1,1)
            X = ExtractTkFromVec(t_k[:,dimension_idx,annotator_id], num_frames)
            XTX += np.dot(X.T,X)
            XTy += np.dot(X.T,y)

         XTX += np.identity(num_frames)
         XTy += np.dot(feature_dict[session_id], theta[:,dimension_idx].reshape(-1,1))

         if math.fabs(1.0/np.linalg.cond(XTX)) < eps:
            XTX += np.identity(num_frames)

         cur_a_star[:,dimension_idx] = np.dot(np.linalg.inv(XTX), XTy).flatten()

      a_star[session_id] = cur_a_star

   return a_star

def ExpectationMaximization(raw_annotations_csv_folder, features_csv_folder, output_csv_path, max_iters=100000000, convergence_threshold=0.1):
   # Get annotation data, and session and annotator IDs
   session_annotator_id_re = re.compile('(.*?)_annotated.*annotator(\d*)_label\.csv')
   annotation_files = glob.glob(os.path.join(raw_annotations_csv_folder,'*.csv'))
   unique_annotator_ids = []
   unique_session_ids = []
   annotation_dict = {}
   for annotation_file in annotation_files:
      re_match = re.match(session_annotator_id_re, os.path.basename(annotation_file))
      if re_match and len(re_match.groups()) > 0:
         session_id = re_match.group(1)
         annotator_id = int(re_match.group(2))
         unique_session_ids.append(session_id)
         unique_annotator_ids.append(annotator_id)
         (annotation_header, annotation_data) = CsvFileIO.GetCsvData(annotation_file, first_line_header=True)
         if len(annotation_header) > 0 and 'time' in annotation_header[0].lower():
            annotation_data = annotation_data[:,1:]
         annotation_dict[annotation_file] = {'session_id': session_id, 'annotator_id': annotator_id, 'annotation':annotation_data}
   unique_session_ids = np.unique(unique_session_ids)
   unique_annotator_ids = np.unique(unique_annotator_ids)

   # Get features data
   feature_session_id_re = re.compile('(.*?)_.*\.csv')
   features_files = glob.glob(os.path.join(features_csv_folder,'*.csv'))
   feature_dict = {}
   for features_file in features_files:
      re_match = re.match(feature_session_id_re, os.path.basename(features_file))
      if re_match and len(re_match.groups()) > 0:
         session_id = re_match.group(1)
         (features_header, features_data) = CsvFileIO.GetCsvData(features_file, first_line_header=True)
         if len(features_header) > 0 and 'time' in features_header[0].lower():
            features_data = features_data[:,1:]
         if session_id in feature_dict.keys():
            feature_dict[session_id]= np.hstack((feature_dict[session_id], features_data))
         else:
            feature_dict[session_id] = features_data

   # Make sure features and annotations have the same number of frames per session. Truncate the end if necessary.
   for session_id in unique_session_ids:
      min_num_frames = feature_dict[session_id].shape[0]
      for annotation_key in annotation_dict.keys():
         if annotation_dict[annotation_key]['session_id'] == session_id:
            min_num_frames = min(min_num_frames, annotation_dict[annotation_key]['annotation'].shape[0])

      feature_dict[session_id] = feature_dict[session_id][0:min_num_frames,:]
      for annotation_key in annotation_dict.keys():
         if annotation_dict[annotation_key]['session_id'] == session_id:
            annotation_dict[annotation_key]['annotation'] = annotation_dict[annotation_key]['annotation'][0:min_num_frames,:]

   # Initialize variables
   num_sessions = len(unique_session_ids)
   num_annotator_ids = len(unique_annotator_ids)
   num_annotation_dimensions = annotation_dict.itervalues().next()['annotation'].shape[1]
   num_features = feature_dict.itervalues().next().shape[1]
   old_log_likelihood = 100000
   eps = 0.0001
   a_star = {}
   for session_id in unique_session_ids:
      # Get annotations pertaining to this session
      annotations = np.array([])
      for annotation_key in annotation_dict.keys():
         if annotation_dict[annotation_key]['session_id'] == session_id:
            if annotations.shape[0]:
               annotations = np.hstack((annotations, annotation_dict[annotation_key]['annotation']))
            else:
               annotations = annotation_dict[annotation_key]['annotation']
      a_star[session_id] = np.mean(annotations, axis=1).reshape(-1,1)
   t_k = np.loadtxt('../t_k', delimiter=',')
   t_k = t_k.reshape(8,1,11)
   theta = np.loadtxt('../theta')
   #t_k = np.random.rand(w, num_annotation_dimensions, num_annotator_ids)
   #theta = np.random.rand(num_features, num_annotation_dimensions)
   (t_k, sigma_k, theta, sigma_m) = MaximizationStep(feature_dict, a_star, theta, annotation_dict, t_k, unique_annotator_ids, unique_session_ids)

   print 'Data loaded, starting EM...'
   # Expectation maximization
   iter_counter = 0
   while(True):
      a_star = ExpectationStep(feature_dict, a_star, annotation_dict, unique_annotator_ids, unique_session_ids, t_k, theta)
      (t_k, sigma_k, theta, sigma_m) = MaximizationStep(feature_dict, a_star, theta, annotation_dict, t_k, unique_annotator_ids, unique_session_ids)
      log_likelihood = ComputeLikelihood(feature_dict, annotation_dict, unique_annotator_ids, unique_session_ids, a_star, theta, sigma_m, t_k, sigma_k)

      if iter_counter == max_iters or abs(old_log_likelihood - log_likelihood) < convergence_threshold:
         break
      else:
         iter_counter += 1
         print 'Iter %d, Log likelihood: %f'%(iter_counter, log_likelihood)
         old_log_likelihood = log_likelihood
   
   # Output results
   np.savetxt(output_csv_path, a_star)
   print 'Sigma_m: '+str(sigma_m)
   print 'Theta: '+str(theta)
   print 'T_k: '+str(t_k)
   print 'Sigma_k: '+str(sigma_k)
   return

if __name__ == '__main__':
   signal.signal(signal.SIGINT, debug_signal_handler)
   if len(sys.argv) > 3:
      raw_annotations_csv_folder = sys.argv[1]
      features_csv_folder = sys.argv[2]
      output_csv_path = sys.argv[3]
      ExpectationMaximization(raw_annotations_csv_folder, features_csv_folder, output_csv_path)
   else:
      print 'Please provide the following command line arguements:\n1) Raw annotations csv folder path\n2) Features csv folder path\n3) Output fused signal path'

