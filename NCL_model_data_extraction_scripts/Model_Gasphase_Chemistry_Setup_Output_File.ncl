; Script for extracting flight track data from WRFCHEM output files.
;

; load functions and procedures
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"


;load "../../WRFCHEM_misc.ncl"
;load "../../WRFCHEM_misc_stats.ncl"
;load "../../WRFCHEM_misc_file_operations.ncl"

load "scenario_settings.ncl"

begin

; set the NaN values
NaN = -9999.


;;;;; settings for different functions
; settings for wrf_user_ll_to_ij
POS_SET = True
POS_SET@returnInt = True



;;;;; define the chemicals we're after

chem_name = (/ \
"nh3" \
/)

chem_description = chem_name

MChem   = dimsizes(chem_name)

chem_units = new(MChem,string)
do ichem = 0,MChem-1
	chem_units(ichem) = "molec.cm^{-2}"
end do




;;; pull out the measurement information
; load data files
fil_data = addfile(MeasDir+"nh3nn_v2_2_"+Data_Time_Stamp+".nc","r")


; extract data
MeasLat = fil_data->latitude
MeasTime= fil_data->time


; close data files
delete(fil_data)


; grab dimension information
Meas_Sizes = dimsizes(MeasLat)

MDP     = Meas_Sizes(0)


;;; create the netcdf files for storing the data

; set netcdf4 configuration info
setfileoption("nc","format","netcdf4")
setfileoption("nc","preFill",False)
setfileoption("nc","CompressionLevel",4)

; backup the file if it already exists
if(isfilepresent(OutputDir+DatasetName+"_"+Data_Time_Stamp+"_gasphase_chemistry.nc"))then
	system("mv "+OutputDir+DatasetName+"_"+Data_Time_Stamp+"_gasphase_chemistry.nc "+\
				OutputDir+DatasetName+"_"+Data_Time_Stamp+"_gasphase_chemistry.nc.backup")
end if

; create new file
file_chem   = addfile(OutputDir+DatasetName+"_"+Data_Time_Stamp+"_gasphase_chemistry.nc", "c")


;;;;;; defining & writing file section ;;;;;;;;;;;;;;;;;;;;;
dimNames = (/"time"/)
dimSizes = (/MDP/)
dimUnlim = (/False/)

globalAtt = True
globalAtt@Parent_Model = ModelInfoString
globalAtt@Model_Directory = ModelDir

setfileoption(file_chem,"DefineMode",True)

	filedimdef(file_chem,dimNames,dimSizes,dimUnlim)
	
	fileattdef(file_chem,globalAtt)

	; loop through variables, defining them in the output file, then writing them out
	do jchem=0,MChem-1

		MDTemp := new((/MDP/),double,-9999)
		MDTemp@missing_value   = MDTemp@_FillValue
		copy_VarCoords(MeasLat,MDTemp)

		MDTemp@Description = chem_description(jchem)
		MDTemp@units = chem_units(jchem)

		filevardef(file_chem, chem_name(jchem), typeof(MDTemp), getvardims(MDTemp))                          
		filevarattdef(file_chem, chem_name(jchem), MDTemp)   

	end do
	
	; add the time variables
	filevardef(file_chem, "time", typeof(MeasTime), getvardims(MeasTime))
	filevarattdef(file_chem, "time", MeasTime)


	; add a new date variable
	MDTemp := new((/MDP/),double,-9999)
	copy_VarCoords(MeasTime,MDTemp)
	MDTemp@long_name = "UTC date and time of satellite acquisition"
	MDTemp@units = "hours since 1800-01-01 00:00:00"

	filevardef(file_chem, "date", typeof(MDTemp), getvardims(MDTemp))
	filevarattdef(file_chem, "date", MDTemp)
	
	

setfileoption(file_chem,"DefineMode",False)

;;;;;; end of defining & writing file section ;;;;;;;;;;;;;;;; 



print("successful completion of program")

end
