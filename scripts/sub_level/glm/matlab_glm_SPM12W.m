% Run first level analysis based on pfile
function matlab_glm_SPM12W(sub,pfile)
run(pfile)

global realigns

prep_dir=fullfile(PREP_DIR, glm.prep_name, sub);
parfile = dir(fullfile(prep_dir, par_form));
realign=cell(1,length(parfile));

for i= 1: length(parfile)
	d{i} = importdata(fullfile(prep_dir, parfile(i).name));
	realign{i} = d{i};
end
realigns=realign;

spm12w_glm_compute('sid', sub, 'glm_file', pfile)
spm12w_glm_contrast('sid', sub, 'glm_file', pfile)
cd([SCRIPT_DIR filesep 'sub_level' filesep 'glm'])
matlab_glm_masking(sub,pfile);