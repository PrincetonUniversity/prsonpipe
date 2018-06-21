Welcome to Data Analysis Modules for Neuroimaging (DAMN):  
[Princeton Social Neuroscience Lab](psnlab.princeton.edu)'s fMRI analysis pipeline.
=========================================== 

See the [wiki](https://github.com/PrincetonUniversity/prsonlab/wiki) for usage instructions.

# Overview

This pipeline is meant to help run your analyses smoothly on the clusters, even 
if you need to use various different software packages. The DAMN pipeline currently
includes scripts for preprocessing, first level glm, and second level glm.

## Available options and packages
There are tools from [FSL](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki), 
[SPM12w](https://github.com/wagner-lab/spm12w), 
and [SPM12](http://www.fil.ion.ucl.ac.uk/spm/software/spm12/)'s DARTEL toolbox available.

For preprocessing, the pipeline currently offers the following options:

- Slice timing
  * SPM12W
- Motion correction
  * SPM12W
  * DARTEL*
- Unwarping
  * SPM12W (unwarping without a field map)
  * TOPUP + DARTEL* (opposing direction spin echos as field map)
  * DARTEL* (no field map) 
- Normalization
  * SPM12W (regular spm12 normalization)
  * DARTEL (generates study specific template, normalizes to that, 
  then to MNI space. Can run with standard template as well if you don't have 
  enough subjects yet for a common template or just want to save time)
- Smoothing 
  * SPM12W 
  * DARTEL (requires normalization in Dartel as well)
- High pass filtering
  * FSL

*Note: DARTEL here really means SPM12 and its fieldmap toolbox. These are included 
in the same script as the DARTEL normalization + smoothing. To avoid confusion with
SPM12W, the name DARTEL is used throughout to refer to these SPM12 functions.

There are first level (subject level) glm scripts available based on SPM12W, 
ROI analysis scripts based on FSL, and second level (group level) glm scripts based
on SPM12W and FSL's randomise.


## Structure
The basic file structure is based on [SPM12w](https://github.com/wagner-lab/spm12w), 
and looks like this:
```
|-- analysis (for analyzed data)
|-- auxil (for study parameters, onset times, roi masks, etc.)
    |-- archive (for subject list, raw data, run orders) 
|-- output (for slurm job logs)
|-- prep (for preprocessed data)
|-- qa (for quality assurance output)
|-- raw (for raw data, in gzipped nifti format)
|-- scripts (contains all scripts)
```

06/21/2018 JNM