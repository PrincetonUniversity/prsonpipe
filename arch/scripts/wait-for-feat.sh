#!/bin/bash
# author: mgsimon@princeton.edu


if [ $# -ne 1 ]; then
  echo "
usage: `basename $0` feat_output_dir

this script sleeps until FSL's FEAT has finished producing output in
feat_output_dir.

REQUIREMENTS:
 - feat_output_dir must be a directory into which FSL's FEAT is placing output,
   otherwise this script will never end
"
  exit
fi


feat_output_dir=$1

SLEEP_INTERVAL=10   # this is in seconds

while [ -z "$(grep 'Finished at' ${feat_output_dir}/report.html)" ]; do
  # feat is still running...
  sleep $SLEEP_INTERVAL
done

