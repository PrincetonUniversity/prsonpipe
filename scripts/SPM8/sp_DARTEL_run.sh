#!/usr/bin/env bash
# type: sbatch -J name script.sh
# Keep lines starting with #SBATCH together and at top of script! Modify settings as appropriate.

#SBATCH -J dartel				# Job name
#SBATCH -o ../../output/dartel-%j.out		# Output file name
#SBATCH -p all					# Set partition to 'all' (don't change)
#SBATCH --workdir=./				# Set working directory
#SBATCH -t 24:00:00				# Set runtime in hh:mm:ss, d-hh, d-hh:mm, mm:ss, or m
#SBATCH --mem 5120				# Set amount of memory in MB (1GB = 1024 MB)
#SBATCH --mail-user=prsonlab@gmail.com		# Set user email for notifications
#SBATCH --mail-type=ALL				# Set notification type

#unzip the files we will be using
bash ./unzip_runs_anat.sh

#run matlab from the command line as part of a submit job
module load matlab/R2015b
# run script
matlab -nosplash -nodisplay -nodesktop -r "try; DARTEL_spm8; catch me; fprintf('%s / %s\n',me.identifier,me.message); end; exit"
