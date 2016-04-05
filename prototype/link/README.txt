== welcome to your NeuroPipe subject directory

this directory was automatically created by the program *scaffold* from your
NeuroPipe project directory. it should contain all scripts and data necessary to
perform the analysis of a single subject

all filepaths in this file will be written as relative to this directory


== directory structure

initially, your subject directory will look like this:
  |--README.txt
  |--run-order.txt
  |--globals.sh
  |--scripts/
  |--analysis/
  |--fsf/
  |--results/
  |--design/
  `--data/
     `--behavioral/


== getting started

your first step is to acquire the raw, DICOM formatted data from your fMRI scan
of this subject. Use scripts/retrieve-data-from-sun.sh to archive and compress that
data into a Gzipped TAR archive at *data/raw.tar.gz*

*run-order.txt* should describe your ideal scanning protocol, assuming you
customized it in the subject template. if your scanning protocol for this
subject differed at all from the one in *run-order.txt*, change that file now to
reflect the protocol you actually followed

next, we will:
- create BXH header files for your data (see
  http://nbirn.net/tools/bxh_tools/index.shtm),
- convert your data to Gzipped NifTi format (see
  http://nifti.nimh.nih.gov/nifti-1/),
- put your data into LAS orientation (see
  http://www.fmrib.ox.ac.uk/fslfaq/#general_radiologicaldef),
- and run BXH XCEDE QA tools (see http://nbirn.net/tools/bxh_tools/index.shtm),
  to generate a quality assurance report on your data

to do all that, run *./analyze.sh*. it should tell you that it's started running
the analysis, print nothing for a while, then tell you it's finished the
analysis.
