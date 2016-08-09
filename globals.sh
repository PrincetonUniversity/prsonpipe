#!/bin/bash -e
# author: mgsimon@princeton.edu
# this script sets up global variables for the whole project

set -e # stop immediately when an error occurs


# add necessary directories to the system path
PATH=$PATH:/exanet/ntb/packages/php-5.3.2/sapi/cli  # this is for rondo until php is installed


PROJECT_DIR=$(pwd)
SUBJECTS_DIR=subjects
GROUP_DIR=group

#below variables are needed for roi.sh
ROI_RESULTS_DIR=results
SUBJ_ROI_DIR=results/roi #path to each subject's roi directory -- the script assumes that
# each subject's roi data is in the same place within his/her directory

function exclude {
  for subj in $1; do
    if [ -e $SUBJECTS_DIR/$subj/EXCLUDED ]; then continue; fi
    echo $subj
  done
}

if [ -d $SUBJECTS_DIR ]; then
ALL_SUBJECTS=$(ls -1d $SUBJECTS_DIR/*/ | cut -d / -f 2)
NON_EXCLUDED_SUBJECTS=$(exclude "$ALL_SUBJECTS")
fi
