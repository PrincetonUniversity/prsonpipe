#!/usr/bin/env python3
# Read all json metadata files in input directory and output temporary conversion
# key based on scan list json file
# June 04, 2018: Judith Mildner created script
################################################################################----------
import argparse
import glob
import json
import csv
import os
import re


def parse_args(args):
    parser = argparse.ArgumentParser(description='''Reads all json files in input directory
                                                    and outputs conversion key based on
                                                    provided scan list json file''')
    parser.add_argument('-i', '--input_dir', required=True, type=str,
                        help='''directory to find scan json metadata files''')
    parser.add_argument('--input_filename_pattern', type=str, default='*.json',
                        help='''metadata filename pattern (e.g. \'scan_*\'. 
                            Note that \'s are required when using wildcards.''')
    parser.add_argument('-t', '--type', required=True, type=str,
                        help='kind of conversion to do',
                        choices=['dcm-bids', 'bids-damn'])
    parser.add_argument('-k', '--key', type=str,
                        help='scan list json file containing naming key')
    parser.add_argument('-o', '--output_file', required=True, type=str,
                        help='full path to file (.csv) to write output in.')
    parser.add_argument('subject', type=str, help='a subject ID (e.g. s001)')

    args = parser.parse_args()
    if not args.key and args.type != 'bids-damn':
        parser.error('Scan list json file (-k) is required, unless conversion'
                     + 'type is bids-damn or damn-bids.')
    if not str(args.subject).startswith('s'):
        if re.match('[0-9]{3}', args.subject):
            args.subject = 's' + str(args.subject)
        else:
            parser.error(args.subject + ' is not a valid subject ID')
    return args


def make_epi_name(name_type, subject, tsk, run):
    if name_type == 'bids':
        name = ('sub-' + subject + '_task-' + tsk
                + '_run-' + str(run).zfill(2) + '_bold.nii.gz')
    elif name_type == 'damn':
        name = (tsk + '/' + subject + '/epi_' + tsk + '_r' +
                str(run).zfill(2) + '.nii.gz')
    else:
        raise RuntimeError("unknown name type " + name_type + " given.")
    return name


def make_se_name(name_type, subject, tsk, direction):
    if name_type == 'bids':
        task = 'task' if tsk == 'ALL' else tsk
        name = ('sub-' + subject + '_acq-' + task + '_dir-'
                + direction + '_epi.nii.gz')
    elif name_type == 'damn':
        task = 'ALL' if tsk == 'task' else tsk
        name = task + '/' + subject + '/' + task + '_SE_' + direction + '.nii.gz'
    else:
        raise RuntimeError("unknown name type " + name_type + " given.")
    return name


def make_anat_name(name_type, subject, modality):
    if name_type == 'bids':
        name = ('sub-' + subject + '_' + modality + '.nii.gz')
    elif name_type == 'damn':
        name = 'ALL/' + subject + '/anat.nii.gz'
    else:
        raise RuntimeError("unknown name type " + name_type + " given.")
    return name


def read_input_metadata(input_dir, input_filename_pattern):
    # Read all json metadata files in input directory
    if input_filename_pattern is not None:
        search = input_filename_pattern
        json_search_string = search if '.json' in search else search + '.json'
    else:
        json_search_string = '*.json'

    search_path = os.path.join(input_dir, json_search_string)
    all_input_files = glob.glob(search_path)

    scan_data = {}
    for f in all_input_files:
        with open(f, 'r') as input_json:
            metadata = json.load(input_json)
            scan_key = metadata['SeriesNumber']
            scan_dict = {
                'protocol_name': metadata['ProtocolName'],
                'series_desc': metadata['SeriesDescription'],
                'tr': metadata['RepetitionTime']
            }

        scan_data[scan_key] = scan_dict
    return scan_data


def get_convert_protocol(key, subject):
    # get the scan list to use as conversion key
    with open(key) as scan_keys:
        scan_list = json.load(scan_keys)
        protocol_options = scan_list.keys()
        # see if subject is listed in the file with a special protocol
        use_protocol = [a for a in protocol_options if subject in a]
        # use default if not found, or first appearance of subject ID
        use_protocol = 'default' if len(use_protocol) == 0 else use_protocol[0]
        return scan_list[use_protocol]


def find_matching_scans(scan_params, scan_data):
    protocol_name = scan_params['protocol_name']
    # find all scans with protocol name that matches the provided name
    matching_scans = [number for number in scan_data.keys()
                      if protocol_name in scan_data[number][
                          'protocol_name']]
    # identify motion corrected duplicates
    moco_scans = [number for number in matching_scans
                  if 'MoCoSeries' in scan_data[number]['series_desc']]
    # use motion corrected scans or discard them, depending on the value
    # set for 'useMoCo'
    if 'useMoCo' not in scan_params:
        scan_params['useMoCo'] = 'no'
    if (str(scan_params["useMoCo"]).lower() in ('no', 'n')) \
            | (not bool(scan_params["useMoCo"])):
        convert_scans = [scan for scan in matching_scans
                         if scan not in moco_scans]
    else:
        convert_scans = moco_scans

    if len(convert_scans) == 0:
        raise RuntimeError('No scans found for ' + protocol_name)

    return convert_scans


def task_dcm_to_bids(scan, scan_params, scan_data, input_dir, subject):
    convert_scans = find_matching_scans(scan_params, scan_data)
    # make sure all remaining scans have the correct number of TRs, as
    # specified in 'ntrs' variable
    full_ntrs_scans = []
    for found_scan in convert_scans:
        ntrs = len(glob.glob(input_dir + '/' + str(found_scan) + '-*.dcm'))
        if ntrs == scan_params['ntrs']:
            full_ntrs_scans.append(found_scan)
        else:
            raise RuntimeWarning('dcm series ' + str(found_scan)
                                 + ' contains ' + str(ntrs)
                                 + 'TRs, but expected '
                                 + str(scan_params['ntrs'])
                                 + ' TRs for task ' + scan
                                 + ' based on scan list json file.')

    # make sure we have the correct number of runs remaining
    if len(full_ntrs_scans) != scan_params['nruns']:
        raise RuntimeError('found ' + str(len(full_ntrs_scans))
                           + ' runs for task ' + scan
                           + ' (matching protocol name '
                           + scan_params['protocol_name'] + '), but expected '
                           + str(scan_params['nruns'])
                           + ' runs based on scan list json file.')

    # output series number, default dcm2niix filename, and bids filename
    # for each run found
    task_data = []
    i = 1
    for run in sorted(full_ntrs_scans):
        series_number = run
        default_converted_name = 'scan_' + str(run).zfill(2) + '.nii.gz'
        bids_name = 'func/' + make_epi_name('bids', subject, scan, i)
        damn_name = make_epi_name('damn', subject, scan, i)
        task_data.append([series_number, default_converted_name, bids_name,
                          damn_name])
        i += 1
    return task_data


def anat_dcm_to_bids(scan_params, scan_data, subject):
    convert_scans = find_matching_scans(scan_params, scan_data)
    modality = scan_params.get('modality') or 'T1w'
    if len(convert_scans) > 1:
        raise RuntimeError('found ' + str(len(convert_scans))
                           + ' scans for anatomical (matching protocol name '
                           + scan_params['protocol_name']
                           + '). There can only be one ' + modality
                           + ' anatomical.')
    series_number = convert_scans[0]
    default_converted_name = 'scan_' + str(convert_scans[0]).zfill(2) + '.nii.gz'
    bids_name = 'anat/' + make_anat_name('bids', subject, modality)
    damn_name = make_anat_name('damn', subject, modality)
    return [[series_number, default_converted_name, bids_name, damn_name]]


def fieldmap_dcm_to_bids(scan, scan_params, scan_data, subject):
    spin_echo = dict()
    spin_echo['AP'] = scan_params.copy()
    spin_echo['AP'].update({'protocol_name': scan_params['protocol_name']['AP']})
    spin_echo['PA'] = scan_params.copy()
    spin_echo['PA'].update({'protocol_name': scan_params['protocol_name']['PA']})
    spin_echo['AP']['scans'] = find_matching_scans(spin_echo['AP'], scan_data)
    spin_echo['PA']['scans'] = find_matching_scans(spin_echo['PA'], scan_data)
    se_data = []
    for se_dir, se_params in spin_echo.items():
        convert_scans = se_params['scans']
        if len(convert_scans) > 1:
            raise RuntimeError('found ' + str(len(convert_scans))
                               + ' scans for spin echo ' + scan
                               + '(matching protocol name '
                               + se_params['protocol_name']
                               + '). There can only be one ' + se_dir
                               + ' spin echo per task.')
        series_number = convert_scans[0]
        default_converted_name = 'scan_' + str(convert_scans[0]).zfill(2) \
                                 + '.nii.gz'
        se_intended_for = scan.replace('_SE', '')
        acq = se_intended_for if se_intended_for != 'ALL' else 'task'
        bids_name = 'fmap/' + make_se_name('bids', subject, acq, se_dir)
        damn_name = make_se_name('damn', subject, acq, se_dir)
        se_data.append([series_number, default_converted_name, bids_name,
                        damn_name])

    return se_data


def dcm_to_bids(protocol, scan_data, input_dir, subject):
    conversion_data = []
    for scan, scan_params in protocol.items():
        if scan_params['type'] == 'task':
            conversion_data += task_dcm_to_bids(scan, scan_params, scan_data,
                                                input_dir, subject)
        elif scan_params['type'] == 'anat':
            conversion_data += anat_dcm_to_bids(scan_params, scan_data, subject)
        elif scan_params['type'] == 'fieldmap':
            conversion_data += fieldmap_dcm_to_bids(scan, scan_params,
                                                    scan_data, subject)
    return conversion_data


def bids_to_damn(input_dir, subject):
    subject_dirname = 'sub-' + subject
    if os.path.basename(input_dir.rstrip('/')) != subject_dirname:
        file_dir = (os.path.join(input_dir, subject_dirname) if
                    os.path.exists(os.path.join(input_dir, subject_dirname))
                    else os.path.join(input_dir, 'bids', subject_dirname))
    else:
        file_dir = input_dir
    if not os.path.exists(file_dir):
        raise RuntimeError('BIDS directory ' + subject_dirname
                           + ' not found in input directory ' + input_dir)
    # bids has files in subdirectories, so get all nifti's in subdir.
    bids_niftis = glob.glob(file_dir + '/*/*.nii.gz')
    conversion_data = []
    for nifti in bids_niftis:
        # get subdirectory name
        subdir = os.path.basename(os.path.dirname(nifti))
        filename = os.path.basename(nifti)
        if subdir == 'func':
            func_bids_p = re.compile(r'^sub-(?P<sub>s[0-9]{3})'
                                     r'_task-(?P<tsk>[A-Z]{3})'
                                     r'_run-(?P<run>[0-9]{2}).*_bold.nii.gz')
            scan_match = func_bids_p.match(filename)
            if not scan_match:
                raise RuntimeError('Nifti file ' + filename + ' was found in '
                                   + subdir + ' but filename pattern does not '
                                   + 'match expected naming pattern for epi')
            scan_info = scan_match.groupdict()
            damn_filename = make_epi_name('damn', subject, scan_info['tsk'],
                                          scan_info['run'])
        elif subdir == 'fmap':
            fmap_bids_p = re.compile(r'^sub-(?P<sub>s[0-9]{3})'
                                     r'_acq-(?P<tsk>[A-Za-z]{3,4})'
                                     r'_dir-(?P<dir>[A-Z]{2}).*_epi.nii.gz')
            scan_match = fmap_bids_p.match(filename)
            if not scan_match:
                raise RuntimeError('Nifti file ' + filename + ' was found in '
                                   + subdir + ' but filename pattern does not '
                                              'match expected naming pattern '
                                              'for spin echo')
            scan_info = scan_match.groupdict()
            tsk = scan_info['tsk'] if scan_info['tsk'] != 'task' else 'ALL'
            damn_filename = make_se_name('damn', subject, tsk, scan_info['dir'])
        elif subdir == 'anat':
            damn_filename = make_anat_name('damn', subject, '')
        else:
            raise RuntimeError('Nifti file found in ' + subdir + '. This BIDS '
                               + 'subdirectory does not match a known scan type'
                               + '(func, fmap, or anat).')
        conversion_data.append([nifti, damn_filename])
    return conversion_data


def main(args):
    args = parse_args(args)
    if args.type == 'dcm-bids':
        input_metadata = read_input_metadata(args.input_dir,
                                             args.input_filename_pattern)
        convert_protocol = get_convert_protocol(args.key, args.subject)
        conversion_data = dcm_to_bids(convert_protocol, input_metadata,
                                      args.input_dir, args.subject)
    elif args.type == 'bids-damn':
        conversion_data = bids_to_damn(args.input_dir, args.subject)

    with open(args.output_file, "w", newline='') as f:
        writer = csv.writer(f)
        writer.writerows(conversion_data)


if __name__ == '__main__':
    import sys
    main(sys.argv[1:])
