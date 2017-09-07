function matlab_prep_DARTEL(subs,pfile)

%=====================================================================%
%  matlab_par_DARTEL_prep
%
%  Created and tested in MATLAB R2016b
%
%  Run SPM12 preprocessing, using DARTEL, in 4 steps:
%    1. Either: a) calculate mean epi and co-register anatomical and mean epi
%               b) motion correct and co-register anatomical and mean epi
%               c) motion correct, undistort using fieldmap, co-register
%                anat and epi
%    2. Segment anatomical into grey matter, white matter, and CSF
%    3. Run DARTEL, either using an existing template (previously created
%    or from CAT12), or creating a template based on your data
%    4. Normalize epi's, anatomicals, and segmentation maps using DARTEL
%
%  Based on: DARTEL_spm8_vars.m
%            August 2, 2016 -- Modified for PSNL pipeline by Miriam Weaverdyck
%                   (Created by Bob Spunt May 11, 2012)
%  Judith Mildner, June 8 2017:
%    Update to SPM12, paralellize, use existing template option, match
%      DAMNpipeline style guidelines better
%=====================================================================%
% Arguments:
%   array of subjects (numbers only)

%% load files and packages %%
% get parameters
run(pfile)

label='[DARTEL.M]';

% load packages
addpath(p.pkg_dir)
addpath(p.spm12_dir)
addpath(p.NIfTI_dir)
spm('defaults','fmri'); spm_jobman('initcfg');

%% Set up parameter names from par file %%
% do which subjects? ('all' to do all, subIDs in vector form, e.g. [1:4 101:103], to do a subset)
run_subs=subs;

% preprocessing parameters
vox_size=p.vox_size;		% voxel size at which to re-sample functionals (isotropic)
smooth_FWHM=p.smooth;		% smoothing kernel (isotropic)
normalize=p.normalize;		% run normalization?
realign=p.realign;			% run motion correction?
undistort=p.undistort;      % run undistortion? (using fieldmap)
epi_readout_time=p.epi_readout_time; % readout time in milliseconds
create_temp=p.template;     % study-specific template?

% folder/directory information
output_dir=p.output;		% dir in which to save dartel output
prep_dir=p.prepdir;			% subjects directory containing subject folders
pkg_dir=p.pkg_dir;

% pattern for finding subject folders and run files
subID=p.subID;   		% pattern for finding subject folders (use wildcards)
epiID=p.epiID; 			% pattern for finding functional run files (use wildcards)
anatID=p.anatID;        % pattern for finding matched-bandwidth image (use wildcards)
fieldmap_dir=p.fieldmap_dir; % directory with fieldmaps
fieldmap_name=p.fieldmap_name; % fieldmap filename (inside fieldmap_dir/<subjectID>)
magnitude_name=p.magnitude_name; % magnitude image name (inside fieldmap_dir/<subject_ID>)
nofieldmap_subs = p.nofieldmap_subs; % cell array of subjects that do not have a fieldmap
vdm_prefix='vdm5_'; %prefix added to fieldmap by spm12's FieldMap toolbox when creating VDM
blipdir=p.blipdir;

% path for tissue probability maps (in spm12/tpm) and templates (if create_temp = 0)
TPMimg=p.TPMimg;
if create_temp == 0
    template_dir=p.templateDir;
    template_suffix=p.templateSuffix;
end

%% Parallel processing setup %%
% create a local cluster object
pc = parcluster('local');
% explicitly set the JobStorageLocation to a directory in output_dir
parallel_dirname = [char(datetime('Now','Format','yyMMdd')),...
                        '_par_DARTEL_',getenv('SLURM_JOB_ID')];
mkdir(output_dir, parallel_dirname);
parallel_outdir = fullfile(output_dir, parallel_dirname);
pc.JobStorageLocation = parallel_outdir;
fprintf(['%s Running on %s, \n%s \t with job storage location %s, \n%s \t ', ...
    'and %d workers on %d threads\n'], label, pc.Host, label, ...
    pc.JobStorageLocation, label, pc.NumWorkers, pc.NumThreads)

% start the parallel pool with all available workers
parpool(pc, pc.NumWorkers);

%% Find subjects %%
% find subject directories
subdirs=dir(fullfile(prep_dir,subID));
fprintf('%s %s: Starting preprocessing \n', label, datestr(now))
%preallocate subname cell array
subnames=cell(length(subdirs),1);
subnums=zeros(length(subdirs),1);
% make list of all subjects found in directory
for i=1:length(subdirs)
  subnames{i}=subdirs(i).name;
  snam=char(subnames{i});
  snum=str2double(snam(2:end));
  subnums(i)=snum;
  fprintf('%s Adding %s to found subject list and %d to found subject numbers\n',...
      label, subnames{i}, subnums(i))
end

% number of subjects found
num_subs = length(subnames);

% make list of subjects to run
if strcmp(run_subs,'all')
  subs_index = 1:num_subs;
else
  subs_index = zeros(length(run_subs));
  for s = 1:length(run_subs)
    subs_index(s)=find(subnums==run_subs(s));
    fprintf('%s Adding %d to run subject numbers\n', label, run_subs(s))
  end
end

%% Get files for each subject %%

allepis = cell(length(subs_index),1);
allanat = cell(length(subs_index),1);
allfieldmap = cell(length(subs_index),1);
allmagnitude = cell(length(subs_index),1);
allvdm = cell(length(subs_index),1);
allrc1 = cell(length(subs_index),1);
allrc2 = cell(length(subs_index),1);
allrc3 = cell(length(subs_index),1);
allu_rc1 = cell(length(subs_index),1);
mean_funcs = cell(length(subs_index),1);

for sub_i = 1:length(subs_index)
  sub = subs_index(sub_i);

  current_subname = sprintf('%s',subnames{sub});
  fprintf('%s %s: Starting subject %d of %d, %s\n',label, datestr(now),...
      sub_i, length(subs_index),current_subname)
  % Find subject directory
  sub_prepdir = fullfile(prep_dir,current_subname); % subject working directory
  assert(isdir(sub_prepdir), '%s Directory %s not found\n', label, sub_prepdir)
  fprintf('%s Subject files found in %s\n', label, sub_prepdir)

  % Find epis
  epis=[epiID '.nii'];

  epidirs=dir(fullfile(sub_prepdir,epis));
  %if we can't find the .nii files, try unzipping
  if isempty(epidirs)
    system_gunzip_nii(sub_prepdir, epiID, label, 'epis')
    epidirs=dir(fullfile(sub_prepdir,epis));
    assert(~isempty(epidirs), '%s No epi (filename format %s) found in %s\n',...
        label, epiID, sub_prepdir)
  end

  % extract all epi names from this structure into cell array
  epi_names = extractfield(epidirs,'name');
  % turn it into a column cell array instead of row
  epi_names = epi_names';
  % add the path to the names
  epi_names = fullfile(sub_prepdir,epi_names);

  numruns=length(epi_names);
  fprintf('%s Found %d runs\n', label, numruns)

  % Find the anatomicals
  % -------------------------------------------------
  anatdirs = dir(fullfile(sub_prepdir,anatID));
  if isempty(anatdirs)
    system_gunzip_nii(sub_prepdir, anatID, label, 'anat')
    anatdirs=dir(fullfile(sub_prepdir,anatID));
    assert(~isempty(anatdirs), '%s No anat (filename format %s) found in %s',...
        label, anatID, sub_prepdir)
  end

  anat_names = {anatdirs.name};
  anat_name=anat_names{1};
  anat = [sub_prepdir filesep anat_name];
  fprintf('%s anat is: %s\n',label, anat)

  % for fieldmap undistortion
  fieldmap='';
  magnitude='';
  vdm='';
  if undistort == 1
    % if this subject does not appear in the list of no fieldmap subjects
    if ~any(strcmp(current_subname, nofieldmap_subs))
      fieldmap = fullfile(fieldmap_dir, current_subname, fieldmap_name);
      magnitude = fullfile(fieldmap_dir, current_subname, magnitude_name);
      %make sure we have a fieldmap, try unzipping if not
      if exist(fieldmap, 'file') == 0
        system_gunzip_nii(fullfile(fieldmap_dir, current_subname),...
            fieldmap_name, label, 'fieldmap')
      end
      %make sure we have a magnitude image , try unzipping if not
      if exist(magnitude, 'file') == 0
        system_gunzip_nii(fullfile(fieldmap_dir, current_subname),...
            magnitude_name, label, 'magnitude image')
      end

      vdm_name = [vdm_prefix fieldmap_name];
      vdm = fullfile(fieldmap_dir, current_subname, vdm_name);

      % throw an error if exist(fieldmap) evaluates to false
      assert(exist(fieldmap, 'file') == 2, '%s No fieldmap %s found in %s',...
        label, fieldmap_name, fullfile(fieldmap_dir, current_subname))
      assert(exist(magnitude, 'file') == 2, '%s No magnitude img %s found in %s',...
        label, magnitude_name, fullfile(fieldmap_dir, current_subname))
      fprintf('%s fieldmap is: %s\n \t with magnitude image %s\n',...
          label, fieldmap, magnitude)
    end
  end

  % for DARTEL
  if sub_i==1 && p.template==1
    dartel_template_6 = {[sub_prepdir filesep 'Template_6.nii']};
    template_dir = sub_prepdir;
    fprintf('%s dartel_template is: %s\n', label, dartel_template_6{1});
  elseif sub_i==1 && p.template == 0
    dartel_template_1 = {[template_dir filesep 'Template_1' template_suffix]};
    dartel_template_2 = {[template_dir filesep 'Template_2' template_suffix]};
    dartel_template_3 = {[template_dir filesep 'Template_3' template_suffix]};
    dartel_template_4 = {[template_dir filesep 'Template_4' template_suffix]};
    dartel_template_5 = {[template_dir filesep 'Template_5' template_suffix]};
    dartel_template_6 = {[template_dir filesep 'Template_6' template_suffix]};
    templates = [dartel_template_1, dartel_template_2, dartel_template_3,...
         dartel_template_4, dartel_template_5, dartel_template_6];
    for i = 1:length(templates)
      % make sure the templates exist
      if exist(templates{i}, 'file') == 0
        [~,temp_name, temp_ext] = fileparts(templates{i});
        system_gunzip_nii(template_dir,...
            [temp_name temp_ext], label, 'template')
        assert(exist(templates{i}, 'file') == 2, '%s Template %s not found',...
          label, templates{i})
      end
    end
    fprintf('%s dartel_template is: %s\n', label, dartel_template_6{1});
  end

  % Put all the files together in cell arrays
  allepis{sub_i} = epi_names;
  allanat{sub_i} = anat;
  allfieldmap{sub_i} = fieldmap;
  allmagnitude{sub_i} = magnitude;
  allvdm{sub_i} = vdm;
  allrc1{sub_i} = [sub_prepdir filesep 'rc1' anat_name];
  allrc2{sub_i} = [sub_prepdir filesep 'rc2' anat_name];
  allrc3{sub_i} = [sub_prepdir filesep 'rc3' anat_name];
  % u_rc naming depends on the template being used
  if create_temp==0
    allu_rc1{sub_i} = [sub_prepdir filesep 'u_rc1' anat_name];
  else
    allu_rc1{sub_i} = [sub_prepdir filesep 'u_rc1' anat_name(1:end-4) '_Template.nii'];
  end
  % make mean functional names out of the epi names
  [path, name , ext] = fileparts(allepis{sub_i}{1});
  mean_funcs{sub_i}=cellstr(strcat(path,filesep,'mean',name,ext));
end

%% Build matlabbatch for first step
% (create mean functional, and/or motion correct with or without unwarp)
% =====================================
% Begin building MATLABBATCH
% =====================================
%allepis = cell(length(subs_index),1);
for sub_i = 1:length(subs_index)
  sub = subs_index(sub_i);
  current_subname = sprintf('%s',subnames{sub});

  if realign == 0
    % motion correction already run on images in earlier preprocessing steps
    % coregister anatomical to mean functional (created when running this
    % step)
    matlabbatch{1}.spm.spatial.coreg.estimate.ref = mean_funcs{sub_i};
    matlabbatch{1}.spm.spatial.coreg.estimate.source = allanat(sub_i);
    matlabbatch{1}.spm.spatial.coreg.estimate.other{1} = '';
    matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
    matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
    matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
    matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];
    % no prefix to add
    prefix{sub_i} = '';
  elseif realign == 1 && undistort == 1 && ~any(strcmp(current_subname, nofieldmap_subs))
    fprintf('%s %s: Setting up fieldmap to VDM conversion...\n', label, datestr(now))
    % convert fieldmap to voxel displacement image (vdm)
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.data.precalcfieldmap.precalcfieldmap = allfieldmap(sub_i); %precalulated fieldmap (Hz)
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.data.precalcfieldmap.magfieldmap = allmagnitude(sub_i); %fieldmap magnitude image
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.et = [66 66]; %echo times ([short long])
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.maskbrain = 0; %mask brain?
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.blipdir = blipdir; % direction of blips along y (1 = PA, -1 = AP)
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.tert = epi_readout_time; % total epi readout time
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.epifm = 0; %epi-based fieldmap?
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.ajm = 0; % jacobian modulation?
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.method = 'Mark3D'; %unwrapping method (Mark2D, Mark3D, or Huttonish)
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.fwhm = 10; % FWHM for weighted smoothing of unwrapped maps
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.pad = 0; % size of padding kernel
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.ws = 1; % weighted smoothing?
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.template = {[p.spm12_dir,'/toolbox/FieldMap/T1.nii']}; %template for brain mask
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.fwhm = 5; % FWHM for mask smoothing
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.nerode = 2; %number of erosions for brain mask
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.ndilate = 4; % number of dilations for brian mask
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.thresh = 0.5; % threshold to create brain mask
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.reg = 0.02; % regularization
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.session.epi = allepis{sub_i}(end); % epi to unwarp
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.matchvdm = 1; % align vdm to epi?
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.sessname = 'r'; % suffix for vdm (will be followed by run number)
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.writeunwarped = 0; % write unwarped epi?
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.anat = allanat(sub_i); %anatomical image to display for comparison
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.matchanat = 0; %match anatomical to epi?
    % realign & unwarp
    fprintf('%s %s: Setting up motion correction with fieldmap undistortion (%s)...\n',...
        label, datestr(now), current_subname)
    matlabbatch{2}.spm.spatial.realignunwarp.data.scans = allepis{sub_i};% images to align & unwarp
    matlabbatch{2}.spm.spatial.realignunwarp.data.pmscan = allvdm(sub_i);% phase map
    matlabbatch{2}.spm.spatial.realignunwarp.eoptions.quality = 0.9;     % quality
    matlabbatch{2}.spm.spatial.realignunwarp.eoptions.sep = 4;           % separation
    matlabbatch{2}.spm.spatial.realignunwarp.eoptions.fwhm = 5;          % smoothing (FWHM)
    matlabbatch{2}.spm.spatial.realignunwarp.eoptions.rtm = 0;           % register to mean? (or first image)
    matlabbatch{2}.spm.spatial.realignunwarp.eoptions.einterp = 4;       % interpolation (nth degree B-spline)
    matlabbatch{2}.spm.spatial.realignunwarp.eoptions.ewrap = [0 0 0];   % wrapping ([x y z])
    matlabbatch{2}.spm.spatial.realignunwarp.eoptions.weight = '';       % weighting image
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.basfcn = [12 12];% basis functions
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.regorder = 1;    % regularisation
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.lambda = 100000; % regularisation factor
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.jm = 0;          % jacobian deformations
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.fot = [4 5];     % first-order effects ([4 5] is pitch and roll)
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.sot = [];        % second order effects
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.uwfwhm = 4;      % smoothing for unwarp
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.rem = 1;         % re-estimate motion parameters at each unwarping iteration?
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.noi = 5;         % number of iterations
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.expround = 'Average'; % Taylor expansion point
    matlabbatch{2}.spm.spatial.realignunwarp.uwroptions.uwwhich = [2 1]; % resliced images + mean?
    matlabbatch{2}.spm.spatial.realignunwarp.uwroptions.rinterp = 4;     % unwarp reslicing interpolation
    matlabbatch{2}.spm.spatial.realignunwarp.uwroptions.wrap = [0 0 0];  % wrapping
    matlabbatch{2}.spm.spatial.realignunwarp.uwroptions.mask = 1;        % mask images?
    matlabbatch{2}.spm.spatial.realignunwarp.uwroptions.prefix = 'ur';   % prefix
    % save the prefix to add to the epi names before the next step
    prefix{sub_i} = matlabbatch{2}.spm.spatial.realignunwarp.uwroptions.prefix;

    %Co-register mprage to MEAN FUNCTIONAL
    %-------------------------------------------------
    % Mean functional after realign & unwarp contains the prefix, so we
    % need to add that into the mean_func filenames first
    [epi_path, epi_name, epi_ext] = fileparts(allepis{sub_i}{1});
    mean_funcs{sub_i} = fullfile(epi_path, ['mean', prefix{sub_i}, epi_name, epi_ext]);
    matlabbatch{3}.spm.spatial.coreg.estimate.ref = mean_funcs(sub_i);
    matlabbatch{3}.spm.spatial.coreg.estimate.source = allanat(sub_i);
    matlabbatch{3}.spm.spatial.coreg.estimate.other{1} = '';
    matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
    matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
    matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
    matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];
  else
    % run motion correction without unwarp
    fprintf('%s %s: Setting up motion correction without fieldmap undistortion (%s)...\n',...
        label, datestr(now), current_subname)
    matlabbatch{1}.spm.spatial.realign.estwrite.data = allepis(sub_i);
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.quality = 0.9;   % higher quality
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.sep = 4;         % default is 4
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.fwhm = 5;        % default
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.rtm = 1;         % changed from 0 (=realign to first) to 1 (realign to mean) for
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.interp = 4;      % default
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0];  % default
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.weight = {};     % don't weight
    matlabbatch{1}.spm.spatial.realign.estwrite.roptions.which  = [2 1];  % create mean image and realigned epi's when reslicing
    matlabbatch{1}.spm.spatial.realign.estwrite.roptions.interp = 4;      % default
    matlabbatch{1}.spm.spatial.realign.estwrite.roptions.wrap   = [0 0 0];% no wrap (default)
    matlabbatch{1}.spm.spatial.realign.estwrite.roptions.mask   = 1;      % enable masking (default)
    matlabbatch{1}.spm.spatial.realign.estwrite.roptions.prefix = 'r';
    %Co-register mprage to MEAN FUNCTIONAL
    %-------------------------------------------------
    matlabbatch{2}.spm.spatial.coreg.estimate.ref = mean_funcs{sub_i};
    matlabbatch{2}.spm.spatial.coreg.estimate.source = allanat(sub_i);
    matlabbatch{2}.spm.spatial.coreg.estimate.other{1} = '';
    matlabbatch{2}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
    matlabbatch{2}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
    matlabbatch{2}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
    matlabbatch{2}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];
    % store the prefix for the next step
    prefix{sub_i} = matlabbatch{1}.spm.spatial.realign.estwrite.roptions.prefix;
  end

  % SAVE UP TO THIS POINT
  % -------------------------------------------------

  current_time = datestr(now, 'yyMMdd_hhmm');
  filename = fullfile(parallel_outdir, ['PREDARTEL_' subnames{sub_i} '_' current_time]);
  save(filename,'matlabbatch');

  spmbatch{sub_i} = matlabbatch;
  clear matlabbatch

  % make epi filenames for next step
  prepped_epis{sub_i} = cell(length(allepis{sub_i}),1);
  for n = 1:length(allepis{sub_i})
    [epi_path, epi_name, epi_ext] = fileparts(allepis{sub_i}{n});
    prepped_epis{sub_i}{n} = fullfile(epi_path, [prefix{sub_i}, epi_name, epi_ext]);
  end
end
%% Run step 1 (realignment with or w/o unwarp and/or align anat to mean epi)
fprintf('%s %s: Starting parallel processing\n', label, datestr(now))
if realign == 0
  % make sure we still have a parallel pool
  if isempty(gcp('nocreate')) == 1
      parpool(pc, pc.NumWorkers)
  end
  parfor s = 1:length(subs_index)
    fprintf('%s %s: Skipping motion correction. Creating mean image for subject %s...\n',...
        label, datestr(now), subnames{s})
    fname='';
    curfunc='';
    mfuncs=[];
    for i = 1:numruns
      fname = fullpath_epi_orig{s}{i}{1}(1:end-4);
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
    [out_path, outname, ext] = fileparts(fname);
    outname = [out_path filesep 'mean' outname ext];
    save_untouch_nii(outnii,outname);

    spm_jobman('run',spmbatch{s});
    fprintf('%s %s: Finished running mean functional and anat coregistration for %s',...
        label, datestr(now), subnames{s})
  end

else
  % make sure we still have a parallel pool
  if isempty(gcp('nocreate')) == 1
      parpool(pc, pc.NumWorkers)
  end
  parfor s = 1:length(subs_index)
    fprintf('%s %s: Running motion correction for subject %s...\n',...
        label, datestr(now), subnames{s})
    spm_jobman('run',spmbatch{s});
    fprintf('%s %s: Finished running motion correction for %s\n',...
        label, datestr(now), subnames{s})
  end
end
clear spmbatch

%% Run step 2: segmentation (parallel)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Run segmentation (SPM) on anatomicals -- Parallel
% -------------------------------------------------
for sub_i = 1:length(subs_index)
  matlabbatch{1}.spm.spatial.preproc.channel.vols = allanat(sub_i);
  matlabbatch{1}.spm.spatial.preproc.channel.biasreg = 0.001;
  matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 60;
  matlabbatch{1}.spm.spatial.preproc.channel.write = [0 0];
  matlabbatch{1}.spm.spatial.preproc.tissue(1).tpm = cellstr([TPMimg ',1']);
  matlabbatch{1}.spm.spatial.preproc.tissue(1).ngaus = 2;
  matlabbatch{1}.spm.spatial.preproc.tissue(1).native = [0 1];
  matlabbatch{1}.spm.spatial.preproc.tissue(1).warped = [1 0];
  matlabbatch{1}.spm.spatial.preproc.tissue(2).tpm = cellstr([TPMimg ',2']);
  matlabbatch{1}.spm.spatial.preproc.tissue(2).ngaus = 2;
  matlabbatch{1}.spm.spatial.preproc.tissue(2).native = [0 1];
  matlabbatch{1}.spm.spatial.preproc.tissue(2).warped = [1 0];
  matlabbatch{1}.spm.spatial.preproc.tissue(3).tpm = cellstr([TPMimg ',3']);
  matlabbatch{1}.spm.spatial.preproc.tissue(3).ngaus = 2;
  matlabbatch{1}.spm.spatial.preproc.tissue(3).native = [0 1];
  matlabbatch{1}.spm.spatial.preproc.tissue(3).warped = [1 0];
  matlabbatch{1}.spm.spatial.preproc.tissue(4).tpm = cellstr([TPMimg ',4']);
  matlabbatch{1}.spm.spatial.preproc.tissue(4).ngaus = 3;
  matlabbatch{1}.spm.spatial.preproc.tissue(4).native = [0 0];
  matlabbatch{1}.spm.spatial.preproc.tissue(4).warped = [0 0];
  matlabbatch{1}.spm.spatial.preproc.tissue(5).tpm = cellstr([TPMimg ',5']);
  matlabbatch{1}.spm.spatial.preproc.tissue(5).ngaus = 4;
  matlabbatch{1}.spm.spatial.preproc.tissue(5).native = [0 0];
  matlabbatch{1}.spm.spatial.preproc.tissue(5).warped = [0 0];
  matlabbatch{1}.spm.spatial.preproc.tissue(6).tpm = cellstr([TPMimg ',6']);
  matlabbatch{1}.spm.spatial.preproc.tissue(6).ngaus = 2;
  matlabbatch{1}.spm.spatial.preproc.tissue(6).native = [0 0];
  matlabbatch{1}.spm.spatial.preproc.tissue(6).warped = [0 0];
  matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1;
  matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1;
  matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
  matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';
  matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0;
  matlabbatch{1}.spm.spatial.preproc.warp.samp = 3;
  matlabbatch{1}.spm.spatial.preproc.warp.write = [0 1];


  current_time = datestr(now, 'yyMMdd_hhmm');
  filename = fullfile(parallel_outdir, ['SEGDARTEL_' subnames{sub_i} '_' current_time]);
  save(filename,'matlabbatch'); % save jobs variable
  spmbatch{sub_i} = matlabbatch;
  clear matlabbatch
end

fprintf('%s %s: Starting parallel processing for segmentation \n', label, datestr(now))
% make sure we still have a parallel pool
if isempty(gcp('nocreate')) == 1
  parpool(pc, pc.NumWorkers)
end
parfor s = 1:length(subs_index)
  fprintf('%s %s: Running segmentation for subject %s\n', label, datestr(now), subnames{s})
  spm_jobman('run',spmbatch{s});
  fprintf('%s %s: Finished segmentation for subject %s\n', label, datestr(now), subnames{s})
end

clear spmbatch

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Run step 3: DARTEL -- with existing template (parallel) or with create template
if create_temp == 0 %If create new template is set to 0 (no), use existing template
  % Run DARTEL (Existing Template) --parallel
  % -------------------------------------------------
  for sub_i = 1:length(subs_index)
    % check how many volumes the template has, and match with that number of
    % segmented images
    sub_rc_vols = {allrc1(sub_i); allrc2(sub_i); allrc3(sub_i)};
    template_vols = length(spm_vol(dartel_template_1{1}));
    matlabbatch{1}.spm.tools.dartel.warp1.images = sub_rc_vols(1:template_vols);
    matlabbatch{1}.spm.tools.dartel.warp1.settings.rform = 0;
    matlabbatch{1}.spm.tools.dartel.warp1.settings.param(1).its = 3;
    matlabbatch{1}.spm.tools.dartel.warp1.settings.param(1).rparam = [4 2 1e-06];
    matlabbatch{1}.spm.tools.dartel.warp1.settings.param(1).K = 0;
    matlabbatch{1}.spm.tools.dartel.warp1.settings.param(1).template = dartel_template_1;
    matlabbatch{1}.spm.tools.dartel.warp1.settings.param(2).its = 3;
    matlabbatch{1}.spm.tools.dartel.warp1.settings.param(2).rparam = [2 1 1e-06];
    matlabbatch{1}.spm.tools.dartel.warp1.settings.param(2).K = 0;
    matlabbatch{1}.spm.tools.dartel.warp1.settings.param(2).template = dartel_template_2;
    matlabbatch{1}.spm.tools.dartel.warp1.settings.param(3).its = 3;
    matlabbatch{1}.spm.tools.dartel.warp1.settings.param(3).rparam = [1 0.5 1e-06];
    matlabbatch{1}.spm.tools.dartel.warp1.settings.param(3).K = 1;
    matlabbatch{1}.spm.tools.dartel.warp1.settings.param(3).template = dartel_template_3;
    matlabbatch{1}.spm.tools.dartel.warp1.settings.param(4).its = 3;
    matlabbatch{1}.spm.tools.dartel.warp1.settings.param(4).rparam = [0.5 0.25 1e-06];
    matlabbatch{1}.spm.tools.dartel.warp1.settings.param(4).K = 2;
    matlabbatch{1}.spm.tools.dartel.warp1.settings.param(4).template = dartel_template_4;
    matlabbatch{1}.spm.tools.dartel.warp1.settings.param(5).its = 3;
    matlabbatch{1}.spm.tools.dartel.warp1.settings.param(5).rparam = [0.25 0.125 1e-06];
    matlabbatch{1}.spm.tools.dartel.warp1.settings.param(5).K = 4;
    matlabbatch{1}.spm.tools.dartel.warp1.settings.param(5).template = dartel_template_5;
    matlabbatch{1}.spm.tools.dartel.warp1.settings.param(6).its = 3;
    matlabbatch{1}.spm.tools.dartel.warp1.settings.param(6).rparam = [0.25 0.125 1e-06];
    matlabbatch{1}.spm.tools.dartel.warp1.settings.param(6).K = 6;
    matlabbatch{1}.spm.tools.dartel.warp1.settings.param(6).template = dartel_template_6;
    matlabbatch{1}.spm.tools.dartel.warp1.settings.optim.lmreg = 0.01;
    matlabbatch{1}.spm.tools.dartel.warp1.settings.optim.cyc = 3;
    matlabbatch{1}.spm.tools.dartel.warp1.settings.optim.its = 3;

    current_time = datestr(now, 'yyMMdd_hhmm');
    filename = fullfile(parallel_outdir, ['DARTEL_' current_subname '_' current_time]);
    save(filename,'matlabbatch');        % save jobs variable in file batch_preproc_MMDDYY_HHMM.mat in subject's base directory
    spmbatch{sub_i} = matlabbatch;
    clear matlabbatch
  end

  fprintf('%s %s: Starting parallel processing for DARTEL (existing template)\n',...
      label, datestr(now))
  % make sure we still have a parallel pool
  if isempty(gcp('nocreate')) == 1
      parpool(pc, pc.NumWorkers)
  end
  parfor s = 1:length(subs_index)
    fprintf('%s %s: Running DARTEL (existing template) for subject %s\n',...
        label, datestr(now), subnames{s})
    spm_jobman('run',spmbatch{s});
    fprintf('%s %s: Finished DARTEL (existing template) for subject %s\n',...
        label, datestr(now), subnames{s})
  end

  clear spmbatch

else
  % Run DARTEL (Create Template)
  % -------------------------------------------------
  matlabbatch{1}.spm.tools.dartel.warp.images{1} = allrc1;
  matlabbatch{1}.spm.tools.dartel.warp.images{2} = allrc2;
  matlabbatch{1}.spm.tools.dartel.warp.images{3} = allrc3;
  matlabbatch{1}.spm.tools.dartel.warp.settings.template = 'Template';
  matlabbatch{1}.spm.tools.dartel.warp.settings.rform = 0;
  matlabbatch{1}.spm.tools.dartel.warp.settings.param(1).its = 3;
  matlabbatch{1}.spm.tools.dartel.warp.settings.param(1).rparam = [4 2 1e-06];
  matlabbatch{1}.spm.tools.dartel.warp.settings.param(1).K = 0;
  matlabbatch{1}.spm.tools.dartel.warp.settings.param(1).slam = 16;
  matlabbatch{1}.spm.tools.dartel.warp.settings.param(2).its = 3;
  matlabbatch{1}.spm.tools.dartel.warp.settings.param(2).rparam = [2 1 1e-06];
  matlabbatch{1}.spm.tools.dartel.warp.settings.param(2).K = 0;
  matlabbatch{1}.spm.tools.dartel.warp.settings.param(2).slam = 8;
  matlabbatch{1}.spm.tools.dartel.warp.settings.param(3).its = 3;
  matlabbatch{1}.spm.tools.dartel.warp.settings.param(3).rparam = [1 0.5 1e-06];
  matlabbatch{1}.spm.tools.dartel.warp.settings.param(3).K = 1;
  matlabbatch{1}.spm.tools.dartel.warp.settings.param(3).slam = 4;
  matlabbatch{1}.spm.tools.dartel.warp.settings.param(4).its = 3;
  matlabbatch{1}.spm.tools.dartel.warp.settings.param(4).rparam = [0.5 0.25 1e-06];
  matlabbatch{1}.spm.tools.dartel.warp.settings.param(4).K = 2;
  matlabbatch{1}.spm.tools.dartel.warp.settings.param(4).slam = 2;
  matlabbatch{1}.spm.tools.dartel.warp.settings.param(5).its = 3;
  matlabbatch{1}.spm.tools.dartel.warp.settings.param(5).rparam = [0.25 0.125 1e-06];
  matlabbatch{1}.spm.tools.dartel.warp.settings.param(5).K = 4;
  matlabbatch{1}.spm.tools.dartel.warp.settings.param(5).slam = 1;
  matlabbatch{1}.spm.tools.dartel.warp.settings.param(6).its = 3;
  matlabbatch{1}.spm.tools.dartel.warp.settings.param(6).rparam = [0.25 0.125 1e-06];
  matlabbatch{1}.spm.tools.dartel.warp.settings.param(6).K = 6;
  matlabbatch{1}.spm.tools.dartel.warp.settings.param(6).slam = 0.5;
  matlabbatch{1}.spm.tools.dartel.warp.settings.optim.lmreg = 0.01;
  matlabbatch{1}.spm.tools.dartel.warp.settings.optim.cyc = 3;
  matlabbatch{1}.spm.tools.dartel.warp.settings.optim.its = 3;

  current_time = datestr(now, 'yyMMdd_hhmm');
  filename = fullfile(parallel_outdir, ['DARTEL_' current_subname '_' current_time]);
  save(filename,'matlabbatch');        % save jobs variable in file batch_preproc_MMDDYY_HHMM.mat in subject's base directory

 fprintf('%s %s: Running DARTEL (create template) for all inputted subjects\n',...
     label, datestr(now))
  spm_jobman('run',matlabbatch);
 fprintf('%s %s: Finished DARTEL (create template) for all inputted subjects\n',...
     label, datestr(now))
  clear matlabbatch
end

%% Run step 4: normalization (parallel)
% Run DARTEL - Normalise FUNCS to MNI space
% -------------------------------------------------
if normalize == 1
  % update allepis with output from step 1
  allepis = prepped_epis;

  %get Dartel's prefix
  if smooth_FWHM == 0
      dartel_prefix = 'w';
  else
      dartel_prefix = 'sw';
  end
  % get the complete prefix
  prefix = insertBefore(prefix,1,dartel_prefix);
  darteled_epis = cell(length(subs_index),1);
  for sub_i = 1:length(subs_index)
    matlabbatch{1}.spm.tools.dartel.mni_norm.template = dartel_template_6;
    matlabbatch{1}.spm.tools.dartel.mni_norm.data.subj.flowfield = allu_rc1(sub_i);
    matlabbatch{1}.spm.tools.dartel.mni_norm.data.subj.images = allepis{sub_i};
    matlabbatch{1}.spm.tools.dartel.mni_norm.vox = [vox_size vox_size vox_size];
    matlabbatch{1}.spm.tools.dartel.mni_norm.bb = [NaN NaN NaN; NaN NaN NaN];
    matlabbatch{1}.spm.tools.dartel.mni_norm.preserve = 0;
    matlabbatch{1}.spm.tools.dartel.mni_norm.fwhm = [smooth_FWHM smooth_FWHM smooth_FWHM];

    % Run DARTEL - Normalise mprages to MNI space
    % -------------------------------------------------
    all_anat_segs = [allanat, allrc1, allrc2, allrc3];
    matlabbatch{2}.spm.tools.dartel.mni_norm.template = dartel_template_6;
    matlabbatch{2}.spm.tools.dartel.mni_norm.data.subj.flowfield = allu_rc1(sub_i);
    matlabbatch{2}.spm.tools.dartel.mni_norm.data.subj.images = all_anat_segs(sub_i,:)';
    matlabbatch{2}.spm.tools.dartel.mni_norm.vox = [vox_size vox_size vox_size];
    matlabbatch{2}.spm.tools.dartel.mni_norm.bb = [NaN NaN NaN; NaN NaN NaN];
    matlabbatch{2}.spm.tools.dartel.mni_norm.preserve = 0;
    matlabbatch{2}.spm.tools.dartel.mni_norm.fwhm = [0 0 0];



  % SAVE/RUN
  % -------------------------------------------------
  current_time = datestr(now, 'yyMMdd_hhmm');
  filename = fullfile(parallel_outdir, ['NORMDARTEL_' current_subname '_' current_time]);
  save(filename,'matlabbatch');  % save jobs variable in file batch_preproc_MMDDYY_HHMM.mat in subject's base directory

  spmbatch{sub_i}=matlabbatch;
  clear matlabbatch

  % Get Dartel output filenames
  darteled_epis{sub_i} = cell(length(allepis{sub_i}),1);
  for n = 1:length(allepis{sub_i})
    [epi_path, epi_name, epi_ext] = fileparts(allepis{sub_i}{n});
    darteled_epis{sub_i}{n} = fullfile(epi_path, [dartel_prefix, epi_name, epi_ext]);
  end
  end

  fprintf('%s %s: Starting parallel processing for normalization to MNI space\n',...
      label, datestr(now))
  % make sure we still have a parallel pool
  if isempty(gcp('nocreate')) == 1
      parpool(pc, pc.NumWorkers)
  end
  parfor s = 1:length(subs_index)
    fprintf('%s %s: Running normalize to MNI for subject %s\n',...
        label, datestr(now), subnames{s})
    spm_jobman('run',spmbatch{s});
    fprintf('%s %s: Finished normalize to MNI for subject %s\n',...
        label, datestr(now), subnames{s})
  end
  % update allepis to darteled version
  allepis = darteled_epis;
end
%% Move the processed epis to epi_r01.nii (without the prefixes) and re-zip
gzip_nii = @system_gzip_nii;
parfor s = 1:length(subs_index)
   for epi = 1:length(allepis{s})
       processed_epi = allepis{s}{epi};
       clean_epi_name = regexp(processed_epi, 'epi_r\d{2}.nii', 'match');
       [clean_epi_path, ~, ~] = fileparts(processed_epi);
       clean_epi = char(fullfile(clean_epi_path, clean_epi_name));
       fprintf('%s %s: Updating %s with %s...\n', label, datestr(now), ...
           clean_epi, processed_epi)
       [cp_status, cp_msg, cp_msg_id] = copyfile(processed_epi, clean_epi, 'f')
       if cp_status == 1
        fprintf('%s %s: Successfully updated %s\n', label, datestr(now), clean_epi)
       else
        warning('%s %s: Updating %s with %s failed with message: \n %s (code: %s)',...
            label, datestr(now), clean_epi, processed_epi, cp_msg, cp_msg_id)
       end
   end
   pause(0.01)
   fprintf('%s %s: Starting gzip for subject %s...\n', label, datestr(now), subnames{s})
   [epi_dir, ~, ~] = fileparts(allepis{s}{1});
   feval(gzip_nii,epi_dir, label)
   % zip .niis in the fieldmap_dir
   [fieldmap_dir, ~, ~] = fileparts(allfieldmap{s});
   feval(gzip_nii,fieldmap_dir, label)
   % also zip templates, if they are not standard ones from a package
   if ~startsWith(template_dir, pkg_dir)
    feval(gzip_nii, template_dir, label)
   end
end
fprintf('%s $s: Finished DARTEL preprocessing for subjects %s ', label, ...
    datestr(now), strjoin(subnames))
%% Clean up Matlab's output
% Stop the parallel pool
delete(gcp('nocreate'))
% Get the files starting with 'Job' and delete them
delete_data = dir(fullfile(parallel_outdir, 'Job*'));
for i = 1:length(delete_data)
   if delete_data(i).isdir == 1
       rmdir(fullfile(delete_data(i).folder, delete_data(i).name));
   else
       delete(fullfile(delete_data(i).folder, delete_data(i).name));
   end
end

return
%% Functions
function system_gzip_nii(nii_dir, label)
 % Tries to gzip all .nii files in a directory using pigz. If pigz is not
 % found, it uses gzip instead. Using the system functions rather than
 % matlab's because it deletes original, but only if conversion
 % was successful. Matlab gzip does not delete or check.
 % Input argument dir = full path to directory containing .nii files to zip
 if ~isempty(dir(fullfile(nii_dir,'*.nii')))
  [pigz_status, pigz_out] = system(['pigz -f ', fullfile(nii_dir, '*.nii')]);
  % Use gzip if pigz isn't found
  if pigz_status == 127
    [gzip_status, gzip_out] = system(['gzip -f ', fullfile(nii_dir, '*.nii')]);
    if gzip_status ~= 0
      warning('%s Zipping .nii with gzip for in directory %s failed with message:\n "%s"\n',...
           label, nii_dir, gzip_out)
    end
  elseif pigz_status ~= 0
    warning('%s Zipping .nii with pigz for in directory %s failed with message:\n "%s"\n',...
           label, nii_dir, pigz_out)
  end
 end
return

function system_gunzip_nii(nii_dir, fileID, label, imageType)
 % unzips all nifti's matching fileID (can contain '*' wildcard).
 % Input arguments:
 %  dir = directory to look in
 %  fileID = files to unzip without extension (can contain '*')
 %  label = label to prepend before output messages
 %  imageType = name of image, e.g. 'epis' or 'anat' to print in error
 %  messages if it fails (optional)
 if nargin == 3
   imageType = 'niftis';
 end
 fprintf('%s %s: unzipping %s in %s...\n', label, datestr(now), imageType, nii_dir)
 % remove path and extension from fileID, if they were provided
 [~,fileID, ~] = fileparts(fileID);
 gz_fileID=[fileID '.nii.gz'];
 %use system gunzip because it deletes original, but only if conversion
 %was successful. Matlab gunzip does not delete or check.
 [status, cmdout] = system(['gunzip ', fullfile(nii_dir,gz_fileID)]);
 assert(status == 0, '%s gunzip for %s failed with error:\n %s',...
     label, fullfile(nii_dir,gz_fileID), cmdout)
return
