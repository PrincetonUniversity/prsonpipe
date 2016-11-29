function SPM12_lvl2(pfile)

%
%
%
%
%
% get parameters
run(pfile)

% load packages
addpath(glm.spm12_dir)


spm('defaults','fmri');
spm_jobman('initcfg');

level2Dir = fullfile(glm.study_dir, 'analysis',glm.user,'group');
cd(glm.study_dir)
if exist(level2Dir,'dir') == 0
    mkdir(level2Dir);
end 
output_dir = fullfile(level2Dir,glm.analysisname);
mkdir(output_dir)

subjects = dir(fullfile(glm.study_dir,glm.firstlevel_dir,'s*'));

vars_file = fopen(glm.vars);
subject_vars=textscan(vars_file,'%s %s','Delimiter',',');
fclose(vars_file);


x=1;
y=1;
for i = 1: length(subjects)
  group = subject_vars{2}{find(strcmp(subject_vars{1},subjects(i).name))};
  contrast_dir = fullfile(glm.study_dir,glm.firstlevel_dir,subjects(i).name);
  load(fullfile(contrast_dir,'SPM.mat'));
  contrast = SPM.xCon(find(strcmp({SPM.xCon.name},glm.contrast))).Vcon.fname;
  if strcmp(group,glm.group1)
    exp_files{x,1} = fullfile(contrast_dir,contrast);
    x=x+1;
  elseif strcmp(group,glm.group2)
    ctrl_files{y,1} = fullfile(contrast_dir,contrast);
    y=y+1;
  end
end

matlabbatch{1}.spm.stats.factorial_design.dir = {output_dir};
matlabbatch{1}.spm.stats.factorial_design.des.t2.scans1 = exp_files;
matlabbatch{1}.spm.stats.factorial_design.des.t2.scans2 = ctrl_files;
matlabbatch{1}.spm.stats.factorial_design.des.t2.dept = 0; %independent = 0, dependent = 1
matlabbatch{1}.spm.stats.factorial_design.des.t2.variance = 0; %equal variances = 0, unequal = 1
matlabbatch{1}.spm.stats.factorial_design.des.t2.gmsca = 0;
matlabbatch{1}.spm.stats.factorial_design.des.t2.ancova = 0;
matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.em = glm.mask;
matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;
matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cellstr([output_dir '/SPM.mat']);
matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
matlabbatch{3}.spm.stats.con.spmmat = cellstr([output_dir '/SPM.mat']);
matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = glm.analysisname;
matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [1 -1];
matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.delete = 0;


spm_jobman('run',matlabbatch);
end
