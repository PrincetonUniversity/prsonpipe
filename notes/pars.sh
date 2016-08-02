#!/bin/bash -e/
# author: Miriam Weaverdyck 8/1/16
# Enter the parameters for your project's p_ files below


# QA: 'BXH', 'SPM'
QA='BXH'

# Slice time correction: 'FSL', 'SPM', 'none'
SLICE_TIME='SPM'

# Realignment/Motion Correction: 'FSL', 'SPM', 'none'
REALIGN='SPM'

# Unwarping: 'FSL', 'SPM', 'none'
UNWARP='SPM'

# Smoothing: 'FSL', 'SPM', 'DARTEL', none'; size of smoothing kernel in FWHM
SMOOTH_SOFT='SPM'
SMOOTH=8

# Signal to Noise Ratio output: 'FSL', 'SPM'
SNR='SPM'

# Slices from SPMw
SLICES='SPM'

# === Not used in SPM ===

# Topup (FSL): yes=1, no=0
TOPUP=1

# Normalization (includes registration to MNI space): 'FSL', 'DARTEL', 'none'
NORM='DARTEL'

# voxel size at which to re-sample functionals (isotropic)
VOX_SIZE=2.0

# TR (sec)
TR=2.25

# Number of TRs per Run
nTR=209

# Number of Runs
RUNS=12