#!/bin/bash
#
# analyze.sh runs the analysis of a subject
# original author: mason simon (mgsimon@princeton.edu)
# this script was provided by NeuroPipe. modify it to suit your needs

set -e # stop immediately when an error occurs


pushd $(dirname $0) > /dev/null   # move into the subject's directory, quietly

source globals.sh   # load subject-wide settings, such as the subject's ID

# here, we call scripts to make a webpage describing this subject's analysis,
# prepare the subject's data, and then run analyses on it. put in a call to each
# of your high-level analysis scripts (behavioral.sh, fir.sh, ...) where
# indicated, below
echo "== beginning analysis of $SUBJ at $(date) =="
bash prep.sh
# run your high-level analysis scripts here
bash scripts/time_fsl.sh
bash scripts/mcflirt.sh
echo "== finished analysis of $SUBJ at $(date) =="

popd > /dev/null   # return to the directory this script was run from, quietly
