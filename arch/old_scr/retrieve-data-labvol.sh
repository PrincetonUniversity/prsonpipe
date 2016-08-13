#!/bin/bash
# author: vej@princeton.edu
# adapted from "retrieve_data_from_sun" by mgsimon@princeton.edu and atompary@gmail.com
# downloads raw DICOM data for the specified subject from dicom and compresses it
# into a gzipped tar file at the file path specified by output_path
# Oct 18 2012
#
# Feb 18, 2015, Nate Wilson, nmwilson@princeton.edu - updated script to include prisma and remove allegra compatibility
# this included changing the basic help prompt, the scanner directory path setting code, and allowing errors during the 
# segment of this script that removes .dcm because of an error that can be ignored.
#
# March 15, 2016 Judith Mildner - Changed DICOM_DIR variable to Tamir lab volume name to get data from lab volume instead of conquest

set -e # fail immediately on error

#####################################
#####################################

source globals.sh

tmp_dir_zip="$(mktemp -d)"
DICOM_DIR=/jukebox/tamir/jmildner/soc_dep_scans/participants

#####################################
#####################################

# Make sure that there is a directory there for that name, and make sure there is not more than one directory for that subject. 

SUBJFILES=$(ls -d /$DICOM_DIR/$SUBJ* 2> /dev/null | wc -l)


#####################################
#####################################
# Copy over the dicom files 

if [ "$SUBJFILES" -gt 1 ]; then
	cp -r $DICOM_DIR/$CHOSEN_SUBJ/dcm/* $tmp_dir_zip/
elif [ "$SUBJFILES" -eq 1 ]; then
	cp -r $DICOM_DIR/$SUBJ*/dcm/* $tmp_dir_zip/
fi

tmp_dir="$(mktemp -d)"
mkdir $tmp_dir/$SUBJ/


pushd $tmp_dir_zip/ > /dev/null

#####################################
#####################################

#Unzip the files

for f in *.gz; do
	STEM=$(basename "${f}" .gz) 
	gunzip -c "${f}" > $tmp_dir/$SUBJ/"${STEM}"
done

popd > /dev/null

rm -rf $tmp_dir_zip

#####################################
#####################################
#remove the .dcm ending, reformat: 

pushd $tmp_dir/$SUBJ > /dev/null

set +e # allowing errors temporarily, because prisma has phoenix report files, 99*unknown.dcm.gz which will throw errors

for f in * ;
do
	FILENAME=$(basename "$f")
	FILENAME="${FILENAME%.*}"
	mv $f $FILENAME;
done

for file in * ;
do
	temp_file_decomp=(`echo $file | tr "-" "\n"`)
	temp_series=`printf "%03d" ${temp_file_decomp[0]}`
	temp_imagenum=`printf "%04d" ${temp_file_decomp[1]}`
	temp_TE=`printf "%03d" ${temp_file_decomp[2]}`
	temp_name=$temp_series'_'$temp_imagenum'_'$temp_TE
	mv $file $temp_name;
done

set -e # returning to setting that fails upon error 

 for file in * ; 
 do 

    mv $file $SUBJ$file; 
 done


#mkdir $SUBJ
#data_dir_temp=$tmp_dir/$SUBJ
#echo $data_dir_temp

popd > /dev/null

output_file=raw.tar.gz
output_dir=$DATA_DIR
pushd $tmp_dir/$SUBJ > /dev/null
tar --create --gzip --file=$output_file *
popd > /dev/null
mv $tmp_dir/$SUBJ/$output_file $output_dir

rm -rf $tmp_dir