#!/bin/python

from __future__ import print_function
import numpy as np
from sklearn import cross_validation
import sklearn
#import sklearn
import csv
import glob as glob
from PIL import Image
import math
import sys
import os
from sklearn.metrics import mean_squared_error
from math import sqrt
from sklearn.svm import SVC
from scipy import stats
from sklearn.model_selection import KFold

#np.random.seed(1337)  # for reproducibility

#from keras.datasets import mnist
from keras.models import Sequential
from keras.layers import Dense, Dropout, Activation, Flatten
from keras.layers import Convolution2D, MaxPooling2D
from keras.utils import np_utils
from keras import backend as K
from keras.layers.recurrent import LSTM,SimpleRNN
from keras.optimizers import RMSprop,Adadelta
from keras.regularizers import l1, l2, activity_l2

np.random.seed(100)

# Reading the data
allData = np.load('/USC/2016_Continuous_Annotations/data/07-11_functionals_and_labels.npy')
labels = allData[:,-1].astype('float32')
feats = allData[:,:-1].astype('float32')

# Defining our network
my_batch_size = 256 
my_nb_epoch = 5

kf = KFold(n_splits=10,shuffle=True)
all_test_classes,all_test_pred = [],[]
foldI = 1
for train,test in kf.split(feats):
#	print( str(len(train))+' \ '+str(len(test)))
	print('Fold: '+str(foldI))
	foldI += 1
	train_data,train_labels = feats[train].astype('float32'),labels[train]
	test_data,test_labels = feats[test].astype('float32'),labels[test]

	train_classes,test_classes = train_labels,test_labels
	train_labels = np_utils.to_categorical(train_labels).astype('float32')
	test_labels = np_utils.to_categorical(test_labels).astype('float32')

	# Two hidden layers - 500 nodes in the first and 10 nodes in the second. Dropouts between the first and second; and the second and softmax

	my_input_dim = len(train_data[0])
	model = Sequential()
#	model.add(Dense(50,activation='relu',input_dim=my_input_dim))
#	model.add(Dropout(0.2))				# Dropout between the first and second hidden laye
#	model.add(Dense(100,activation='relu'))
#	model.add(Dropout(0.2))
	model.add(Dense(20,activation='relu',input_dim=my_input_dim))
	model.add(Dropout(0.2))
	model.add(Dense(5,activation='softmax'))  	# Uncomment for classification
	model.summary()
	model.compile(loss='categorical_crossentropy',optimizer='adadelta',metrics=['binary_accuracy'])				# Classification

	# Training
	model.fit(train_data, train_labels, batch_size=256, nb_epoch=15,verbose=1)

	# Testing
	train_pred = model.predict_classes(train_data, batch_size=256, verbose=0)
	test_pred = model.predict_classes(test_data, batch_size=256, verbose=0)
#	print('Unweighted average F1score for (train,test) is ('+str(sklearn.metrics.f1_score(train_classes,train_pred,average='macro'))+','+str(sklearn.metrics.f1_score(test_classes,test_pred,average='macro'))+')')
	all_test_classes = np.append(all_test_classes,test_classes)
	all_tet_pred = np.append(all_test_pred,test_pred)

#	break;

print('Final, unweighted average F1score for full dataset is  '+str(sklearn.metrics.f1_score(test_classes,test_pred,average='macro')))


