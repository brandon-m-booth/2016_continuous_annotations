#!/usr/bin/python
import os
import sys
import pdb
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from sklearn.manifold import MDS
from scipy.stats import rankdata
from utilsMDS import computeEmbedding

# Input: points (nxd matrix)
def ComputeDistanceMatrix(points):
   dist_mat = np.zeros((points.shape[0], points.shape[0]))
   for i in range(dist_mat.shape[0]):
      for j in range(i+1,dist_mat.shape[1]):
         dist_mat[i,j] = np.linalg.norm(points[i], points[j])
   dist_mat += dist_mat.T
   return dist_mat


def DoOrdinateIntervals(signal_csv, intervals_csv, output_file, comparison_retain_percent=1.0):
   if not os.path.isdir(os.path.basename(output_file)):
      os.makedirs(os.path.basename(output_file))

   signal = pd.read_csv(signal_csv, header=None).as_matrix()
   intervals = pd.read_csv(intervals_csv, header=None).as_matrix()

   # For each interval, compute the average signal value
   signal_mean = np.zeros(intervals.shape[0])
   for i in range(intervals.shape[0]):
      interval = intervals[i,:]
      signal_mean[i] = np.mean(signal[interval[0]:interval[1]])

   # HACK - TEMP
   #for i in range(len(signal_mean)):
   #   signal_mean[i] = float(i)/len(signal_mean)

   # Form triplets such that for each [i,j,k], the signal at
   # index i is closer to then signal at k than j
   n = intervals.shape[0]
   num_triplets = n*(n-1)*(n-2)/2 # n * (n-1)C2
   num_triplets = 2*num_triplets # Worst case if all comparisons are equal
   triplets = np.zeros((num_triplets,3)).astype(int)
   triplet_idx = 0
   diff_eps = 0.01
   for i in range(intervals.shape[0]):
      for j in range(intervals.shape[0]):
         if i == j:
            continue
         for k in range(j+1, intervals.shape[0]):
            if i == k:
               continue
            diff_ij = abs(signal_mean[i]-signal_mean[j])
            diff_ik = abs(signal_mean[i]-signal_mean[k])
            if abs(diff_ik - diff_ij) < diff_eps:
               # If similar, add one triplet for both cases
               #triplets[triplet_idx,:] = [i,j,k]
               #triplet_idx += 1
               #triplets[triplet_idx,:] = [i,k,j]
               #triplet_idx += 1
            elif diff_ik < diff_ij:
               triplets[triplet_idx,:] = [i,j,k]
               triplet_idx += 1
            else:
               triplets[triplet_idx,:] = [i,k,j]
               triplet_idx += 1

   triplets = triplets[np.unique(np.nonzero(triplets)[0]), :] # Remove rows with all zeros

   # Uniformly retain some percentage of the triplets
   np.random.shuffle(triplets)
   num_retain_triplets = round(triplets.shape[0]*comparison_retain_percent)
   triplets = triplets[0:num_retain_triplets, :]

   # Perform the embedding
   # Nowak's NMDS triplets method
   d = 1
   num_restarts = 15
   num_passes = 20
   num_iter = 10
   epsilon = 0.000001
   #epsilon = 0.0000068
   (embedding_triplets, gamma) = computeEmbedding(n, d, triplets, num_random_restarts=num_restarts, max_num_passes=num_passes, max_iter_GD=num_iter, epsilon=epsilon, verbose=True)
   mean_emb = np.mean(embedding_triplets)
   max_emb = np.max(np.abs(embedding_triplets-mean_emb))
   embedding_triplets = (embedding_triplets-mean_emb)/max_emb + mean_emb # Centered and [-1,1]
   embedding_triplets = embedding_triplets.flatten()
   if np.correlate(embedding_triplets,signal_mean-np.mean(signal_mean))[0] >= 0:
      embedding_triplets = 0.5*embedding_triplets + 0.5
   else:
      embedding_triplets = -0.5*embedding_triplets + 0.5

   #embedding_diffs = []
   #for i in range(len(embedding_triplets)):
   #   for j in range(i+1, len(embedding_triplets)):
   #      embedding_diffs.append(abs(embedding_triplets[i] - embedding_triplets[j]))
   #embedding_diffs = np.array(embedding_diffs)
   #embedding_diffs = embedding_diffs[embedding_diffs < 0.00003]
   #plt.hist(embedding_diffs.tolist(), 100)
   #plt.show()
   #pdb.set_trace()

   # Push values that are sufficiently close together to be exactly equal
   #triplet_epsilon = 0.0005
   triplet_epsilon = 0.0001
   for i in range(len(embedding_triplets)):
      for j in range(i+1, len(embedding_triplets)):
         if abs(embedding_triplets[i] - embedding_triplets[j]) < triplet_epsilon:
            embedding_triplets[j] = embedding_triplets[i]
   
   # Rank the results
   #embedding_triplets = rankdata(embedding_triplets, method='min').astype(float)
   #embedding_triplets /= np.max(embedding_triplets)
   print 'Triplet embedding complete.  Gamma is: %f'%(gamma)


   # Sklearn's SMACOF NMDS
   #num_restarts = 100
   #num_iter = 500
   #epsilon = 0.00001
   ##distance_mat = ComputeDistanceMatrix(signal_mean.reshape(len(signal_mean), 1))
   #model = MDS(n_components=1, metric=False, n_init=num_restarts, max_iter=num_iter, eps=epsilon, verbose=1, dissimilarity='euclidean')#dissimilarity='precomputed')
   ##embedding_sklearn = model.fit(distance_mat).embedding_
   #embedding_sklearn = model.fit(signal_mean.reshape(len(signal_mean), 1)).embedding_
   #mean_emb_sklearn = np.mean(embedding_sklearn)
   #max_emb_sklearn = np.max(np.abs(embedding_sklearn-mean_emb_sklearn))
   #embedding_sklearn = (embedding_sklearn-mean_emb_sklearn)/max_emb_sklearn + mean_emb_sklearn # Centered and [-1,1]
   #embedding_sklearn = embedding_sklearn.flatten()
   #if np.correlate(embedding_sklearn,signal_mean)[0] >= 0:
   #   embedding_sklearn= 0.5*embedding_sklearn+ 0.5
   #else:
   #   embedding_sklearn= -0.5*embedding_sklearn+ 0.5
   #print 'SkLearn embedding complete. Stress is: %f'%(model.stress_)


   # Plot the results
   plt.plot(signal, 'b-')
   for i in range(intervals.shape[0]):
      plt.plot(intervals[i,:], 2*[signal_mean[i]], 'r-o')
      plt.plot(intervals[i,:], 2*[embedding_triplets[i]], 'g-o')
      #plt.plot(intervals[i,:], 2*[embedding_sklearn[i]], 'k-o')
      plt.xlabel('Time(s)')
      plt.ylabel('Green Saturation')
      #plt.legend(['Signal', 'Intervals', 'Triplets', 'Sklearn'])
      plt.legend(['Signal', 'Intervals', 'Triplets'])
   plt.show()

   np.savetxt(output_file, embedding_triplets, delimiter=',')
   return

if __name__=='__main__':
   if len(sys.argv) > 3:
      signal_csv = sys.argv[1]
      intervals_csv = sys.argv[2]
      output_file = sys.argv[3]
      if len(sys.argv) > 4:
         comparison_retain_percent = float(sys.argv[4])
      else:
         comparison_retain_percent = 1.0
      DoOrdinateIntervals(signal_csv, intervals_csv, output_file, comparison_retain_percent)
   else:
      print 'Please provide the following arguments:\n1) Path to csv containing signal data\n2) Path to csv containing interval pairs (Nx2 matrix with [left_idx, right_idx] rows)\n3) Output file'
