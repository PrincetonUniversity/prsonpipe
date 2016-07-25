#!/bin/bash
# author: Judith Mildner

set -e

source globals.sh

cur=`pwd`
nifti_folder=$NIFTI_DIR
cd $nifti_folder
LOCATION=`pwd`
SE_AP="${LOCATION}/${SUBJ}_epi_SE_AP.nii.gz"
for epi in `ls *_epi_t.nii.gz`; do

mcflirt -in $epi -refvol $SE_AP -plots -mats

done

cd $cur

