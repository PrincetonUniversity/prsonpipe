#!/usr/bin/env bash
# backup_prep.sh creates the destination folder and copies all DARTEL files from subject folders in 03_DARTEL to /jukebox/tamir/mentalstates/prep/s<subnum>/
# and then zips all of these files to conserve space

source ../globals.sh
study=$PROJECT_DIR

cd "$PROJECT_DIR/$SUBJECTS_DIR"
for sub in `ls -d 1*`; do mkdir "/jukebox/tamir/${study}/prep/s${sub:16}/"; cd "$sub"; cd data; cd nifti; cp mean* "/jukebox/tamir/${study}/prep/s${sub:16}"/; cp r* "/jukebox/tamir/${study}/prep/s${sub:16}"/; cp u* "/jukebox/tamir/${study}/prep/s${sub:16}"/; cp w* "/jukebox/tamir/${study}/prep/s${sub:16}"/; cp y* "/jukebox/tamir/${study}/prep/s${sub:16}"/; cd ../../../; done
cd "/jukebox/tamir/${study}/prep/"
for sub in `ls -d s*`; do cd "$sub"; gzip *.nii; cd ../; done
