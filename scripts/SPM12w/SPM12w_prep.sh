#!/usr/bin/env bash
# type: sbatch -J name script.sh sub
# sub should be in s000 form.  Only 1 sub at a time allowed
# Keep lines starting with #SBATCH together and at top of script! Modify settings as appropriate.

#SBATCH -J SPMw_prep				# Job name
#SBATCH --workdir=./				# Set working directory
#SBATCH -t 01:00:00					# Set runtime in hh:mm:ss, d-hh, d-hh:mm, mm:ss, or m
#SBATCH --mem 5120					# Set amount of memory in MB (1GB = 1024 MB)

source ../globals.par

