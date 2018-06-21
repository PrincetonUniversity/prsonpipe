6/21/18 JNM

scripts directory
===========================================

This directory contains all scripts for the pipeline. The scripts are organized
by their function.

```
|-scripts
    |-BXH_QA (Quality assurance scripts. Under construction.)
    |-group_level (Second level (group level) analysis scripts)
    |-import_data (Scripts to import raw data and convert it from dcm to nii)
    |-preprocess (Scripts to preprocess raw data)
    |-sub_level (First level (subject level) analysis scripts)
    |-utils (various handy tools and functions used in other scripts)
    |-globals.par (contains the study's most important global variables)
    |-globals.m (translates globals.par for use with Matlab)
    |-init_project (sets up your project directory when you start using the pipeline)
```
