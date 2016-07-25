#!/bin/bash
# author: Judith Mildner
# default -f value is 0.3

set -e # fail immediately on error

source globals.sh

FVALUE=0.4 #-f alue for structural scan skull stripping. Adjust this if stripped anatomical does not look good (default=0.5)

#run BET on topuped epi's
echo 'Running BET on epi runs'
for epi in `ls $NIFTI_DIR/*topup.nii.gz`; do
	bet $epi ${epi%.nii.gz}b -F
done

#run BET on anatomical
echo 'Running BET on structural'
for struct in `ls $NIFTI_DIR/*anat.nii.gz`; do
	bet $struct ${struct%.nii.gz}b -f $FVALUE
done
