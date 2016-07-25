#!/usr/bin/env bash

# unzip_runs_anat.sh unzips the preprocessed nifitis for all subjects in 
# the subject directory that are required for DARTEL (i.e. the anat 
# all functional runs)
# unzip_runs_anat.sh assumes it is located in /<project dir>/scripts/

source ../globals.sh

#cd $SUBJECTS_DIR
cd $PREP_DIR
for sub in `ls -d s*`; do
	cd "$sub/"	
	gunzip *topup.nii.gz
	gunzip *anat.nii.gz
	echo "$sub niftis are unzipped"
done
