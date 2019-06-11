# NH3 satellite / model comparison scripts.

Scripts for extracting NH3 column information from WRF-Chem data files, and comparing it with IASI satellite data.

The data extraction scripts are written in NCL (https://www.ncl.ucar.edu/ - it can be installed using conda).

The data plotting scripts are written in python.

The python environment has been setup using conda. The environment
can be replicated using the command (using the spec-file.txt file in
the python directory):
conda create --name myenv --file spec-file.txt


IASI data can be downloaded from: https://iasi.aeris-data.fr/NH3/

Example headers for the IASI data-files (for which these scripts are written) are available here: http://cds-espri.ipsl.fr/etherTypo/index.php?id=1730&L=1


