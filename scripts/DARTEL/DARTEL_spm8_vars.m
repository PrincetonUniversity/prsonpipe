function DARTEL_spm8_vars(subs,pfile)

%=====================================================================%

%   DARTEL_spm8_vars.m 
%
%   August 2, 2016 -- Modified for PSNL pipeline by Miriam Weaverdyck
%                    (Created by Bob Spunt May 11, 2012)

%=====================================================================%

% get parameters
run(pfile)		

% load packages
addpath(p.spm8_dir)
addpath(p.NIfTI_dir)
addpath(p.scripts_dir)
spm('defaults','fmri'); spm_jobman('initcfg');              

%================================================%

% User Defined 

%================================================%


execTAG = p.execTAG;				% execute the job immediately? (0 = no, 1 = yes)

% do which subjects? ('all' to do all, subIDs in vector form, e.g. [1:4 101:103], to do a subset)
subTAG=subs;    

% customizable preprocessing parameters
vox_size=p.vox_size;				% voxel size at which to re-sample functionals (isotropic)
smooth_FWHM=p.smooth;				% smoothing kernel (isotropic)
normalize=p.normalize;				% run normalization?
realign=p.realign;					% run motion correction?

% folder/directory information
owd=p.proj_dir;				        % study directory
output=p.output;					% dir in which to save dartel output
subdirID=p.subdir;					% subjects directory containing subject folderss

% pattern for finding subject folders and run files
subID=p.subID;   					% pattern for finding subject folders (use wildcards)
runID=p.runID; 						% pattern for finding functional run files (use wildcards)

% image information
funcFormat=p.funcFormat;	        % format of your raw functional images (1=img/hdr, 2=4D nii)
mprageID=p.mprageID;            	% pattern for finding matched-bandwidth image (use wildcards)

% did you want to normalise only a subset of subjects? (leave empty for all)
donormsubs={};

% path for tissue probability maps (in spm8/tpm) for 'new segment'
TPMimg=p.TPMimg;

%================================================%

% End User Defined

%================================================%
%

% move into outer working directory (i.e. project directory)
cd(owd)

% find subject directories
cd(subdirID)
d=dir(subID);

% make list of all subjects found in directory
for i=1:length(d)
    subnam{i}=d(i).name;
%    fprintf('Adding %s to found subject list\n',subnam{i})
    snam=char(subnam{i});
    snum=str2num(snam(2:end));
    snums(i)=snum;
    fprintf('Adding %s to found subject list and %d to found subject numbers\n',subnam{i},snums(i))
end

% number of subjects found
subnum = length(subnam);

% make list of subjects to run based on indices of all subjects
if strcmp(subTAG,'all')
    dosubs = 1:subnum;
else
    for s = 1:length(subTAG)
        dosubs(s)=find(snums==subTAG(s));
        fprintf('Adding %d to run subject numbers\n',subTAG(s))
    end
end



%-----------------------------------------------------------------%

% Build MatlabBatch Structure for Each Subject

%-----------------------------------------------------------------%

for s = 1:length(dosubs)

    sub = dosubs(s);

    f = find(subnum==sub); % UNUSED?

    cbusub = sprintf('%s',subnam{sub});

    fprintf('Starting subject %d of %d, %s\n',s,length(dosubs),cbusub)

    swd = [subdirID filesep cbusub];    % subject working directory (cbusub = sub name)

    fprintf('Subject files found in %s\n',swd)

    base_dir = swd;

    cd(base_dir)
                                  


    % Find run directories

    %-----------------------------------------------------------------%

    if funcFormat==1
        runs=[runID '.img'];
    else
        runs=[runID '.nii'];
    end
    
    d=dir(runs);

    run_names = {d.name};

    numruns=length(run_names);

    fprintf('Found %d runs\n',numruns)

    

    % Find functional images for run(s)

    %-----------------------------------------------------------------%

    load_dir = {};

    raw_func_filenames = {};

    allfiles_orig = {};

    allfiles_norm = {};

    for i = 1:numruns                                                     

        load_dir{i} = fullfile(base_dir);
        
        fprintf('Run no. %d: %s\n', i, run_names{i});

        if funcFormat==1

            tmpString=sprintf('^%s.%s\\.img$',cbusub,runID);

            [raw_func_filenames{i},dirs] = spm_select('List',load_dir{i},tmpString);

            filenames_orig{i}=cellstr(strcat(load_dir{i},filesep,raw_func_filenames{i},',1'));

            filenames_norm{i}=cellstr(strcat(load_dir{i},filesep,'w',raw_func_filenames{i},',1'));

            allfiles_orig = [allfiles_orig; filenames_orig{i}];

        else

            tmpString=sprintf('^%s.*\\.nii$',runID);   % name of epi functional runs

            [raw_func_filenames{i},dirs] = spm_select('ExtFPList',load_dir{i},tmpString,1:10000);

            filenames_orig{i}=cellstr(strcat(raw_func_filenames{i},',1'));

            filenames_norm{i}=cellstr(strcat('w',raw_func_filenames{i},',1'));

            allfiles_orig = [allfiles_orig; filenames_orig{i}];

        end

    end

    if funcFormat==1

        mean_func=cellstr(strcat(load_dir{1},filesep,'mean',raw_func_filenames{1}(1,:),',1'));

    else

        [path name ext] = fileparts(allfiles_orig{1});

        mean_func=cellstr(strcat(path,filesep,'mean',name,'.nii,1'));

    end

    load_dir = fullfile(base_dir,run_names{i});  

    

    % Find the anatomicals

    % -------------------------------------------------

    mpragedir=base_dir;
    
    mprage_names={};

    % get the anatomical images

    cd(mpragedir); 
    
    d = dir(mprageID);

    mprage_names = {d.name}; 
    
    clear d

    mprage_name=mprage_names{1};
    
    mprage = [mpragedir filesep mprage_name];

    fprintf('mprage is: %s\n',mprage)

    [firstpart,lastpart] = strread(mprage,'%s %s');   
    

    % for DARTEL

    if s==1

        dartel_template = [mpragedir filesep 'Template_6.nii'];
        
        fprintf('dartel_template is: %s\n',dartel_template);

    end   

    for i = 1:length(run_names)
        run_names{i} = [base_dir filesep run_names{i}];
    end
    
    allfuncs{s} = run_names;

    allt2{s} = [mprage ',1'];

    allrc1{s} = [mpragedir filesep 'rc1' mprage_name(1:end-4) '.nii,1'];

    allrc2{s} = [mpragedir filesep 'rc2' mprage_name(1:end-4) '.nii,1'];

    allu_rc1{s} = [mpragedir filesep 'u_rc1' mprage_name(1:end-4) '_Template.nii,1'];

    

    % =====================================

    % Begin building MATLABBATCH

    % =====================================
   
   if realign == 0
    % motion correction already run on images in earlier preprocessing steps       
    % Create a mean image

    fprintf('Skipping motion correction. Creating mean image...\n')
    
        for i = 1:numruns
            
             fname = filenames_orig{i}{1}(1:end-4);
             
             curfunc = load_untouch_nii(fname);
             
             if i == 1 
                  
                 vsize = size(curfunc.img);
                 
                 mfuncs = NaN([vsize(1:3) numruns]);
                 
             end
             
             mfuncs(:,:,:,i) = mean(curfunc.img,4); 
              
             disp(['Loaded functional ' num2str(i) ' for mean']);
             
        end
         
        mmfunc = mean(mfuncs,4);
         
        outnii = curfunc;
         
        outnii.img = mmfunc;
         
        outnii.hdr.dime.dim(1) = 3;
        
        outnii.hdr.dime.dim(5) = 1;
         
        outname = strsplit(fname,'/');
         
        outname = ['mean' outname{end}];
         
        save_untouch_nii(outnii,outname);
         
    else
    % run motion correction here

    fprintf('Running motion correction...\n')
        % Realignment of functionals

        % -------------------------------------------------


        matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.quality = 0.9;         % higher quality

        matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.sep = 4;               % default is 4

        matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.fwhm = 5;              % default

        matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.rtm = 1;               % changed from 0 (=realign to first) to 1 (realign to mean) for

        matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.interp = 4;            % default

        matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0];        % default

        matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.weight = {};           % don't weight

        matlabbatch{2}.spm.spatial.realign.estwrite.roptions.which  = [0 1];        % create mean image only when reslicing

        matlabbatch{2}.spm.spatial.realign.estwrite.roptions.interp = 4;            % default

        matlabbatch{2}.spm.spatial.realign.estwrite.roptions.wrap   = [0 0 0];      % no wrap (default)

        matlabbatch{2}.spm.spatial.realign.estwrite.roptions.mask   = 1;            % enable masking (default)

        matlabbatch{2}.spm.spatial.realign.estwrite.roptions.prefix = 'r';

        

%        Co-register mprage to MEAN FUNCTIONAL
%
%       -------------------------------------------------

        matlabbatch{3}.spm.spatial.coreg.estimate.ref = mean_func;

        matlabbatch{3}.spm.spatial.coreg.estimate.source = cellstr(mprage);   

        matlabbatch{3}.spm.spatial.coreg.estimate.other{1} = '';

        matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';

        matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];

        matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];

        matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];
                  
    end


    matlabbatch{1}.spm.spatial.coreg.estimate.ref = mean_func;

    matlabbatch{1}.spm.spatial.coreg.estimate.source = cellstr(mprage);   

    matlabbatch{1}.spm.spatial.coreg.estimate.other{1} = '';

    matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';

    matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];

    matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];

    matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];


%    % SAVE/RUN UP TO THIS POINT

    % -------------------------------------------------

    a=datestr(clock,31);   % returns date string of the form 'YYYY-MM-DD HH:MM:SS' e.g., 2006-12-27 15:03:37

    time_stamp = [a(6:7) a(9:10) a(3:4) '_' a(12:13) a(15:16)];   % note timestamp is a function name, hence the _ in time_stamp

    filename = [output filesep 'PREDARTEL_' cbusub '_' time_stamp];

        save(filename,'matlabbatch');                           % save jobs variable in file batch_preproc_MMDDYY_HHMM.mat in subject's base directory

    if execTAG==1
       

        spm_jobman('run',matlabbatch);

    end

    clear matlabbatch

end

    

% Run NEW SEGMENT on mprages

% -------------------------------------------------                             

matlabbatch{1}.spm.tools.preproc8.channel.vols = allt2;  % cell array containing paths to all t2s

matlabbatch{1}.spm.tools.preproc8.channel.biasreg = 0.0001;

matlabbatch{1}.spm.tools.preproc8.channel.biasfwhm = 60;

matlabbatch{1}.spm.tools.preproc8.channel.write = [0 0];

matlabbatch{1}.spm.tools.preproc8.tissue(1).tpm = {[TPMimg ',1']};

matlabbatch{1}.spm.tools.preproc8.tissue(1).ngaus = 2;

matlabbatch{1}.spm.tools.preproc8.tissue(1).native = [0 1];   % [native_space DARTEL_Imported]

matlabbatch{1}.spm.tools.preproc8.tissue(1).warped = [0 0];

matlabbatch{1}.spm.tools.preproc8.tissue(2).tpm = {[TPMimg ',2']};

matlabbatch{1}.spm.tools.preproc8.tissue(2).ngaus = 2;

matlabbatch{1}.spm.tools.preproc8.tissue(2).native = [0 1];  % [native_space DARTEL_Imported]

matlabbatch{1}.spm.tools.preproc8.tissue(2).warped = [0 0];

matlabbatch{1}.spm.tools.preproc8.tissue(3).tpm = {[TPMimg ',3']};

matlabbatch{1}.spm.tools.preproc8.tissue(3).ngaus = 2;

matlabbatch{1}.spm.tools.preproc8.tissue(3).native = [0 0];  % [native_space DARTEL_Imported]

matlabbatch{1}.spm.tools.preproc8.tissue(3).warped = [0 0];

matlabbatch{1}.spm.tools.preproc8.tissue(4).tpm = {[TPMimg ',4']};

matlabbatch{1}.spm.tools.preproc8.tissue(4).ngaus = 3;

matlabbatch{1}.spm.tools.preproc8.tissue(4).native = [0 0];  % [native_space DARTEL_Imported]

matlabbatch{1}.spm.tools.preproc8.tissue(4).warped = [0 0];

matlabbatch{1}.spm.tools.preproc8.tissue(5).tpm = {[TPMimg ',5']};

matlabbatch{1}.spm.tools.preproc8.tissue(5).ngaus = 4;

matlabbatch{1}.spm.tools.preproc8.tissue(5).native = [0 0];  % [native_space DARTEL_Imported]

matlabbatch{1}.spm.tools.preproc8.tissue(5).warped = [0 0];

matlabbatch{1}.spm.tools.preproc8.tissue(6).tpm = {[TPMimg ',6']};

matlabbatch{1}.spm.tools.preproc8.tissue(6).ngaus = 2;

matlabbatch{1}.spm.tools.preproc8.tissue(6).native = [0 0];  % [native_space DARTEL_Imported]

matlabbatch{1}.spm.tools.preproc8.tissue(6).warped = [0 0];

matlabbatch{1}.spm.tools.preproc8.warp.reg = 4;

matlabbatch{1}.spm.tools.preproc8.warp.affreg = 'mni';

matlabbatch{1}.spm.tools.preproc8.warp.samp = 3;

matlabbatch{1}.spm.tools.preproc8.warp.write = [0 1];  % [inverse_deformation forward_deformation]



% Run DARTEL (Create Template)

% -------------------------------------------------

matlabbatch{2}.spm.tools.dartel.warp.images{1} = allrc1; 

matlabbatch{2}.spm.tools.dartel.warp.images{2} = allrc2; 

matlabbatch{2}.spm.tools.dartel.warp.settings.template = 'Template';

matlabbatch{2}.spm.tools.dartel.warp.settings.rform = 0;

matlabbatch{2}.spm.tools.dartel.warp.settings.param(1).its = 3;

matlabbatch{2}.spm.tools.dartel.warp.settings.param(1).rparam = [4 2 1e-06];

matlabbatch{2}.spm.tools.dartel.warp.settings.param(1).K = 0;

matlabbatch{2}.spm.tools.dartel.warp.settings.param(1).slam = 16;

matlabbatch{2}.spm.tools.dartel.warp.settings.param(2).its = 3;

matlabbatch{2}.spm.tools.dartel.warp.settings.param(2).rparam = [2 1 1e-06];

matlabbatch{2}.spm.tools.dartel.warp.settings.param(2).K = 0;

matlabbatch{2}.spm.tools.dartel.warp.settings.param(2).slam = 8;

matlabbatch{2}.spm.tools.dartel.warp.settings.param(3).its = 3;

matlabbatch{2}.spm.tools.dartel.warp.settings.param(3).rparam = [1 0.5 1e-06];

matlabbatch{2}.spm.tools.dartel.warp.settings.param(3).K = 1;

matlabbatch{2}.spm.tools.dartel.warp.settings.param(3).slam = 4;

matlabbatch{2}.spm.tools.dartel.warp.settings.param(4).its = 3;

matlabbatch{2}.spm.tools.dartel.warp.settings.param(4).rparam = [0.5 0.25 1e-06];

matlabbatch{2}.spm.tools.dartel.warp.settings.param(4).K = 2;

matlabbatch{2}.spm.tools.dartel.warp.settings.param(4).slam = 2;

matlabbatch{2}.spm.tools.dartel.warp.settings.param(5).its = 3;

matlabbatch{2}.spm.tools.dartel.warp.settings.param(5).rparam = [0.25 0.125 1e-06];

matlabbatch{2}.spm.tools.dartel.warp.settings.param(5).K = 4;

matlabbatch{2}.spm.tools.dartel.warp.settings.param(5).slam = 1;

matlabbatch{2}.spm.tools.dartel.warp.settings.param(6).its = 3;

matlabbatch{2}.spm.tools.dartel.warp.settings.param(6).rparam = [0.25 0.125 1e-06];

matlabbatch{2}.spm.tools.dartel.warp.settings.param(6).K = 6;

matlabbatch{2}.spm.tools.dartel.warp.settings.param(6).slam = 0.5;

matlabbatch{2}.spm.tools.dartel.warp.settings.optim.lmreg = 0.01;

matlabbatch{2}.spm.tools.dartel.warp.settings.optim.cyc = 3;

matlabbatch{2}.spm.tools.dartel.warp.settings.optim.its = 3;

    

% Run DARTEL - Normalise FUNCS to MNI space

% -------------------------------------------------

if normalize == 1

    matlabbatch{3}.spm.tools.dartel.mni_norm.template{1} = dartel_template;

    % figure out which subs to run

    if ~isempty(donormsubs)

        for s = 1:length(dosubs)

            donorm(s) = ~isempty(cell2mat(regexp(donormsubs,subnam{s})));

        end

        dosubs = find(donorm);

    end

    for s = 1:length(dosubs)

        matlabbatch{3}.spm.tools.dartel.mni_norm.data.subj(s).flowfield{1} = allu_rc1{dosubs(s)};

        matlabbatch{3}.spm.tools.dartel.mni_norm.data.subj(s).images = allfuncs{dosubs(s)};

    end                                              

    matlabbatch{3}.spm.tools.dartel.mni_norm.vox = [vox_size vox_size vox_size];

    matlabbatch{3}.spm.tools.dartel.mni_norm.bb = [-78 -112 -50; 78 76 85];

    matlabbatch{3}.spm.tools.dartel.mni_norm.preserve = 0;

    matlabbatch{3}.spm.tools.dartel.mni_norm.fwhm = [smooth_FWHM smooth_FWHM smooth_FWHM];



    % Run DARTEL - Normalise mprages to MNI space

    % -------------------------------------------------



    matlabbatch{4}.spm.tools.dartel.mni_norm.template{1} = dartel_template;

    for s = 1:length(dosubs)

        matlabbatch{4}.spm.tools.dartel.mni_norm.data.subj(s).flowfield{1} = allu_rc1{s};

        matlabbatch{4}.spm.tools.dartel.mni_norm.data.subj(s).images{1} = allt2{s};

    end                                              

    matlabbatch{4}.spm.tools.dartel.mni_norm.vox = [1 1 3];

    matlabbatch{4}.spm.tools.dartel.mni_norm.bb = [-78 -112 -50; 78 76 85];

    matlabbatch{4}.spm.tools.dartel.mni_norm.preserve = 0;

    matlabbatch{4}.spm.tools.dartel.mni_norm.fwhm = [0 0 0];

end

% SAVE/RUN 

% -------------------------------------------------

a=datestr(clock,31);   % returns date string of the form 'YYYY-MM-DD HH:MM:SS' e.g., 2006-12-27 15:03:37

time_stamp = [a(6:7) a(9:10) a(3:4) '_' a(12:13) a(15:16)];   % note timestamp is a function name, hence the _ in time_stamp

filename = [output filesep 'DARTEL_' cbusub '_' time_stamp];

    save(filename,'matlabbatch');                           % save jobs variable in file batch_preproc_MMDDYY_HHMM.mat in subject's base directory

if execTAG==1

    spm_jobman('run',matlabbatch);

end

return
