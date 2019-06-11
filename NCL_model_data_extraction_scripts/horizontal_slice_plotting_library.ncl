;
; library file for the scripts which deal with horizontal plotting of model data.
;
;  
;
;
;

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_inv_string.ncl"

;load "../../library/variable_loading_library.ncl"
;load "/nerc/n02/n02/lowe/Clearflo_data_analysis/working_space/git_scripts/WRFChem-Basic-Plotting/library/variable_loading_library.ncl"

begin

;;;;;;; Setting up the logical variables which we will use to carry 
;;;;;;;   attributes controlling the variable setups
;; used for carrying colour scale information, e.g.:
;;   colour_levels@no2       = (/0.1,0.2,0.5,1.0,2.0,5.0,10.0,20.0,50.0,100.0,200.0,500.0/) 
colour_levels = True

;; used for carrying information about changing variable units, e.g.:
;;     variable_units@T2  = (/"K","C"/)
variable_units = True

;; used for carrying the variable descriptions
variable_description = True


N_A = 6.02214e23    ; avogadro's number mol^-1
R = 8.3144621       ; gas constant J/molK



;
;   Function for correcting the MissingValue information in SAMBBA measurement data
;

undef("data_nan_correct")
procedure data_nan_correct(var:numeric,nan_replace:numeric)
begin

replace_ieeenan(var,nan_replace,0)

var@_FillValue    = nan_replace
var@missing_value = nan_replace

end


;-------------------------------------------------------------------
;     Convert from ppm to molecules cm^-3
; !!! WARNING - Must have pressure in Pa !!!

undef("ppm_moleconc_conv")
function ppm_moleconc_conv(p:numeric, Temp:numeric)	; pressure [Pa], temperature [K]
begin

	if (p@units .eq. "Pa")
		 ppm_conv_fac = 1e-12*N_A*p/(Temp*R)
	else if (p@units .eq. "hPa")
		 ppm_conv_fac = 1e-10*N_A*p/(Temp*R)
	else
		print("ppm_conv: must have pressure in units Pa or hPa")
	end if
	end if		

	 return(ppm_conv_fac)

end



;-------------------------------------------------------------------;
; get_grid_thickness	-	return the vertical thickness(del_z) of grid cells (in m)
; SAN - 19/02/14 - Reframed to be calculated explicitly from geopotential at grid 
; boundaries (unstaggered)

; Height = full geopotential / 9.81

undef("get_grid_thickness")
function get_grid_thickness(PH:numeric, PHB:numeric, height:numeric)
local z_stag, del_z, dims, nk, iz
begin

	; calculate the height at the staggered grid boundaries
	z_stag = (PH + PHB)/9.81

	; get dimension sizes of the domain
	dims = dimsizes(height)

	; create array for model thickness same size/type as the unstaggered height array
	del_z = new(dims,typeof(height))
	
	
	; check if the variable has 3 or 4 dimensions (i.e. does it have a time dimension or not)
	if(dimsizes(dims).eq.4)
		nk = dims(1)

		; loop through the vertical, calculating thickness at each level:
		do iz = 0, nk-1
			del_z(:, iz, :, :) = z_stag(:, iz+1, :, :) - z_stag(:, iz, :, :)
		end do
	
	else if (dimsizes(dims).eq.3)
		nk = dims(0)

		; loop through the vertical, calculating thickness at each level:
		do iz = 0, nk-1
			del_z(iz, :, :) = z_stag(iz+1, :, :) - z_stag(iz, :, :)
		end do

	end if
	end if
	

	del_z@units = "m"
	del_z@description = "Grid Thickness"

    return(del_z)

end


;
;  Function for calculating column densities
;

undef("column_data_calculation")
function column_data_calculation(FILES:list,var:string)
local var_name, PH, PHB, height, grid_thickness, pres, tk, ppm_conv, var_temp, dims, var_temp_a
begin
		; pull out the variable name
		var_name = str_sub_str(var, "_column","" )


		; checks for data type, and then extract variable data
		if(isStrSubset(var_name,"_a0") .or. isStrSubset(var_name,"_cw0") .or. \
			isStrSubset(var_name,"_A0") .or. isStrSubset(var_name,"_CW0") .or. \
			isStrSubset(var_name,"_fine") .or. isStrSubset(var_name,"_coarse") .or. \
			isStrSubset(var_name,"_pm1") .or. isStrSubset(var_name,"_pm25") .or. isStrSubset(var_name,"_tot") )
		
			print("column calculation not set up for aerosol species yet, so can't process "+var)
			exit

		else
			var_temp = wrf_user_getvar(FILES,var_name,-1)
			
			if(isatt(var_temp,"units"))
				if(.not.isStrSubset(var_temp@units,"ppm") .and. .not.isStrSubset(var_temp@units,"PPM"))
					print("column calculation requires input with units of ppmv, not "+var_temp@units)
					print("  you will need to modify the code in variable_loading_library to process "+var_name)
					exit
				end if
			else
				print("no units information for "+var_name+" - column calculation requires ppmv, ")
				print("   so we will assume this is what the units are, but please check to make sure this is right!")
			end if
			
		end if

		; pull out pressure height information, and calculate grid level thickness (in m)
		PH = wrf_user_getvar(FILES,"PH",-1)
		PHB = wrf_user_getvar(FILES,"PHB",-1)
		height = wrf_user_getvar(FILES,"height",-1)
		grid_thickness = get_grid_thickness(PH,PHB,height)


		; convert from ppm to molecules / cm3
		pres = wrf_user_getvar(FILES,"pres",-1)
		tk   = wrf_user_getvar(FILES,"tk",-1)
		ppm_conv  = ppm_moleconc_conv(pres, tk)
		var_temp = var_temp * ppm_conv

		; calculate molecules / cm2 / column for each grid cell (with conversion from m to cm for grid thickness)
		var_temp = var_temp * grid_thickness * 100.
		
		; sum molecules / cm2 for all columns
		dims = dimsizes(var_temp)
		if(dimsizes(dims).eq.4)
			var_temp_a = dim_sum_n_Wrap(var_temp,1)	
		else if(dimsizes(dims).eq.3)
			var_temp_a = dim_sum_n_Wrap(var_temp,0)			
		end if
		end if
		var_temp_a@units = "molecules/cm2"

		return(var_temp_a)

end





undef("load_variable_2D")
function load_variable_2D(FILES:list,var:string)
local var_temp
begin


		
	;;; extract a 2D map of the column densities of the required species 
	var_temp = column_data_calculation(FILES,var)
	

	return(var_temp)


end







end ;; end of script
