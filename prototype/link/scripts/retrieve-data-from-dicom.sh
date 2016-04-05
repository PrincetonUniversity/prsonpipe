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

set -e # fail immediately on error

#####################################
#####################################

# Basic help for using the function, if no input is given:

if [ $# -ne 1 ]; then
  echo '
usage: `basename $0` $scanner

Retrieves raw DICOM data from the specified scanner''s directory and compresses it
into a gzipped tar file.

For skyra, type s for the $scanner. For prisma, type p (e.g. scripts/retrieve-data-from-dicom.sh s)

The default is to take the files from the current year, from the Turk-B lab.

If you did not run the subject in the current year, change the YEAR_DICOM variable within scripts/subject_id to be the year you want, i.e change YEAR_DICOM=''`date +%Y`'' to YEAR_DICOM=2012. You can similarly change the lab if the subjects scans are not in the Turk-B folder.

If you cannot find your scans, you can look manually: 

	All the SKYRA files are found in:
		 /jukebox/dicom/conquest/Skyra-AWP45031/Turk-B/$YEAR/
	All the PRISMA files are found in:
		/jukebox/dicom/conquest/Prisma-MSTZ400D/Turk-B/$YEAR/
	
  '
  exit
fi
#####################################
#####################################

#set which scanner to pull the dicom files from:

scanner=$1
if [ "$scanner" = s ]; then
	SCANNER_DIR='Skyra-AWP45031'

elif [ "$scanner" = p ]; then
	SCANNER_DIR='Prisma-MSTZ400D'

else
	echo
	echo 'ERROR: you must specify which scanner to retrieve files from. For skyra, write an s, and for prisma, write an p. For example: 
	
	>> retreieve-data-from-dicom s' 
	echo
	exit
fi

source globals.sh

tmp_dir_zip="$(mktemp -d)"
DICOM_DIR=/jukebox/dicom/conquest/$SCANNER_DIR/$LAB/$YEAR_DICOM

#####################################
#####################################

# Make sure that there is a directory there for that name, and make sure there is not more than one directory for that subject. 

SUBJFILES=$(ls -d /$DICOM_DIR/$SUBJ* 2> /dev/null | wc -l)

if [ "$SUBJFILES" -eq 0 ]; then
 	echo 
 	echo "ERROR: Cannot find the folder for the specified subject. Be sure the correct year, subjID, and lab folder are being used. Default is set to be the current year and the "Turk-B" folder. You can change these in the subject_id script in the subject folder." 
 	echo 
 	echo  'If you want to search manually for the scans that were transferred: 
 	
 	All the SKYRA files are found in:
 		 /jukebox/dicom/conquest/Skyra-AWP45031/$LAB/$YEAR/ 
 	All the ALLEGRA files are found in:  	
 		/jukebox/dicom/conquest/Allegra-MRC20413/$LAB/$YEAR/'
 	echo
	exit
elif [ "$SUBJFILES" -gt 1 ]; then
	echo
 	echo "More than one directory for this subject found. They may have been transferred more than once, or you may have accidentally used the same subject ID multiple times. Which of these directories would you like to use (distinguished by date)?"
 	pushd /$DICOM_DIR/ > /dev/null
 	echo
 	ls -d $SUBJ*
 	popd > /dev/null
 
 	echo
 	echo -n "Please type the directory name exactly (or press enter to quit):"
 	read CHOSEN_SUBJ
 	if [ -z "$CHOSEN_SUBJ" ]; then
   	 exit
     fi		
fi
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
