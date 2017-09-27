clear globals_file
clear globals
%get path to where this file lives
globals_m = mfilename('fullpath');
% path to here up to 'scripts' (where globals is). [globals_m, '.par']
% could work too, as long as this filename is globals.m
globals_dir = regexp(globals_m, '.*/scripts', 'match');
globals_file = char(fullfile(globals_dir, 'globals.par'));
setenv('globals', globals_file)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PROJECT SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[~, fstr]           = system('source $globals; echo $PROJECT_DIR');
PROJECT_DIR         = strrep(fstr,sprintf('\n'),'');
[~, fstr]           = system('source $globals; echo $BACKUP_DIR');
BACKUP_DIR          = strrep(fstr,sprintf('\n'),'');
[~, fstr]           = system('source $globals; echo $USER_EMAIL');
USER_EMAIL          = strrep(fstr,sprintf('\n'),'');
[~, fstr]           = system('source $globals; echo $SCANNER');
SCANNER             = strrep(fstr,sprintf('\n'),'');
[~, fstr]           = system('source $globals; echo $PREP_SEP');
PREP_SEP            = str2num(fstr(1));
[~, fstr]           = system('source $globals; echo $LAB_NAME');
LAB_NAME            = strrep(fstr,sprintf('\n'),'');
[~, fstr]           = system('source $globals; echo $PKG_DIR');
PKG_DIR             = strrep(fstr,sprintf('\n'),'');
[~, fstr]           = system('source $globals; echo $MATLAB_PKG_DIR');
MATLAB_PKG_DIR      = strrep(fstr,sprintf('\n'),'');

[~, fstr]           = system('source $globals; echo $NUM_TASKS');
NUM_TASKS           = str2num(fstr(1));

% prep software names
[~, fstr]           = system('source $globals; echo $FSL');
FSL                 = strrep(fstr,sprintf('\n'),'');
[~, fstr]           = system('source $globals; echo $DARTEL');
DARTEL              = strrep(fstr,sprintf('\n'),'');
[~, fstr]           = system('source $globals; echo $SPMW');
SPMW                = strrep(fstr,sprintf('\n'),'');
[~, fstr]           = system('source $globals; echo $SPM');
SPM                 = strrep(fstr,sprintf('\n'),'');
[~, fstr]           = system('source $globals; echo $TOPUP');
TOPUP               = strrep(fstr,sprintf('\n'),'');
PREP_SOFTS          = {FSL DARTEL SPMW};

[~, fstr]           = system('source $globals; echo $RAW_DIR');
RAW_DIR             = strrep(fstr,sprintf('\n'),'');
[~, fstr]           = system('source $globals; echo $PREP_DIR');
PREP_DIR            = strrep(fstr,sprintf('\n'),'');
[~, fstr]           = system('source $globals; echo $ANALYSIS_DIR');
ANALYSIS_DIR        = strrep(fstr,sprintf('\n'),'');
[~, fstr]           = system('source $globals; echo $QA_DIR');
QA_DIR              = strrep(fstr,sprintf('\n'),'');
[~, fstr]           = system('source $globals; echo $OUT_DIR');
OUT_DIR             = strrep(fstr,sprintf('\n'),'');
[~, fstr]           = system('source $globals; echo $SCRIPT_DIR');
SCRIPT_DIR          = strrep(fstr,sprintf('\n'),'');

[~, fstr]           = system('source $globals; echo $SCRIPT_DIR_SHORT');
SCRIPT_DIR_SHORT    = strrep(fstr,sprintf('\n'),'');
[~, fstr]           = system('source $globals; echo $SCRIPT_DIR_QA');
SCRIPT_DIR_QA       = strrep(fstr,sprintf('\n'),'');
[~, fstr]           = system('source $globals; echo $SCRIPT_DIR_PREP');
SCRIPT_DIR_PREP     = strrep(fstr,sprintf('\n'),'');
[~, fstr]           = system('source $globals; echo $SCRIPT_DIR_SUBLVL');
SCRIPT_DIR_SUBLVL   = strrep(fstr,sprintf('\n'),'');
[~, fstr]           = system('source $globals; echo $SCRIPT_DIR_GRPLVL');
SCRIPT_DIR_GRPLVL   = strrep(fstr,sprintf('\n'),'');
[~, fstr]           = system('source $globals; echo $SCRIPT_DIR_UTIL');
SCRIPT_DIR_UTIL     = strrep(fstr,sprintf('\n'),'');
[~, fstr]           = system('source $globals; echo $SCRIPT_DIR_ROI');
SCRIPT_DIR_ROI      = strrep(fstr,sprintf('\n'),'');
