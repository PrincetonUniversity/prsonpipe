clear globals_file
clear globals
[~, globals_file] = system('script_dir="$(dirname -- "$(pwd)")"; echo "${script_dir%scripts*}/scripts/globals.par"');
setenv('globals', globals_file)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PROJECT SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[~, fstr]		 		= system('source $globals; echo $PROJECT_NAME');
PROJECT_NAME 			= strrep(fstr,sprintf('\n'),'');
[~, fstr]		 		= system('source $globals; echo $PROJECT_DIR');
PROJECT_DIR 			= strrep(fstr,sprintf('\n'),'');
[~, fstr]		 		= system('source $globals; echo $USER_EMAIL');
USER_EMAIL  			= strrep(fstr,sprintf('\n'),'');
[~, fstr]		 		= system('source $globals; echo $LAB_NAME');
LAB_NAME 				= strrep(fstr,sprintf('\n'),'');
[~, fstr]		 		= system('source $globals; echo $PKG_DIR');
PKG_DIR					= strrep(fstr,sprintf('\n'),'');
[~, fstr]		 		= system('source $globals; echo $SCANNER');
SCANNER					= strrep(fstr,sprintf('\n'),'');

% tasks
%TASKS] = system('source $globals; for t in ${TASKS[@]}; do [[ $t == ${TASKS[0]} ]] && \
%	marray=[ || marray=$marray,; marray="$marray$t"; done; marray=$marray]; echo $marray');
[~, fstr]		 		= system('source $globals; echo $PREP_SEP'); 
PREP_SEP 				= str2num(fstr(1));
[~, fstr]		 		= system('source $globals; echo $NUM_TASKS'); 
NUM_TASKS 				= str2num(fstr(1));

[~, fstr]		 		= system('source $globals; echo $BACKUP_DIR'); 
BACKUP_DIR				= strrep(fstr,sprintf('\n'),'');

% prep software names
[~, fstr]		 		= system('source $globals; echo $FSL'); 
FSL						= strrep(fstr,sprintf('\n'),'');
[~, fstr]		 		= system('source $globals; echo $DARTEL'); 
DARTEL					= strrep(fstr,sprintf('\n'),'');
[~, fstr]		 		= system('source $globals; echo $SPMW'); 
SPMW					= strrep(fstr,sprintf('\n'),'');
[~, fstr]		 		= system('source $globals; echo $SPM'); 
SPM						= strrep(fstr,sprintf('\n'),'');
PREP_SOFTS		 		= {FSL DARTEL SPMW};

[~, fstr]		 		= system('source $globals; echo $PARS_DIR');
PARS_DIR				= strrep(fstr,sprintf('\n'),'');
[~, fstr]		 		= system('source $globals; echo $RAW_DIR');
RAW_DIR					= strrep(fstr,sprintf('\n'),'');
[~, fstr]		 		= system('source $globals; echo $PREP_DIR');
PREP_DIR				= strrep(fstr,sprintf('\n'),'');
[~, fstr]		 		= system('source $globals; echo $QA_DIR');
QA_DIR					= strrep(fstr,sprintf('\n'),'');
[~, fstr]		 		= system('source $globals; echo $OUT_DIR');
OUT_DIR					= strrep(fstr,sprintf('\n'),'');
[~, fstr]		 		= system('source $globals; echo $SCRIPT_DIR');
SCRIPT_DIR				= strrep(fstr,sprintf('\n'),'');

%SCRIPT_DIR_SHORT	
[~, fstr]		 		= system('source $globals; echo $SCRIPT_DIR_FSL');
SCRIPT_DIR_FSL			= strrep(fstr,sprintf('\n'),'');
[~, fstr]		 		= system('source $globals; echo $SCRIPT_DIR_DARTEL');
SCRIPT_DIR_DARTEL		= strrep(fstr,sprintf('\n'),'');
[~, fstr]		 		= system('source $globals; echo $SCRIPT_DIR_SPM');
SCRIPT_DIR_SPM			= strrep(fstr,sprintf('\n'),'');
[~, fstr]		 		= system('source $globals; echo $SCRIPT_DIR_SPMW');
SCRIPT_DIR_SPMW			= strrep(fstr,sprintf('\n'),'');
[~, fstr]		 		= system('source $globals; echo $SCRIPT_DIR_UTIL');
SCRIPT_DIR_UTIL			= strrep(fstr,sprintf('\n'),'');
