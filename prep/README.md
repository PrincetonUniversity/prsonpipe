6/21/18 JNM

prep directory
===========================================

Preprocessed data is stored here. Each task has a subdirectory, which contains
a directory for each preprocessing pipeline used. This preprocessing pipeline 
directory is named according to the tool used for each step. 
It has lowercase letters that correspond mostly to the prefixes SPM uses
for preprocessing steps, followed by uppercase letters that denote the software
that step ran in (<b>D</b>artel, <b>S</b>PM12W, <b>F</b>SL, or <b>N</b>one). 
The preprocessing steps are: a = slice timing, r = motion correction
(realignment), u = unwarp, w = normalization, s = smoothing, f = bandpass filter.

For example, if slicetiming is turned off and all the other steps are run in 
DARTEL, with the exception of bandpass filtering, which was done in FSL, the
directory would be named `aNrDuDwDsDfF`. This `TSK/aNrDuDwDsDfF/` directory will
then have subdirectories for each subject with their preprocessed data. Within
a subject's directory, the file named `epi_r<run number>.nii.gz` is always the 
fully preprocessed one. The other versions of this file, with prefixes corresponding
to preprocessing steps, are intermediate files that you can look at to debug if 
the `epi_r` files don't look right.