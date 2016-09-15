function SPM12w_preprocess(sub,pfile,pkg_dir)
	% Matlab function called by bash script run_SPM12w_prep
	% adds package paths, creates temporary raw directory by copying current sdir (s000) in prepdir (prep/TSK/wd) to tmp_raw_dir
	% runs spm12w_preprocess from pkg dir, then copies moves all files back to sdir from tmp_raw_dir, except those that are already there

    % add packages
    addpath([pkg_dir 'spm12'])
    addpath([pkg_dir 'spm12w_new1608'])
    addpath([pkg_dir 'dicm2nii'])
    addpath([pkg_dir 'r2agui_v27'])
    
    % create temp raw directory
    p.sid=sub;
    run(pfile);
    tmp_rawdir=p.rawdir;
    movefile(p.datadir,tmp_rawdir);
    
    % run spm12w_preprocess
    spm12w_preprocess('sid',sub,'para_file',pfile);
    
    % move files (except for ./ and ../) from tmp_raw back to subject folder
    files=dir(tmp_rawdir);
    for i = 1:length(files)
    	fname=files(i).name;
    	if exist([p.datadir fname])
    		new_fname=['x' fname];
	        disp(['[SPMW] ' p.datadir fname 'already exists. Renaming to ' new_fname])
	    else 
	    	new_fname=fname;
	    end
	    d=regexp(fname,'\.');
	    if (isempty(d) || d(1) ~= 1)
	        movefile([tmp_rawdir '/' fname],[p.datadir new_fname]);
	    end
    end
    del=1;
    if isempty(dir([p.datadir '/anat.nii*']))
        disp(['[SPMw] Warning: no anat.nii* found in ' p.datadir '. Check ' tmp_rawdir ' for original anat.nii*'])
        del=0;
    end
    if isempty(dir([p.datadir '/epi_r*']))
        disp(['[SPMw] Warning: no epi_r* found in ' p.datadir '. Check ' tmp_rawdir ' for original epi_r*.nii*'])
        del=0;
    end
    if del == 1
        rmdir(tmp_rawdir)
    end
