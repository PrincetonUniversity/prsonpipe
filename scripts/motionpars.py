#!/bin/env python2.7



import glob
import math
import os.path
import csv

prep_path='/fastscratch/jmildner/socdep1016/prep/SHA/aFrFuFwDsD/'

sub_paths=glob.glob(prep_path+'/s*')

for path in sub_paths:
	write_path,subject=os.path.split(path)
	parfiles=glob.glob(path+'/*.par')
	dists=[]
	counts_s=[]
	counts_b=[]
	for idx,parfile in enumerate(parfiles):
		countbig=0
		countsmall=0
		with open(parfile) as pfile:
			lines=pfile.readlines()
			tx=[]
			ty=[]
			tz=[]
			d=[]
			for i,line in enumerate(lines):
				rx,ry,rz,x,y,z=line.split()
				tx.append(x)
				ty.append(y)
				tz.append(z)
				if i > 0:
					dist=math.sqrt(math.pow(float(tx[i])-float(tx[i-1]),2) + math.pow(float(ty[i])-float(ty[i-1]),2) + math.pow(float(tz[i])-float(tz[i-1]),2))
					d.append(dist)
					if dist > 2:
						countbig+=1
					elif dist > 0.5:
						countsmall+=1
		dists.append(d)
		counts_s.append(countsmall)
		counts_b.append(countbig)
	write_file=write_path+'/dists_'+subject+'.csv'
	with open(write_file,'wb') as f:
 	   csv.writer(f).writerows(zip(*dists))
 	   f.write('small\n1,2,3,4\n')
 	   csv.writer(f).writerow(counts_s)
 	   f.write('big\n1,2,3,4\n')
 	   csv.writer(f).writerow(counts_b)
