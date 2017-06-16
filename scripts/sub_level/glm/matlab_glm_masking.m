function matlab_glm_masking(subid, pfile)

	run(pfile)

	% paths
	% input directory = where the unmasked contrasts are
	inputdir = [glm.study_dir filesep 'analysis' filesep glm.username filesep 'glm' filesep glm.glm_name];
	inputdir_sub = [inputdir filesep subid];
	% output directory = where to save the masked contrasts
	outputdir_sub = [inputdir_sub filesep 'masked_cons'];
	% create the output directory if it doesn't exist
	if ~exist(outputdir_sub)
		mkdir(outputdir_sub)
	end

	% load grey matter mask
	fname = [glm.study_dir filesep 'auxil' filesep 'ref' filesep 'icbm152_gm25_spm12mask.nii'];
	mask = load_untouch_nii(fname);
	mask = mask.img;
	disp(['loaded mask ' fname])

	% find all contrast files
	fname = [inputdir_sub filesep 'con_*.nii'];
	confiles = dir(fname);
	ncons = length(confiles);
	% mask and save each contrast
	for i = 1:ncons
		cname = confiles(i).name;
		nii = load_untouch_nii([inputdir_sub filesep cname]);
		con = nii.img;
		con(mask==0) = NaN;
		fname = [outputdir_sub filesep cname];
		nii.img = con;
		save_untouch_nii(nii, fname);
		disp(['Saved ' fname])
	end
