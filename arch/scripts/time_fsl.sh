#!/bin/bash
# author: Judith Mildner

set -e

source globals.sh

cur=`pwd`
nifti_folder=$NIFTI_DIR
cd $nifti_folder
for epi in `ls *epi.nii.gz`; do
slicetimer -i $epi -o "${epi%.nii.gz}_t" --odd
done

cd $cur
