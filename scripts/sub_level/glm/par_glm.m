% spm12w r6225
% Parameters file for 1st level glm analysis and 2nd level rfx analysis
% Last updated: January 2017
% =======1=========2=========3=========4=========5=========6=========7=========8
% p_glm_default.m
% glm parameters for transition analyses

% Get environmental variables based on globals.par
global realigns

[~, fstr] = system('echo "$USER"');
netid = strrep(fstr,sprintf('\n'),'');

clear globals_file;
[~, fstr] = system('script_dir="$(dirname -- "$(pwd)")"; echo "${script_dir%scripts*}scripts/globals.m"');
globals_file 		= strrep(fstr,sprintf('\n'),'');

run(globals_file)

% User input paths
glm.username        = netid;
tsk                 = 'TSK';			% enter the task you want to run
wd                  = 'aNrNuNwNsNfF';	% enter the preprocessing directory
glm.glm_name        = 'myGLM';			% enter a unique name to call this GLM
glm.ons_dir         = 'TSK_onsets'; 	% enter the directory in which the onsets are stored

% Paths (no need to change)
glm.study_dir       = PROJECT_DIR;		% do not change
glm.prep_name       = [tsk filesep wd]; % do not change

% GLM Model Inclusions - 1=yes 0=no
glm.include_run 	= 'all'; % Specify run to model: 'all' or runs (e.g. [1,3])
glm.runsplit    	= 0; 	% Seperate GLM per run?
glm.design_only 	= 0; 	% Design only (i.e., no data)
glm.outliers    	= 0; 	% Include outlier as nuissance in GLM  
glm.duration    	= 0; 	% Event/Block Duration (same units as glm.time). 
                       		% Dur files will override.

% GLM Conditions (seperate by commas)
glm.events          = {'private', 'share'};
glm.blocks     		= {};
glm.regressors 		= {};

%% GLM Parametric modualtors - Special keyword: 'allthethings'
glm.parametrics 	= {};

% GLM Onsets File Specifications
glm.time			= 'secs';
glm.durtime			= 'secs';
tr 					= 2.25; % length of TR
ntr 				= 107; % number of TRs in one run
glm.nses 			= 2; % number of runs
glm.tr 				= ones(1,glm.nses)*tr; % same length of TR for each run
glm.nvols 			= ones(1,glm.nses)*ntr; % same number of TRs for each run
glm.hrf 			= 'hrf';
glm.hpf				= Inf;

% GLM realignment Specifications
glm.ra 				= realigns;
glm.move 			= 1;
par_form 			= '*.par'; % form of realignment files ('*.par' for FSL, 'rp*' for SPM12w)

glm.cleanupzip		= 1;

% GLM Contrasts - Numeric contrasts should sum to zero unless vs. baseline
%               - String contrasts must match Condition names.
%               - String contrast direction determine by the placement of 'vs.'
%               - Special keywords: 'housewine' | 'fir_bins' | 'fir_hrf'
% Note that the housewine's allVSbaseline will skip pmods but is not savy
% to complex designs (i.e., where you want all conditions VS baseline but
% not your user supplied regressors under glm.regressors, so in those cases
% you should create your own allVSbaseline and refuse the housewine). 
glm.con.housewine 	= 'housewine';

% RFX Specification
glm.rfx_name 		= 'rfx_mvpa';
glm.rfx_conds 		= {'allVSbaseline'};

% add packages
addpath(fullfile(MATLAB_PKG_DIR, 'PSNL_funcs'))
addpath(fullfile(MATLAB_PKG_DIR, 'spm12'))
addpath(fullfile(MATLAB_PKG_DIR, 'catstruct'))
addpath(fullfile(MATLAB_PKG_DIR, 'spm12w_1702'))
addpath(fullfile(MATLAB_PKG_DIR, 'NIfTI'))
