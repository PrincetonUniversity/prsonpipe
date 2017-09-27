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

% create text file with contrast names and numbers
glm_dir = fullfile(ANALYSIS_DIR, glm.username, 'glm', glm.glm_name, sub);
load(fullfile(glm_dir, 'SPM.mat'))
con_table = struct2table(SPM.xCon);
con_info = cell2mat({SPM.xCon.Vcon});
con_table.con_file = {con_info.fname}';
writetable(con_table(:, {'con_file', 'name'}), fullfile(glm_dir, 'contrast_list.txt'),...
    'Delimiter', ' ')
