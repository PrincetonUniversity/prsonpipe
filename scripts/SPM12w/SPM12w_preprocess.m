function SPM12w_preprocess(sub,pfile,pkg_dir)
    addpath([pkg_dir 'spm12'])
    addpath([pkg_dir 'spm12w_new1608'])
    addpath([pkg_dir 'dicm2nii'])
    addpath([pkg_dir 'r2agui_v27'])
    spm12w_preprocess('sid',sub,'para_file',pfile);