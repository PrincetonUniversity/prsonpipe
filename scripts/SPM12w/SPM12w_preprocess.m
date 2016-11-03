function SPM12w_preprocess(sub,pfile)
	% Matlab function called by bash script run_SPM12w_prep
	% adds package paths, creates temporary raw directory by copying current sdir (s000) in prepdir (prep/TSK/wd) to tmp_raw_dir
	% runs spm12w_preprocess from pkg dir, then copies moves all files back to sdir from tmp_raw_dir, except those that are already there

    p.sid=sub;
    run(pfile);
    label='[SPMW.M] '

    % add packages
    addpath(p.spm12_dir)
    addpath(p.spm12w_dir)
    addpath(p.dicm2nii_dir)
    addpath(p.r2agui_dir)
    
    % create temp raw directory
    tmpdir=[p.prepdir 'SPMw_temp_raw/'];
    tmp_rawdir=[tmpdir p.sid '/'];
    mkdir(tmp_rawdir);
    orig_prep=[p.prepdir p.sid];
    disp([label 'Moving sub directory ' p.prepdir p.sid ' to ' tmp_rawdir '...'])
    movefile([orig_prep '/*'],tmp_rawdir);
    rmdir(orig_prep);

    disp([label 'running spm12w_preprocess...'])
    % run spm12w_preprocess
    spm12w_preprocess('sid',sub,'para_file',pfile);
    
    % ONCE SPM12W PREPROCESS IS DONE, MOVE OLD AND NEW FILES BACK FROM TEMP_RAW TO SDIR
    % move files (except for ./ and ../) from tmp_raw back to subject folder
    files=dir(tmp_rawdir);
    for i = 1:length(files)
    	fname=files(i).name;
        % check if file already exists in sdir
    	if exist([p.datadir fname])
            % so, rename with an 'x' in front and still move
    		new_fname=['x' fname];
	        disp([label p.datadir fname 'already exists. Renaming to ' new_fname])
	    else 
	    	new_fname=fname;
	    end
        % if ./ or ../, do not move, otherwise move to sdir with new_fname
	    d=regexp(fname,'\.');
	    if (isempty(d) || d(1) ~= 1)
	        movefile([tmp_rawdir '/' fname],[p.datadir new_fname]);
	    end
    end
    del=1;
    if isempty(dir([p.datadir '/anat.nii*']))
        disp([label 'Warning: no anat.nii* found in ' p.datadir '. Check ' tmp_rawdir ' for original anat.nii*'])
        del=0;
    end
    if isempty(dir([p.datadir '/epi_r*']))
        disp([label 'Warning: no epi_r* found in ' p.datadir '. Check ' tmp_rawdir ' for original epi_r*.nii*'])
        del=0;
    end
    if del == 1
        disp([label 'Deleting temp directory ' tmp_rawdir '...'])
        rmdir(tmp_rawdir)
    end
    disp([label 'Done moving files from ' tmp_rawdir ' to ' p.datadir])
    if isempty(dir([tmpdir '*']))
         rmdir(tmpdir)
         disp([label 'Deleted ' tmpdir])
    else
        disp([label 'WARNING: ' tmpdir ' is not empty:'])
        disp(dir([tmpdir '*']))
    end
