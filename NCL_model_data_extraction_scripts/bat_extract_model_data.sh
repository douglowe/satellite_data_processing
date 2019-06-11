#!/bin/bash --login
#
#PBS -l ncpus=1
#PBS -l walltime=48:00:00
#PBS -A n02-weat

module load netcdf
module load gcc
export NCARG_ROOT='/nerc/n02/n02/lowe/RDF_software/ncl-6.4.0'
export PATH=$PATH:/nerc/n02/n02/lowe/RDF_software/ncl-6.4.0/bin

cd $PBS_O_WORKDIR

year="2012"
months=( "01" "02" "07" "08" )
days=( "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" \
		"11" "12" "13" "14" "15" "16" "17" "18" "19" "20" \
		"21" "22" "23" "24" "25" "26" "27" "28" "29" "30" "31" )

times=( "AM" "PM" )
file_head="nh3nn_v2_2_"
file_path="/nerc/n02/n02/lowe/Clearflo_data_analysis/satellite_data/"

#nh3nn_v2_2_20120127_AM.nc

for MONTH in ${months[@]}; do

	for DAY in ${days[@]}; do
		
		for TIME in ${times[@]}; do
		
			file_name=${file_head}${year}${MONTH}${DAY}_${TIME}.nc
			
			echo ${file_name}
	
			if [ -e ${file_path}${file_name} ]; then
			
				sed -e "s|%%STAMP%%|${year}${MONTH}${DAY}_${TIME}|g" scenario_settings.ncl.template > scenario_settings.ncl
			
				ncl Model_Gasphase_Chemistry_Data_Extraction_FullPath_Single_Flight.ncl
				
			fi
	
		done
	
	done

done



#ncl Model_Gasphase_Chemistry_Data_Extraction_FullPath_Single_Flight.ncl &> log_file_gas.txt &


# wait for everything to finish
#wait

