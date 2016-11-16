#!/bin/bash
# author: Judith Mildner
# edited by Miriam Weaverdyck 7/28/16: converting to spock-compatable
# This script takes epi spin echos and puts them into topup using FSL. Then applies topup to your epi data. Adapted from Mark Pinsk's Unoffical PNI fMRI wiki
# Keep lines starting with #SBATCH together and at top of script! Modify settings as appropriate.

#SBATCH -J topup-%j				# Job name
#SBATCH -p all					# Set partition to 'all' (don't change)
#SBATCH -t 1:00:00				# Set runtime in hh:mm:ss, d-hh, d-hh:mm, mm:ss, or m
#SBATCH --mem 5120				# Set amount of memory in MB (1GB = 1024 MB)


set -e #fail on error

source globals.sh #load environment variables

cd $NIFTI_DIR

fslmerge -t all_SE_epi ${SUBJ}_epi_SE_AP ${SUBJ}_epi_SE_PA

declare -a APinfo=(`fslinfo ${SUBJ}_epi_SE_AP`) #make array out of header info for AP epi to use in readout time calculation
declare -a PAinfo=(`fslinfo ${SUBJ}_epi_SE_PA`)
EPI_ACCEL=1
EPI_ECHOSPACING=0.00072 #make sure to get correct value from your scanning protocol

echo 'Generating acqparams file'
if [ ! -e 'acqparams_epi.txt' ] #lines to make sure it only generates new file if it does not already exist
then
	readout=(${APinfo[3]}/$EPI_ACCEL-1)*$EPI_ECHOSPACING
	readout=`echo "$readout" | bc -l`
	for i in $(eval echo "{1..${APinfo[9]}}") ; do
		cat >> acqparams_epi.txt <<EOF
0 -1 0 $readout
EOF
	done
for i in $(eval echo "{1..${APinfo[9]}}"); do
	cat >> acqparams_epi.txt <<EOF
0 1 0 $readout
EOF
	done
fi
echo 'Running topup'

topup --imain=all_SE_epi --datain=acqparams_epi.txt --config=b02b0.cnf --out=topup_output --iout=topup_iout --fout=topup_fout --logout=topup_logout

echo 'Applying topup to all timing and motion corrected epi runs'

for epi in `ls ${SUBJ}*epi_t_mcf.nii.gz`; do
	applytopup --imain=$epi --datain=acqparams_epi.txt --inindex=1 --topup=topup_output --method=jac --out="${epi%.nii.gz}_topup"
done

cd ../../


