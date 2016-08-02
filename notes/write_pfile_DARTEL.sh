#!/bin/bash -e
# author: Miriam Weaverdyck 8/1/16
# ------------------------------------------------------------------------------
# this script writes out the parameters to the p_study.m file 
# (a matlab file to be read by SPM12w)

source pars.sh
source study_info.sh
source ../arch/globals.sh

SAVE_DIR=$PROJECT_DIR/$SCRIPT_DIR_SPM8

spm8_dir=$PKG_DIR/SPM8
NIfTI_dir=$PKG_DIR/NIfTI

if [ $SMOOTH_SOFT == 'DARTEL' ]; then
	SMOOTHING=$SMOOTH
else
	SMOOTHING=0
fi

# Check if $last_prep is empty. If so, assign it SPM by default
if [ -z "$last_prep" ]; then 
echo "WARNING: Variable 'last_prep' is unset.  Setting it to SPM as default."; SUB_DIR=prep/SPM*;
else SUB_DIR=prep/$last_prep*;
fi

cat <<EOT > $SAVE_DIR/p_DARTEL.m
% Parameters file for SPM8 DARTEL normalization
% Last updated: August 2016
% =======1=========2=========3=========4=========5=========6=========7=========8

% SPM packages to load
p.spm8_dir      = '$spm8_dir';
p.NIfTI_dir     = '$NIfTI_dir';
p.scripts_dir   = '$SCRIPT_DIR_SPM8';

% study directory
p.proj_dir      = '$PROJECT_DIR';
p.output        = '$OUT_DIR';

% execute the job immediately? (0 = no, 1 = yes)
p.execTAG       = 1;

% customizable preprocessing parameters
p.vox_size      = $VOX_SIZE;
p.smooth        = $SMOOTHING;

% subjects directory containing subject folders
p.subdir        = '$SUB_DIR';
% pattern for finding subject folders (use wildcards)
p.subID         = 's*';
% do which subjects? ('all' to do all, position vector, e.g. 1:4, to do a subset)
%p.subTAG        = 'all';
% pattern for finding functional run files (use wildcards)
p.runID         = 'epi*_r*';
% pattern for finding matched-bandwidth image (use wildcards)
p.mprageID      = '*anat.nii';

% format of your raw functional images (1=img/hdr, 2=4D nii)
p.funcFormat    = 2;

% path for tissue probability maps (in spm8/tpm) for 'new segment'
p.TPMimg        = '$spm8_dir/toolbox/Seg/TPM.nii';

EOT
echo "Parameters file $SAVE_DIR/p_DARTEL.m written and saved."
