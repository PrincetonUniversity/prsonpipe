#!/bin/bash
# author: mgsimon@princeton.edu

set -e  # fail immediately on error

if [ $# -ne 4 ]; then
  echo "
usage: `basename $0` dicom_archive output_folder output_prefix run_order_file

converts the raw data in dicom_archive (tgz-ed) to gzipped NIfTi format, in LAS
order, with BXH headers, and names each run according to the names in
run_order_file.

run_order_file must be a text file with one line per run that should be
converted. on each line it should contain the name of that run, optionally
followed by a space and then the number of TRs that are expected to be in that
run. if an expected number of TRs is given, an error will be shown for each run
that doesn't contain the expected number of TRs. if a run was recorded, but you
want to ignore it, place the text 'ERROR_RUN' on the line corresponding to that
run.

BXH XCEDE tools must be in the path for this script to run.

see http://nifti.nimh.nih.gov/nifti-1 for details on NIfTi format.
see http://nbirn.net/tools/bxh_tools/index.shtm for details on BXH headers.
  "
  exit
fi


dicom_archive=$1
output_dir=$2
output_prefix=$3
run_order_file=$4

source globals.sh

ORIENTATION=LAS
PREFIX=scan
ERROR_FLAG=ERROR_RUN
UNEXPECTED_NUMBER_OF_SCANS=1
UNEXPECTED_NUMBER_OF_TRS=2


if [ -d "$output_dir" ]; then
  read -t 5 -p "data has already been converted. overwrite? (y/N) " overwrite || true
  if [ "$overwrite" != "y" ]; then exit; fi
  rm -rf $output_dir
fi

mkdir -p $output_dir

temp_dicom_dir=$(mktemp -d -t tmp.XXXXXX)
temp_output_dir=$(mktemp -d -t tmp.XXXXXX)
tar --extract --gunzip --file=$dicom_archive --directory=$temp_dicom_dir
$BXH_DIR/dicom2bxh $temp_dicom_dir/* $temp_output_dir/$PREFIX.bxh 1>/dev/null 2>/dev/null

# strip blank lines and comments from run order file
stripped_run_order_file=$(mktemp -t tmp.XXXXX)
sed '/^$/d;/^#/d;s/#.*//' $run_order_file > $stripped_run_order_file

# check that the actual number of scans retrieved matches what's expected, and
# exit with an error if not.
num_actual_scans=$(find $temp_output_dir/*.bxh -maxdepth 1 -type f | wc -l)
num_expected_scans=$(wc -l < $stripped_run_order_file)
if [ $num_actual_scans != $num_expected_scans ]; then
  echo "found $num_actual_scans scans, but $num_expected_scans were described in $run_order_file. check that you're listing enough scans for your circle localizer, etc... because those may convert as more than one scan." >/dev/stderr
  exit $UNEXPECTED_NUMBER_OF_SCANS
fi


# convert all scans to gzipped nifti format, and if the run order file indicates
# how many TRs are expected in a particular scan, check that there are actually
# that many TRs, and exit with an error if not.
number=0
# the sed magic here strips out comments
cat $stripped_run_order_file | while read name num_expected_trs; do
  let "number += 1"
  if [ $name == $ERROR_FLAG ]; then
    continue
  fi

  # convert the scan
  niigz_file_prefix=$temp_output_dir/${output_prefix}_$name
  $BXH_DIR/bxh2analyze --analyzetypes --niigz --niftihdr -s "${temp_output_dir}/${PREFIX}-$number.bxh" $niigz_file_prefix 1>/dev/null 2>/dev/null

  if [ -n "$num_expected_trs" ]; then
    num_actual_trs=$(fslnvols ${niigz_file_prefix}.nii.gz)
    if [ $num_expected_trs -ne $num_actual_trs ]; then
      echo "$name has $num_actual_trs TRs--expected $num_expected_trs" >/dev/stderr
      exit $UNEXPECTED_NUMBER_OF_TRS
    fi
  fi
done

rm -f $temp_output_dir/$PREFIX-*.bxh
rm -f $temp_output_dir/$PREFIX-*.dat
rm -f $stripped_run_order_file
mv $temp_output_dir/* $output_dir

