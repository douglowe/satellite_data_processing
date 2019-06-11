Scripts for extracting the chemical data for a number of satellite overpasses
from a set of wrf output files.

"file_list.txt" contains a list of the satellite data files which will be
the templates for the model data storage files that we create (and provide
the measurement time and location information).

"scenario_settings.ncl.template" contains the scenario specific settings 
which will be needed to run this code.

"horizontal_slice_plotting_library.ncl" contains the routines needed for extracting
the column data from the model data.

"Model_Gasphase_Chemistry_Data_Extraction_FullPath_Single_Flight.ncl" and 
"Model_Gasphase_Chemistry_Setup_Output_File.ncl" are the main scripts for creating
and populating the new data files.

=== Running these scripts ===

1) create the "file_list.txt" file with the paths to your satellite data files
(e.g. ls -1 [path to files]/nh3nn* > file_list.txt)

2) edit scenario_settings.ncl.template to match your file structures
and layout.

3) to setup the storage files to which everything will be extracted you need to run:
qsub bat_make_storage_files.sh

4) to extract the data from the wrfout files you run this batch script:
qsub bat_extract_model_data.sh
