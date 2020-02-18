// Use modern global access method, strict compilation
#pragma rtGlobals=3	

#pragma ModuleName = ModFunctionEditor
#include ":::Util:ErrorUtil"
#include ":::Util:PlotUtil"

// Note: at present, this function assumes all values are given as nanometers, as 
// described in setup_for_new_indenter. 

Static Function /S editor_base()
	// Returns: where the indenter lives
	return "root:packages:MFP3D:FunctionEditor:Indenter:"
End Function

Static Function /S variable_wave_name()
	// Returns: the path to the variable wave (need this to,
	// for example, set the velocities)
	return  editor_base() + "FEVariablesWave"
End function

Static Function /S function_editor_window()
	// Returns: the name of the indenter graph
	return  "FEGraphIndenter"
End Function 

Static Function set_indenter_variable(name,value)
	// Sets an indenter variable (by name) to the given value
	//
	// Args:
	//	name: of the variable, see UserProgramming.ipf
	//	 value: what to set it to. right now, this is in units of whatever is already there...
	String name
	Variable value
	Struct WMSetVariableAction setvar_struct
	// These are the codes needed by ARFESetVarFunc; mouse up or enter?
	setvar_struct.EventCode = 2
	setvar_struct.EventCode = 1
	String VName = variable_wave_name() + "[%" + name + "][%Value]"
	setvar_struct.VName = VName
	setvar_struct.sVal = num2str(value)
	setvar_struct.dval = value
	setvar_struct.Win = function_editor_window()
	// POST: window exists, should be OK
	Wave setvar_struct.svWave = $(variable_wave_name())
	ARFESetVarFunc(setvar_struct)
End Function

Static Function /S segment_start_position()
	// Returns: The control name for the function editor's "Start" field
	return "SegmentStartPos"
End Function

Static Function /S segment_end_position()
	// Returns: The control name for the function editor's "End" field
	return "SegmentEndPos"
End Function 

Static Function /S segment_velocity()
	// Returns: the control name for  the function editor's  "Velocity" field
	return "SegmentVelocity"
End Function 

Static Function make_segment(start_loc,end_loc,time_delta,velocity)
	// Makes an indenter segment in the GUI
	//
	// Args:
	//	<start/end>_loc: the z value needed for the beginning and end of the segment
	// 	time_delta: thelength of the segment
	// 	velocity: the velocity of the segment 
	// Returns:
	//	nothing
	Variable start_loc,end_loc,time_delta,velocity
	set_indenter_variable(segment_start_position(),start_loc)
	set_indenter_variable(segment_end_position(),end_loc)
	set_indenter_variable(segment_velocity(),velocity)
      set_indenter_variable("SegmentLength",time_delta)	
End Function 

Static Function make_segment_equilibrium(location,time_delta)
	// Makes the currently-selected segment an equilibrium segment 
	// at a certain Z with a given time
	//
	// Args:
	//	location: the z value needed
	// 	time_delta: thelength of the segment
	// Returns:
	//	nothing
	Variable location,time_delta
	// velocity is zero (not moving)
	make_segment(location,location,time_delta,0)
End Function

Static Function new_segment()
	// Creates a new segment on the function editor panel 
	ARFEInsertFunc(indenter_handle(),1,nan)
End Function 

Static Function /S indenter_handle()
	// Returns: the 'handle' for the indenter
	// (used by some asylum functions)
	return "Indenter"
End Function

Static Function delete_existing_indenter()
	// Deletes the existing waves on the indenter
	// (technically, it doesn't the delete the last segment, 
	// because there always has to be one left)
	Wave /Z wave_ref = $(variable_wave_name())
	ModErrorUtil#assert_wave_exists(wave_ref,msg="Check that indenter panel and function editor are open.")
	String handle = indenter_handle()
	// keep deleting segments while they are a thing
	// XXX make into for loop?
	do
		Variable A, NumKilled, NumOfSegs = wave_ref[%NumOfSegments][%Value]
		ARFEDeleteFunc(handle,NumOfSegs)	
	while (NumOfSegs > 1)
End Function


Static Function setup_for_new_indenter([units])
	// Deletes all previous indenter information, setting up the function
	// editor for a new one
	//
	// Args:
	//	units: the units everything should be in. defaults to nm
	// Returns:
	// 	nothing 
	Variable units
	// by default, assume nanometers. 
	units = ParamIsDefault(units) ? 1e-9 : units
	delete_existing_indenter()
	// POST: all old indenter steps are gone. 
	// Make all the units into the proper units
	Make /FREE/T tmp_txt = {segment_start_position(),segment_end_position(),segment_velocity()}
	Variable n = DimSize(tmp_txt,0)
	Variable i 
	for (i=0; i < n; i+=1)
		FEPutValue(indenter_handle(),tmp_txt[i],"Value",units)
	EndFor	
End Function

Static Function setup_equilbirum_wave(locations,n_delta_per_location,time_delta)
	// sets up an equilibrium wave on the current indenter.
	//
	//	PRE: must have a current indenter	
	//
	// Args:
	//		locations: wave, size N, what the step heights are
	//		n_delta_per_location: how many 'time_delta' steps should be spent at each location
	//		time_delta: fundamental step unit
	// Returns:
	//		Nothing
	//
	Wave locations,n_delta_per_location
	Variable time_delta
	Variable n_times = DimSize(n_delta_per_location,0)
	ModErrorUtil#Assert(n_times > 0,msg="equilibrium needs at least one step")
	Variable total_deltas = sum(n_delta_per_location)
	// POST: waves exist
	// Make sure the window exists
	ModPlotUtil#assert_window_exists(function_editor_window())
	// POST: first segment is all that remains. 
	// set up its location and time
	Variable first = locations[0]
	Variable time_first = time_delta*n_delta_per_location[0]
	make_segment_equilibrium(first,time_first)
	// Finish up the rest (inserting as we go)
	Variable i 
	for (i=1;i<n_times; i+= 1)
		Variable location_tmp = locations[i]
		Variable time_tmp =  time_delta*n_delta_per_location[i]
		new_segment()
		make_segment_equilibrium(location_tmp,time_tmp)
	EndFor
End Function

Static Function staircase_equilibrium(start_x,delta_x,n_steps,time_dwell,[use_reverse])
	//  easy-of-use function; has <n_steps> 'plateaus', each of length time_dwell
	// starting at start_x and separated by delta_x
	//
	// Args:
	//	start_x: where to start, in x
	//	delta_x: how much to move each step 
	//	n_steps: how many steps there are
	//  	time_dwell: how long to dwell at each step (all the same)
	//	use_reverse: if true, also walks 'back' to the original point
	//
	// Returns:
	//	Nothing
	Variable start_x,delta_x,n_steps,time_dwell,use_reverse
	if (ParamIsDefault(use_reverse))
		use_reverse = 0
	EndIf
	ModErrorUtil#Assert(n_steps > 0,msg="equilibrium needs at least one step")
	Make /FREE/N=(n_steps) data_wave
	data_wave[] = start_x + p * delta_x
	If (use_reverse)
		// reversed will have one less point (so there 
		// are no duplicate points
		Make /FREE/N=(n_steps-1) reversed
		// copy the points such that we dont 
		// include the very last point
		// data_wave idx		reversed  idx
		// n_points - 2		0   (p=0)
		// n_points - 3		1   (p=1)
		//	...				...
		// 1					n-3  (p=n-3)
		// 0					n-2  (p=n-2)
		reversed[] = data_wave[n_steps-(p+2)]
		// combine the 'there and out' wave
		// /O: overwrite
		// /NP: no promotion (dont make a 2D wave)
		Concatenate /O /NP{data_wave,reversed}, data_wave
		// update the number of points
		n_steps = (DimSize(data_wave,0))
	EndIf
	// each location has exactly one time point 
	Make /FREE/N=(n_steps) n_time_deltas
	n_time_deltas[] = 1
	setup_equilbirum_wave(data_wave,n_time_deltas,time_dwell)
End Function

Static Function default_bidirectional_staircase([start_x,delta_x,n_steps,time_dwell])
	// Sets up a 'pretty good' bidirectional staircase, assuming
	// the indenter is open with units set to nm and nm/s
	//
	//	NOTE: this deletes any existing indenter set up
	//
	// Args:
	//	 see staircase_equilibrium
	// Returns:
	//	 nothing
	Variable start_x,delta_x,n_steps,time_dwell
	start_x = ParamIsDefault(start_x) ? -30 : start_x
	delta_x = ParamIsDefault(delta_x) ? -0.5 : delta_x
	n_steps = ParamIsDefault(n_steps) ? 50: n_steps
	time_dwell= ParamIsDefault(time_dwell) ? 75e-3 : time_dwell
	setup_for_new_indenter()
	staircase_equilibrium(start_x,delta_x,n_steps,time_dwell,use_reverse=1)
End Function

Static Function default_staircase([start_x,delta_x,n_steps,time_dwell])
	// Sets up a 1-directional staircase
	//
	//	NOTE: this deletes any existing indenter set up
	//
	// Args:
	//	 see default_bidirectional_staircase
	// Returns:
	//	 nothing
	Variable start_x,delta_x,n_steps,time_dwell
	start_x = ParamIsDefault(start_x) ? -65 : start_x
	delta_x = ParamIsDefault(delta_x) ? 1 : delta_x
	n_steps = ParamIsDefault(n_steps) ? 6: n_steps
	time_dwell= ParamIsDefault(time_dwell) ? 1 : time_dwell
	setup_for_new_indenter()
	staircase_equilibrium(start_x,delta_x,n_steps,time_dwell,use_reverse=0)
End Function

Static Function default_inverse_boltzmann()
	Variable start_boltzmann = -60
	// parameters for the initial point spread function region 
	Variable point_spread_initial_step_nm = -5
	Variable point_spread_dwell_s = 0.5
	Variable n_initial_steps = 4	
	Variable start_staircase = start_boltzmann + abs((n_initial_steps) * point_spread_initial_step_nm)
	Variable time_initial_s = 0.5
	Variable dwell_time_initial_s = 1
	Variable velocity_nm_per_s = abs(start_staircase/time_initial_s)
	setup_for_new_indenter()
	// make an effective dwell slightly into the surface, to avoid unit problems. 
	Variable global_zero = 1
	make_segment(global_zero,global_zero,dwell_time_initial_s,0)
	new_segment()	
	// Make a segment getting to the start of tthe first psf region 
	make_segment(global_zero,start_staircase,time_initial_s,velocity_nm_per_s)
	new_segment()
	// make the first psf region 
	staircase_equilibrium(start_staircase,point_spread_initial_step_nm,n_initial_steps,point_spread_dwell_s)
	new_segment()	
	// Make the boltzmann staircase...
	Variable step_boltz_nm = -0.33
	Variable n_steps_boltz = 20
	Variable dwell_boltz_s = 2
	staircase_equilibrium(start_boltzmann,step_boltz_nm,n_steps_boltz,dwell_boltz_s)
	// Make the second psf region
	Variable step_second_psf_region_nm = -5 
	Variable start_second_psf_region_nm = start_boltzmann + step_boltz_nm * (n_steps_boltz-1) + step_second_psf_region_nm
	Variable n_second_psf_region = n_initial_steps
	Variable dwell_second_psf_region_s = point_spread_dwell_s
	staircase_equilibrium(start_second_psf_region_nm,step_second_psf_region_nm,n_second_psf_region,dwell_second_psf_region_s)	
	Variable end_equil = start_second_psf_region_nm + step_second_psf_region_nm * (n_second_psf_region-1)
	// Make a new segment for the 'return to 0'
	new_segment()		
	make_segment(end_equil,global_zero,time_initial_s,velocity_nm_per_s)
End Function 

Static Function slow_refolding_experiment()
	refolding_experiment(velocity_nm_per_s=50,n_ramps=5,start_ramp_nm=-23,end_ramp_nm=-87)	
End Function

Static Function fishing_refolding_experiment()
	refolding_experiment(velocity_nm_per_s=500,n_ramps=1,start_ramp_nm=-23,end_ramp_nm=-87)	
End Function 

Static function refolding_experiment([velocity_nm_per_s,n_ramps,start_ramp_nm,end_ramp_nm])	
	Variable velocity_nm_per_s
	Variable start_ramp_nm
	Variable end_ramp_nm
	Variable n_ramps
	// initialize everrything
	velocity_nm_per_s = ParamIsDefault(velocity_nm_per_s) ? 50 : velocity_nm_per_s
	start_ramp_nm =  ParamIsDefault(start_ramp_nm) ? -50 : start_ramp_nm
	end_ramp_nm = ParamIsDefault(end_ramp_nm) ? -80 : end_ramp_nm
	n_ramps = ParamIsDefault(n_ramps) ? 5 : n_ramps
	Variable dwell_s = 1	
	setup_for_new_indenter()
	// Dwell into the surface
	Variable global_zero = 1
	make_segment(global_zero,global_zero,dwell_s,0)
	new_segment()		
	// Get to the first ramp 
	// Make a segment getting to the start of tthe first psf region 
	Variable time_initial_s = abs(global_zero - start_ramp_nm)/velocity_nm_per_s
	make_segment(global_zero,start_ramp_nm,time_initial_s,velocity_nm_per_s)
	new_segment()	
	// Make all the unfolding/refolding ramps 
	Variable i
	for (i=0; i< n_ramps; i+=1)
		Variable time_fold_and_unfold = abs(end_ramp_nm - start_ramp_nm)/velocity_nm_per_s
		make_segment(start_ramp_nm,end_ramp_nm,time_fold_and_unfold,velocity_nm_per_s)
		new_segment()		
		make_segment(end_ramp_nm,start_ramp_nm,time_fold_and_unfold,velocity_nm_per_s)
		new_segment()			
	EndFor
	// Make a 'back to zero' 
	make_segment(start_ramp_nm,global_zero,time_initial_s,velocity_nm_per_s)	
End Function