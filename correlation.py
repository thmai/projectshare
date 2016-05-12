#!/usr/bin/python

import numpy as np
import csv, sys
import matplotlib.pyplot as plt

filename = 'XD edit suvery input template.xlsx - Cleaned Data.csv'

reader = csv.reader(open(filename,'r'),delimiter=',')
data=np.array([line for line in reader])

#print data[2049,151]
#np.set_printoptions(threshold=np.nan)

for index, x in np.ndenumerate(data):
        if 
        if x == '#N/A':
                data[index] = 0

#x = x.astype(float)

#print data[:,0], '\n', data[:,1]
correl = [np.corrcoef(data[:,i],data[:,j])[1,1] for i in range(len(data[0])) for j in range(len(data[0]))]
print correl
