7/25/16 MEW

scripts/SPM8 directory
===========================================

Customized scripts for SPM8

DARTEL:
DARTEL_spm8.m is the matlab script that uses SPM8 to normalize the data.  CHANGE SETTINGS IN THIS FILE FOR YOUR PROJECT
sp_* are spock-compatible scripts
sp_DARTEL_run.sh is the spock wrapper to run DARTEL_spm8.m.  It uses unzip_runs_anat.m to expand the nifti files.
DARTEL_backup.sh copies the output files from DARTEL_spm8.sh to your project folder in /jukebox/tamir
unzip_runs_anat.sh goes into every subject's folder and unzips the preprocessed runs and anatomical
