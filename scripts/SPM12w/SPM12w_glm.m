% Run first level analysis based on pfile
%
%

function SPM12w_glm(sub,pfile,pkg_dir,prep_dir)

global realigns

par_form='*.par';

addpath(fullfile(pkg_dir, 'spm12'))
addpath(fullfile(pkg_dir, 'spm12w'))

parfile = dir(fullfile(prep_dir, sub, par_form));

for i= 1: length(parfile)
d{i} = importdata(fullfile(prep_dir, sub , parfile(i).name));
realign{i} = d{i};
end


realigns=realign;


spm12w_glm_compute('sid',sub,'glm_file',pfile)
spm12w_glm_contrast('sid',sub,'glm_file',pfile)
