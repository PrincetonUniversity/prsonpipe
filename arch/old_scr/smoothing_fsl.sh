#!bin/bash
# author: Judith Mildner
# 16/02/12
# script smooths epi data using fslmaths with FWHM specified

set -e

FWHM=6 #set desired FWHM
sigma=`echo "2.35482004503*$FWHM" | bc -l` #calculate sigma value needed for FSL smoothing based on FWHM

echo "Smoothing epi runs using fslmaths with FWHM $FWHM"
for epi in `ls ${LOCATION}/${NIFTI_DIR}/w_*`; do
	fslmaths $epi -s $sigma s${epi%.nii.gz}
done