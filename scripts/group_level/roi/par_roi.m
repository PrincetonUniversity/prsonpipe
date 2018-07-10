% spm12w r6906
% Parameters file for roi analysis
% Last updated: March, 2017
% =======1=========2=========3=========4=========5=========6=========7=========8
% Get environmental variables based on globals.par
[~, fstr] = system('echo "$USER"');
netid = strrep(fstr,sprintf('\n'),'');

clear globals_file;
[~, fstr] = system('script_dir="$(dirname -- "$(pwd)")"; echo "${script_dir%scripts*}scripts/globals.m"');
globals_file 		= strrep(fstr,sprintf('\n'),'');

run(globals_file)

% Paths and names
roi.glm_name = 'glm_ANT';      % glm to use for extracting parameters
roi.roi_name = 'roi_ANT';      % name of directory for roi analysis output
roi.study_dir = PROJECT_DIR; % no need to change

% CSV files specifying roi specs and subject variables (optional)
% These files should be in auxil/roicsv
roi.spec_file = 'roi_neurosynth_spec.csv'; % name of a csv file specifying rois
roi.var_file = 'roi_vars.csv';  % name of a csv file with subject variables

% 1st level GLM contrasts to use for roi analysis
roi.conds = {'cueVSbaseline', 'centerVSbaseline', 'cueVScenter'};

% ROI statistics - statistics: descriptives, ttest1 ttest2, correl1, correl2
%                - leave blank or omit if statistic not desired
%                - use cell arrays for stats on multiple contrasts
%                - use strings to define a contrast formula
%                - 'all_conditions' is a reserved word
roi.stats.descriptives = 'all_conditions';
roi.stats.ttest1 = 'all_conditions';
roi.stats.ttest2 = 'all_conditions';
%roi.stats.correl1 = 'humVSall';
%roi.stats.correl2 = 'allVSbaseline';

% ROI specifications - (X,Y,Z, sphere diameter in mm) or mask filename
%                    - for masks use nifti image name instead of coordinate
%                    - if no sphere diameter specified, default will be used
%                    - can be used in conjunction with an roi spec file.
%roi.roi.l_dmpfc_ba10 = [-3,63,15,6];
%roi.roi.l_precuneus_ba32 = [-3,-60,24];
%roi.roi.l_amygdala = 'aal_l_amyg_3x3x3.nii';

% User name
roi.username = netid; % no need to change