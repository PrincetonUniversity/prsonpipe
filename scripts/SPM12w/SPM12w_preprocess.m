function SPM12w_preprocess(sub,pfile,pkg_dir)
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
    disp(tmp_rawdir)
    
    % run spm12w_preprocess
    spm12w_preprocess('sid',sub,'para_file',pfile);
    
    % move files (except for epi_r* and anat*) from tmp_raw back to subject folder
    files=dir(tmp_rawdir);
    for i = 1:length(files)
        a=regexp(files(i).name,'anat.nii');
        e=regexp(files(i).name,'epi_r');
        d=regexp(files(i).name,'\.');
        if (isempty(d) || d(1) ~= 1) && (isempty(a) || a(1) ~= 1) && (isempty(e) || e(1) ~= 1)
            movefile([tmp_rawdir '/' files(i).name],[p.datadir '/' files(i).name]);
        end
    end
    del=1;
    if isempty(dir([p.datadir '/anat.nii*']))
        disp(['Warning: no anat.nii* found in ' p.datadir '. Check ' tmp_rawdir ' for original anat.nii*'])
        del=0;
    end
    if isempty(dir([p.datadir '/epi_r*']))
        disp(['Warning: no epi_r* found in ' p.datadir '. Check ' tmp_rawdir ' for original epi_r*.nii*'])
        del=0;
    end
    if del == 1
        rmdir(tmp_rawdir)
    end