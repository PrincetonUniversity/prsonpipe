% Parameters file for SPM8 DARTEL normalization
% Last updated: August 2016
% =======1=========2=========3=========4=========5=========6=========7=========8

% SPM packages to load
p.spm8_dir      = '/jukebox/tamir/pkg/SPM8';
p.NIfTI_dir     = '/jukebox/tamir/pkg/NIfTI';
p.scripts_dir   = 'scripts/SPM8';

% study directory
p.proj_dir      = '/jukebox/tamir/prsonpipe';
p.output        = '/jukebox/tamir/prsonpipe/output';

% execute the job immediately? (0 = no, 1 = yes)
p.execTAG       = 1;

% customizable preprocessing parameters
p.vox_size      = 2.0;
p.smooth        = 0;
p.normalize	= 1;
p.realign	= 0;

% subjects directory containing subject folders
p.subdir        = 'prep/wd';
% pattern for finding subject folders (use wildcards)
p.subID         = 's*';
% do which subjects? ('all' to do all, position vector, e.g. 1:4, to do a subset)
%p.subTAG        = 'all';
% pattern for finding functional run files (use wildcards)
p.runID         = 'epi_r*';
% pattern for finding matched-bandwidth image (use wildcards)
p.mprageID      = 'anat.nii';

% format of your raw functional images (1=img/hdr, 2=4D nii)
p.funcFormat    = 2;

% path for tissue probability maps (in spm8/tpm) for 'new segment'
p.TPMimg        = '/jukebox/tamir/pkg/SPM8/toolbox/Seg/TPM.nii';

