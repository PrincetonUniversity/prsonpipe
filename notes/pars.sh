#!/bin/bash -e/
# author: Miriam Weaverdyck 8/1/16
# Enter the parameters for your project's p_ files below


# QA: 'BXH', 'SPM'
QA='BXH'

# Slice time correction: 'FSL', 'SPM', 'none'
SLICE_TIME='SPM'

# Realignment: 'FSL', 'SPM', 'none'
REALIGN='SPM'

# Unwarping: 'FSL', 'SPM', 'none'
UNWARP='SPM'

# Smoothing: 'FSL', 'SPM', 'none'; size of smoothing kernel in FWHM
SMOOTH_SOFT='SPM'
SMOOTH=8

# Signal to Noise Ratio output: 'FSL', 'SPM'
SNR='SPM'

# Normalization: 'FSL', 'DARTEL', 'none'
NORM='DARTEL'
