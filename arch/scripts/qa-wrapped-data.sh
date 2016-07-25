#!/bin/bash
# author: mgsimon@princeton.edu

if [ $# -ne 2 ]; then
  echo "
  usage: `basename $0` nifti_folder output_folder

  runs BXH XCEDE QA tools on the functional data in the specified nifti_folder,
  and places the output of the QA process into output_folder.

  see http://nbirn.net/tools/bxh_tools/index.shtm for details on the QA tools.

  BXH XCEDE tools must be in the path for this script to run.
  "
  exit
fi

source globals.sh

nifti_dir=$1
output_dir=$2


if [ -d "$output_dir" ]; then
  read -t 5 -p "data has already been qa-ed. overwrite? (y/N) " overwrite || true
  if [ "$overwrite" != "y" ]; then exit; fi
  rm -rf $output_dir
fi


TRUE=0
FALSE=1
is_functional() {
  file=$1
  num_volumes=$(fslnvols $file 2>/dev/null)
  if [[ "$num_volumes" -gt 65 ]]; then #changed to 65 so qa doesn't run on dti scans
    return $TRUE
  else
    return $FALSE
  fi
}


mkdir -p $output_dir
functional_files=""
for file in $nifti_dir/*.nii.gz; do
  if is_functional $file; then
    prefix=${file%.nii.gz}
    functional_files="$functional_files $prefix.bxh"
  fi
done

$BXH_DIR/fmriqa_generate.pl --overwrite $functional_files $output_dir 1>/dev/null 2>/dev/null

