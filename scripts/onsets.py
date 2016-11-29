#/bin/env python2.7
#
#
#
#

import argparse
import csv
import glob
import collections
import os


parser = argparse.ArgumentParser(description='This script pulls the SFNR values from each bxh qa index.html file. -JM')
parser.add_argument('-t','--task', help='Task name (as specified in behav filename)',required=True)
parser.add_argument('-T','--TSK',help='Task name in study_info.par and used throughout study dir (3 uppercase letters, e.g. TSK)',required=True)
parser.add_argument('-s','--sub',help='subject', required=True)
parser.add_argument('-tr','--TR',help='TR for this task', required=True)
parser.add_argument('-v','--volumes',help='number of volumes for this task', required=True)
parser.add_argument('-p','--path',help='path to behav data files', required=False)
parser.add_argument('-c','--columns',help='order of columns in csv',required=False)
parser.add_argument('-o','--onsetcolumn',help='name of onset column in csv',required=False)
parser.add_argument('-d','--durcolumn',help='name of duration column in csv',required=False)
parser.add_argument('-con','--conditions',help='conditions (trialtype in columns)',required=False)

args = parser.parse_args()

subject = args.sub
path = args.path if args.path != None else '/jukebox/tamir/jmildner/soc_dep_behavioral_scanner/'
task = args.task
tsk = args.TSK
cols = args.columns
onset = args.onsetcolumn
dur = args.durcolumn
TR = args.TR
vols = args.volumes

search_path=path+subject+'/s*_*'+task+'*'

bfiles=sorted(glob.glob(search_path))
run_dur=float(TR)*float(vols)
onsets = collections.defaultdict(list)
durs = collections.defaultdict(list)
for idx,bfile in enumerate(bfiles):
	sel=[]
	print "Processing "+bfile
	with open(bfile) as bfile:
		line1=bfile.readline()
		sub,trialtype,totaldur,statenum,trialtypnum,resp1,respf,rt1,rtf,dk,onset = line1.strip().split("\t")
		t1=float(onset)
		onset=float(onset)-t1
		dur=float(rtf) if float(rtf) != 0 else float(totaldur)
		trialtype=trialtype.strip()
		onsets[trialtype].append(onset+(idx*run_dur))
		durs[trialtype+'_dur'].append(dur)
		reader=csv.reader(bfile,delimiter='\t')
		try:
			for sub,trialtype,totaldur,statenum,trialtypnum,resp1,respf,rt1,rtf,dk,onset in reader:
				onset=float(onset)
				onset=onset-t1
				trialtype=trialtype.strip()	
				dur=float(rtf) if float(rtf) != 0 else float(totaldur)
				
				durs[trialtype+'_dur'].append(dur)
				
				onsets[trialtype].append(onset+(idx*run_dur))
		except ValueError:
			pass

for trial in onsets:
	path='/fastscratch/jmildner/socdep1016/auxil/onsets/'+tsk+'/'
	try: 
    		os.makedirs(path)
	except OSError:
    		if not os.path.isdir(path):
	        	raise	

	with open(path+subject+'_'+trial+'.txt', 'w+') as f:
		for item in onsets[trial]:
			print >>f, item		
for dur in durs:
	with open(path+subject+'_'+dur+'.txt', 'w+') as f:
		for item in durs[dur]:
			print >>f, item		




