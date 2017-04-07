Welcome to Data Analysis Modules for Neuroimaging, by the Princeton Social Neuroscience Lab
===========================================

README.txt's are still under construction.

See the wiki for usage instructions: https://github.com/PrincetonUniversity/prsonlab/wiki

# Overview

Below is a tree of all the files in the DAMN pipeline package per directory, with short descriptions. Scripts link to their own wiki pages.

{} indicates the file is created by the init_project script.

## analysis
This directory is empty at first, but will contain all results from first and second level analyses once run.

## auxil
This directory contains auxiliary files, like onset times, rois, run orders, and an archive of the original dicom files for all your subjects.
* onsets (directory with onset time files)
    - The onset files must be created by the user. See [[page_under_construction]]
* archive (directory with an archive of the original dicom files for all of your subjects)
* {runorders}
    - Contains your run order template, and the custom run order files for each subject.
* subid_list.txt
    - Contains the key to your subject IDs (from yymmdd_projectname_subject to s000 format (e.g. 161206_socdep_045 s045).

## notes << should we change this name to parameters or something? >>
This directory is the one containing all the files you have to edit when you start a project.
* study_info.par (start here)
    - This file contains everything about your project. Edit it to include the right tasks, settings, run orders, etcetera.
    - After you create this file, you run init_project to set everything up
    - See [[Getting Started|Getting-Started]]
* pars.par
    - this file is where you set all of your default preprocessing and analysis parameters. Once initialized, you will have a general pars.par, plus one per task (pars_TSK.par), if you have different preprocessing streams
* step.par
    - this file is used by preprocess to change parameters per preprocessing step. You should not change anything in here.

## output
Once you start running scripts, all output from sbatch jobs will be stored in this directory. The format of the output files is <script_name>-<jobID#>.out (e.g. convert-328450.out).

## prep
This directory contains the preprocessing output for each subject, once preprocessing starts to run.
* (TSK) (One subdirectory per task specified in study_info will be created by init_project)
        * (preprocessing stream directory) (subdirectory of TSK)
            - This will be created by preprocess. The directory name has the format of each preprocessing step's SPM prefix (a=slice timing, r = motion correction, u = unwarping (field map), w = coregistration, s = smoothing), followed by the package it was done in (N = none, F = FSL, S = SPM12w, D = DARTEL), for example 'aNrFuFwDsD'.

## qa
This directory will contain all Quality Assurance output for your data
* (TSK) (Like in prep, one directory per task will be created)

## raw
This directory will contain all raw data, in nifti format, after it has been converted to meet file and naming standards during preprocessing.
* (TSK) (Again, one directory per task)

## scripts
This is where the magic happens. Each package has its own directory
* [[BXH_QA]] (Quality assurance scripts)
* [[DARTEL]] (directory)
* [[FSL]] (directory)
* [[SPM12w]] (SPM12w)
* [[utils]] (directory contains conversion scripts, functions, logging scripts, etc)
* [[init_project]]
* [[preprocess]]
* [[retrieve_dcm]]
