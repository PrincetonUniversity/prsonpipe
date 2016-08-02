% spm12w r6225
% Parameters file for fMRI preprocessing
% Last updated: October, 2014
% =======1=========2=========3=========4=========5=========6=========7=========8

% User name
p.username = 'miriamw'

% Paths and names
p.study_dir = '/jukebox/tamir/miriamw/testpipe';
p.prep_name = 'SPM_prep';

% Preprocessing Routines - 1=yes 0=no
          
p.slicetime     = 1;        
p.realign       = 1;        
p.unwarp        = 1;      % Unwarping (correct field inhomogeneties)      
p.smoothing     = 8;   % Size of smoothing kernel in FWHM (0 for no smoothing)
p.snr           = 1;         % make SNR analysis document
p.slices        = 1;        
p.cleanup       = 2;            % delete intermediate files 0 (keep all), 1 (keep last), 
                                % 2 (keep last 2), 3 (keep last 2 and originals)
p.cleanupzip    = 0;            % Zip up the final stages

% Not currently working
p.normalize     = 'none';       % Normalize type ('none','epi','spm12','dartel')

% Uncomment and set equal to 1 or 0 if changing from default
%p.tripvols     = ;         
%p.shuffle      = ;         
%p.despike      = ;
