#!/bin/bash
# author: Judith Mildner
# edited by Miriam Weaverdyck 7/28/16: converting to spock-compatable, changed epi names from '*epi' to 'epi*'
# Slice timing using FSL
# Keep lines starting with #SBATCH together and at top of script! Modify settings as appropriate.

#SBATCH -J slice_time-%j		# Job name
#SBATCH -p all					# Set partition to 'all' (don't change)
#SBATCH -t 1:00:00				# Set runtime in hh:mm:ss, d-hh, d-hh:mm, mm:ss, or m
#SBATCH --mem 5120				# Set amount of memory in MB (1GB = 1024 MB)

set -e

source globals.sh
# save subject's directory location
cur=`pwd`
# cd to subject's nifti folder
nifti_folder=$NIFTI_DIR
cd $nifti_folder
# for each EPI, perform slice timing
for epi in `ls epi*.nii.gz`; do
slicetimer -i $epi -o "${epi%.nii.gz}_t" --odd
done
# return to subject's directory
cd $cur
