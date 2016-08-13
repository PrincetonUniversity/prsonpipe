#!bin/bash
#author: Judith Mildner
# This script takes the preprocessed data (suffix is input argument 1, default topup) and moves it into data/prep
# Removes all suffixes from data in the prep folder for easier viewing, and creates prep/contents.txt to keep track of what you put in there
# If moving data with a certain prefix call script prefix <prefix>, for example: bash scripts/cleanup.sh prefix w
# An example for suffixed data is: bash scripts/cleanup.sh _s

set -e

#save current location and move into nifti dir
LOCATION=`pwd`
cd data/nifti

#check for input argument
if [ -z "$1" ]; then
    suffix="topup.nii.gz"
elif [ "$1" == "prefix" ]; then
	suffix="$2"
else
	suffix="${1}.nii.gz"
fi

#create prep directory if it does not exist yet
if [ ! -d "../prep" ]; then
	mkdir ../prep
fi

#make contents file so you know what was moved to prep directory and when
echo $(date) | cat > ../prep/contents.txt
ls *${suffix} | cat >> ../prep/contents.txt


# move files over and strip everything from _epi onward from the name
for file in `ls *${suffix}`; do
	mv $file ../prep/${file%_epi*}
done

cd $LOCATION
