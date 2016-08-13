#!/bin/bash
# author: Judith Mildner
# edited by Miriam Weaverdyck 7/28/16: converting to spock-compatable
# Motion correction using FSL
# Keep lines starting with #SBATCH together and at top of script! Modify settings as appropriate.

#SBATCH -J mcflirt-%j			# Job name
#SBATCH -p all					# Set partition to 'all' (don't change)
#SBATCH -t 1:00:00				# Set runtime in hh:mm:ss, d-hh, d-hh:mm, mm:ss, or m
#SBATCH --mem 5120				# Set amount of memory in MB (1GB = 1024 MB)

set -e

source globals.sh

# save subject's directory location
cur=`pwd`
# cd to subject's nifti folder and select field map
nifti_folder=$NIFTI_DIR
cd $nifti_folder
LOCATION=`pwd`
SE_AP="${LOCATION}/${SUBJ}_epi_SE_AP.nii.gz"
# run motion correction on all EPIs
for epi in `ls *_epi_t.nii.gz`; do
mcflirt -in $epi -refvol $SE_AP -plots -mats
done
# return to subject's directory
cd $cur

