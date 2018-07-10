function matlab_prep_SPM12W(sub,pfile)
	% Matlab function called by bash script run_SPM12w_prep
	% adds package paths, creates temporary raw directory by copying current sdir (s000) in prepdir (prep/TSK/wd) to tmp_raw_dir
	% runs spm12w_preprocess from pkg dir, then copies moves all files back to sdir from tmp_raw_dir, except those that are already there

    p.sid=sub;
    run(pfile);
    label='[SPMW.M] ';

    % add packages
    addpath(p.spm12_dir)
    addpath(p.spm12w_dir)
    addpath(p.dicm2nii_dir)
    addpath(p.r2agui_dir)
    
    % create temp raw directory
    tmpdir=fullfile(p.prepdir, 'SPMw_temp_raw/');
    tmp_rawdir=fullfile(tmpdir, p.sid);
    mkdir(tmp_rawdir);
    orig_prep=p.datadir;
    disp([label 'Moving sub directory ' orig_prep ' to ' tmp_rawdir '...'])
    movefile([orig_prep '/*'],tmp_rawdir);
    rmdir(orig_prep);

    disp([label 'running spm12w_preprocess...'])
    % run spm12w_preprocess
    try
      spm12w_preprocess('sid',sub,'para_file',pfile);
    catch me
      fprintf('%sAn error occuring during SPM12W processing.\n', label)
      fprintf('%sMoving original prep files back to prep directory\n', label)
      clean_up_temp(tmp_rawdir, p.datadir, label)
      exit(1)
    end
    % ONCE SPM12W PREPROCESS IS DONE, MOVE OLD AND NEW FILES BACK FROM TEMP_RAW TO SDIR
    disp([label 'Done running spm12w_preprocess. Moving original files back to subs folder'])
    clean_up_temp(tmp_rawdir, p.datadir, label)
    return

    %%%%% Function to clean up temp directory %%%%%
    function clean_up_temp(tmp_rawdir, datadir, label)
      % move files (except for ./ and ../) from tmp_raw back to subject folder
      files=dir(tmp_rawdir);
      for i = 1:length(files)
    	    fname=files(i).name;
          % check if file already exists in sdir
    	    if exist([datadir fname], 'file')
              % so, rename with an 'x' in front and still move
    		      new_fname=['x' fname];
	            disp([label datadir fname 'already exists. Renaming to ' new_fname])
	        else
	    	      new_fname=fname;
	        end
          % if not ./ or ../, move to sdir with new_fname
	        d=regexp(fname,'\.');
	        if (isempty(d) || d(1) ~= 1)
	          movefile(fullfile(tmp_rawdir,fname),fullfile(datadir,new_fname));
	        end
      end
      del=1;
      if isempty(dir([datadir '/anat.nii*']))
          disp([label 'Warning: no anat.nii* found in ' datadir '. Check ' tmp_rawdir ' for original anat.nii*'])
          del=0;
      end
      if isempty(dir([datadir '/epi_r*']))
          disp([label 'Warning: no epi_r* found in ' datadir '. Check ' tmp_rawdir ' for original epi_r*.nii*'])
          del=0;
      end
      disp([label 'Done moving files from ' tmp_rawdir ' to ' datadir])
      if del == 1
          disp([label 'Deleting temp directory ' tmp_rawdir '...'])      
        if length(dir([tmp_rawdir '*'])) <= 2
           rmdir(tmp_rawdir)
           disp([label 'Deleted ' tmp_rawdir])
        else
          disp([label 'WARNING: ' tmp_rawdir ' is not empty:'])
          disp(dir(tmp_rawdir))
        end
      end

      return
