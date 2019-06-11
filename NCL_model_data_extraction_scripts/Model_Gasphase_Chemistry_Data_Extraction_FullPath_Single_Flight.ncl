; Script for extracting flight track data from WRFCHEM output files.
;

; load functions and procedures
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_inv_string.ncl"


load "horizontal_slice_plotting_library.ncl"

;load "WRFCHEM_misc.ncl"
;load "../../WRFCHEM_misc_stats.ncl"
;load "WRFCHEM_misc_file_operations.ncl"


load "scenario_settings.ncl"

begin

; set the NaN values
NaN = -9999.


;;;;; settings for different functions
; settings for wrf_user_ll_to_ij
POS_SET = True
POS_SET@returnInt = True


;setfileoption ("nc","Format","NetCDF4")
;setfileoption("nc","CompressionLevel",4)
;;;;;;;; open the netcdf file for storing the data
file_chem   = addfile(OutputDir+DatasetName+"_"+Data_Time_Stamp+"_gasphase_chemistry.nc", "w")


; pull out the Model Directory information from the output file, so we always use the correct data
ModelDir = file_chem@Model_Directory

; read the variables which we want to extract
chem_name = getfilevarnames(file_chem)

;;;; remove time and date from variable list (messy technique, is there any cleaner way to do this?!)
; find the locations containing *only* date or time, and clear those strings
ind_out = str_match_ind_ic_regex(chem_name,"^(date|time)$")   
chem_name(ind_out) = ""
; now find all locations still containing information, and keep only those
ind_in = str_match_ind_ic_regex(chem_name,"([:alnum:])+")
chem_name := chem_name(ind_in)

; count remaining variables we're working on
MChem   = dimsizes(chem_name)

; check that this is the correct number of variables for this script
if(MChem .ne. 1) 
	print("This script is set up for running with 1 variables. Change it to deal with "+MChem+" variable instead")
	exit()
end if


;;;;;;;;;; pull out the measurement information
; load data files
fil_data = addfile(MeasDir+"nh3nn_v2_2_"+Data_Time_Stamp+".nc","r")

; extract data
MeasLat = fil_data->latitude
MeasLon = fil_data->longitude
;  date needs calculating from Date_Time_Stamp..... MeasDate = fil_data->Date              ; YYYYMMDD
MeasTime_in = fil_data->time              ; HHMMSS.ms   



; correct data, so we have sensible NaN's
data_nan_correct(MeasLat,NaN)
data_nan_correct(MeasLon,NaN)
;data_nan_correct(MeasDate,NaN)
;data_nan_correct(MeasTime,NaN)

;; record the positions of missing location information in measurements
Pos_missing_Lat = ind(ismissing(MeasLat(:)))
Pos_missing_Lon = ind(ismissing(MeasLon(:)))
Pos_missing := array_append_record(Pos_missing_Lat,Pos_missing_Lon,0)
Pos_missing := get_unique_values(Pos_missing)

;; if no missing datapoints, set Pos_missing = -1 (otherwise the NaN value will crash code below)
if(ismissing(Pos_missing))
	Pos_missing := -1
end if

; close data files
delete(fil_data)

; grab dimension information
Meas_Sizes = dimsizes(MeasLat)
MDP     = Meas_Sizes(0)


;;; convert the measured times to format: hours after start of the day 
MeasTime = toint(MeasTime_in)
MeasTime := sprinti("%6.6i",MeasTime)
MeasTimeStamp = tochar(MeasTime)
MeasHour   = tofloat(tostring(MeasTimeStamp(:,0:1)))
MeasMinute = tofloat(tostring(MeasTimeStamp(:,2:3)))
MeasSecond = tofloat(tostring(MeasTimeStamp(:,4:5)))
MeasTimeOfDay = MeasHour + (MeasMinute/60.0) + (MeasSecond/(60.0*60.0))


;;; convert the measured dates to format: hours since 1800-01-01 00:00:00
MeasDateStamp := tochar(Data_Time_Stamp)
MeasDate := tostring(MeasDateStamp(0:7))   ;;; these two lines cut off the _AM / _PM from the end of the string
MeasYear = tostring(MeasDateStamp(0:3))
MeasMonth= tostring(MeasDateStamp(4:5))
MeasDay  = tostring(MeasDateStamp(6:7)) ;;; these three lines will be used for wrfout* file selection
MeasDate := cd_inv_string(MeasDate,"%Y%N%D")
MeasDate := MeasDate + MeasTimeOfDay


;;; write the time and date information to the output file
file_chem->time  = (/MeasTime_in/)
file_chem->date  = (/MeasDate/) 




print("== loading model data ==")
; list the input files, and open them
file_list := systemfunc("ls -1 "+ModelDir+"wrfout_d01_"+MeasYear+"-"+MeasMonth+"-"+MeasDay+"*")
FILES = addfiles(file_list,"r")


; load model dates, and convert to format: hours since 1800-01-01 00:00:00
Model_Dates = wrf_user_getvar(FILES,"times",-1)
Model_N = dimsizes(Model_Dates)
Model_Dates := cd_inv_string(Model_Dates,"%Y-%N-%D_%H:%M:%S")



; load model positional data
Model_Lat = wrf_user_getvar(FILES,"lat",0)
Model_Lon = wrf_user_getvar(FILES,"lon",0)

;;; set up model data array for storing extracted data (single array, so we can loop through the list of variables)
Model_Data = new((/MDP,MChem/),double,-9999)
Model_Data@missing_value   = Model_Data@_FillValue


;;; pointer arrays for model data
xx_array = new(MDP,integer,-9999)
yy_array = new(MDP,integer,-9999)
tt_array = new(MDP,integer,-9999)

print("== getting positional information from measurement data ==")

;;; get point data positions on model domain
locations =	wrf_user_ll_to_ij(FILES[0],MeasLon,MeasLat,POS_SET)
;; convert to ncl indexes
locations = locations - 1


;;; get dimensions of model domain
vardims = dimsizes(Model_Lat)


;;; ensure that we only plot data inside model domain
;yy_array = where(locations(0,:).ge.0.and.locations(0,:).lt.vardims(0)\
;						.and. locations(1,:).ge.0.and.locations(1,:).lt.vardims(1),\
;						locations(0,:),-9999)
yy_array = where(locations(1,:).ge.0.and.locations(1,:).lt.vardims(0)\
						.and. locations(0,:).ge.0.and.locations(0,:).lt.vardims(1),\
						locations(1,:),-9999)
xx_array = where(.not.ismissing(yy_array),locations(0,:),-9999)


;; get index of points inside model domain
ind_data = ind(.not. ismissing(xx_array))



print("=== looping through hours list ===")


;;; loop through Measurement Data
;do idata=0,MDP-1
do idata=0,dimsizes(ind_data)-1

	; check to make sure we've got measurement data - if not jump to next datapoint
	if( any(Pos_missing.eq.ind_data(idata)) .or. ismissing(xx_array(ind_data(idata))) )
		continue
	end if

	; round to the nearest hour, and see if it matches any time in the model data - if not jump to next datapoint
	meas_hour = round(MeasDate(ind_data(idata)),0)
	if( .not. any(Model_Dates.eq.meas_hour))
		continue
	else
		tt_array(ind_data(idata)) = ind(Model_Dates.eq.meas_hour)
	end if
	
end do 



if(any(.not. ismissing(tt_array)))
	print(min(tt_array))
	print(max(tt_array))
else
	print("no model times matches measurements")
	exit()
end if



;; extract the model data (for all times)
print("      loading model data")
mdata_00 := (/load_variable_2D(FILES,chem_name(0)+"_column")/)

print("      looping through flight datapoints")


; loop through the data points in each profile
;do kpoint=0,MDP-1 ;N_not_missing-1
do kpoint=0,dimsizes(ind_data)-1 ;N_not_missing-1

	xx = xx_array(ind_data(kpoint)) 
	yy = yy_array(ind_data(kpoint))
	tt = tt_array(ind_data(kpoint))

	;; pull required data from the location on the 2D dataset
	Model_Data(ind_data(kpoint),0)  = (/mdata_00(tt,yy,xx)/)

end do



print(getvardims(Model_Data))



;;;;;; writing file section ;;;;;;;;;;;;;;;;;;;;;

print("   writing model data")

; loop through variables, defining them in the output file, then writing them out
do jchem=0,MChem-1

	; pull out the data array from the storage file (creating our temporary array)
	MDTemp = file_chem->$chem_name(jchem)$
	
	; Data is organised thus: MDTemp = new((/MFlight,MDP/),double,-9999)

	; copy data for our flight of interest to temporary data array
	MDTemp(:) = (/Model_Data(:,jchem)/)

	; copy the data back into the storage file
	file_chem->$chem_name(jchem)$  = (/MDTemp/)

end do

;;;;;; end of writing file section ;;;;;;;;;;;;;;;; 




print("successful completion of program")

end
