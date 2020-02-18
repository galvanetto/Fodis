// Use modern global access method, strict compilation
#pragma rtGlobals=3	

#pragma ModuleName = ModFastIndenter
#include ":NewFC"
#include "::ForceModifications"
#include ":::Util:IoUtil"
#include ":::Util:PlotUtil"
#include ":::Util:Numerical"
#include "::asylum_interface"

static constant DEF_NUMBER_OF_CALLS = 10
static constant max_info_chars = 100

Static Function default_timespan()
	// Returns:  the default time for the indenter capture
	return 20
End Function

// XXX TODO: for this to work properly, as of 2017-6-7:
// (1) Force Review must be open, and 'last' wave must be selected.
// (2) Defl must be plotted against ZSnsr 
// (3) As a note, the saving routine closes all open  files before it starts
// (4) 
// So, you shouldn't open any files, call this routine, then expect them to be opened

// XXX should select last element, Delf, and Zsnsr (that was it always saves out...)

structure indenter_info
	// Struct to use to communicate with the call back
	// <x/y_wave_high_res>: the string name of the high resolution wave
	char x_wave_high_res[max_info_chars] 
	char y_wave_high_res[max_info_chars] 
	// points_per_second: the frequency of data capture
	double points_per_second
EndStructure 

Static Function default_speed()
	// Returns: the default speed for the indenter capture
	return 0
End Function

Static Function /S default_wave_base_suffix()
	// Returns: the default fast-capture suffix for the indenter
	return "_fci_"
End Function

Static Function /S calls_remaining_path()
	// Returns: the path to the 'remaining' variable 
	return default_indenter_base() + "calls_remaining"
End Function

Static Function calls_remaining()
	// Returns:: the number of calls reamaining
	NVar to_ret = $calls_remaining_path()
	return to_ret
End Function

Static Function set_calls_remaining(value)
	// sets the nujmr of calls remaining
	// Args:
	//	value: to set the mber of calls. 
	// Returns
	//	nothing
	Variable value
	String path = calls_remaining_path()
	Variable /G $path = value
End Function

Static Function /S default_indenter_base()
	// Returns: the default location of the data base
	return "root:prh:fast_indenter:"
End Function

Static Function /S default_save_folder()
	// Returns: the default location to save the data
	return default_indenter_base() + "data:" 
End Function	

Static Function setup_directory_sturcture()
	// This function ensures the indenter directory structure is set up
	// /O: OK if doesn't already exist, don't overwrite
	NewDataFolder /O root:prh
	NewDataFolder /O root:prh:fast_indenter
	NewDataFolder /O root:prh:fast_indenter:data
End Function

Static Function /S get_global_wave_loc()
	// Returns: the string location of the globally-saved wave
	return "root:prh:fast_indenter:info"
End Function

Static Function save_info_struct(ind_inf)
	// Saves out the information structure (overwriting anything pre-exising one)
	// Args:
	//	ind_inf: indenter_info struct reference to save
	// Returns:
	//	Nothing
	struct indenter_info & ind_inf
	String wave_name =  get_global_wave_loc()
	Make /O/N=0 $(wave_name)
	StructPut /B=3 ind_inf $(wave_name)
End Function

Static Function get_info_struct(ind_inf)
	// Reads the existing information structure 
	//
	// Args:
	//	ind_inf: indenter_info struct reference to read into
	// Returns:
	//	Nothing
	struct indenter_info & ind_inf
	StructGet /B=3 ind_inf $(get_global_wave_loc())
End Function


Static Function select_index(select_wave,index)
	// Selects a given index at a wave
	// From igor manual:
	// 	Bit 0 (0x01):	Cell is selected.
	//
	// Args:
	//	select_wave: which wave to use 
	// 	index: what index to select
	// Returns:
	//	nothing
	Wave select_wave
	Variable index
	// For listbox in mode 4 (multiple selections possible),
	// SelWave bits have different meanings: 
	//Bit 0 (0x01):	Cell is selected.
	// ...
	///Bit 3 (0x08):	Current shift selection.
	//Bit 4 (0x10):	Current state of a checkbox cell.
	//Bit 5 (0x20):	Cell is a checkbox.
	
	// 0x9 should be enough for non-checkboxes
	variable bit_or =  0x9
	// 0x20 means we are a check box, 0x10 is the checked status  
	if (select_wave[index][0][0]  & 0x20)
		bit_or = bit_or |  0x10
	endIf
	select_wave[index][0][0] = select_wave[index][0][0] | bit_or
End Function

Static Function setup_gui_for_fast_capture()
	// fast capture relies on having the Force Review graph open and accessible. This 
	// function ensures that those conditions are met
	//
	// Args: 
	//	None
	// Returns:
	// 	None, but thows errors if problem (e.g. Force Review isn't open)
	String force_review = ModAsylumInterface#force_review_graph_name()
	String master_force_name = "MasterForcePanel"
	ModErrorUtil#Assert(ModIoUtil#WindowExists(master_force_name),msg="Must have Review panel open")
	// POST: force review panel exists
	String y_axis_selector = "ForceAxesList0_0"
	ControlInfo /W=$(master_force_name) $(y_axis_selector)
	String list_wave_path = S_DataFolder + S_Value
	Wave list_wave = $(list_wave_path)
	Variable defl_exists = ModDataStructures#text_in_wave("Defl",list_wave)
	ModErrorUtil#assert(defl_exists,msg="Couldn't find Defl in Force Review Options")
	// POST: defl exists, get its index
	Variable defl_idx = ModDataStructures#element_index("Defl",list_wave)
	// Call the swapping procedure 
	Variable valid_event = 1
	Variable col = 0 
	Wave selector_wave_y_axis = $("root:ForceCurves:Parameters:AxesListBuddy0") 
	ModErrorUtil#assert_wave_exists(selector_wave_y_axis)
	select_index(selector_wave_y_axis,defl_idx)
	HotSwapForceData(y_axis_selector,defl_idx,col,valid_event)
	// Ensure that ZSnsr is selected as the x
	String x_axis_selector = "ForceXaxisPop_0"
	PopupMenu $(x_axis_selector) mode=5,popvalue="ZSnsr", win=$(master_force_name) 
	ChangeForceXAxis(x_axis_selector,5,"ZSnsr")
	// Ensure that the most revent force wave is selected 
	Struct WMListBoxAction InfoStruct	
	Wave /T InfoStruct.listWave=$("root:ForceCurves:Parameters:SlaveFPList")
	InfoStruct.Row = DimSize(InfoStruct.listWave,0)-1
	Wave InfoStruct.selWave=$("root:ForceCurves:Parameters:SlaveFPBuddy")
	Wave InfoStruct.colorWave=$("root:packages:MFP3D:TOC:ListColorWave")
	InfoStruct.CtrlName = ModAsylumInterface#force_review_list_control_name()
	InfoStruct.Win = master_force_name
	// these two are chosen to run properly in SelectFPByFolderProc
	InfoStruct.EventCode = 2
	InfoStruct.CtrlRect.Left = 14
	// EventMod is if there was a shift or control (we are 'faking' an event)	
	InfoStruct.EventMod = 0
	// Make sure the waves we need exist
	ModErrorUtil#assert_wave_exists(InfoStruct.listWave)
	ModErrorUtil#assert_wave_exists(InfoStruct.selWave)
	ModErrorUtil#assert_wave_exists(InfoStruct.colorWave)
	// POST: all the waves exist, save to set . 
	select_index(InfoStruct.selWave,InfoStruct.Row)
	SelectFPByFolderProc(InfoStruct)
End Function

Function prh_indenter_final()
	// Call the 'normal' asylum callback, then saves out the normal data
	// Args/Returns: None
	TriggerScale()
	// POST: data is saved into the waves we want
	align_and_save_fast_capture()
End Function

Static Function align_and_save_fast_capture()
	// Assuming that fast capture data has been taken, aligns it to the 
	// low resolution data and saves it as a 'normal' asylum wave 
	//
	// PRE: capture_indenter has been called, and the global indenter_info
	// struct has been saved out 
	//
	// Args:
	//	None
	// Returns:
	//	None
	// get the previously-setup information by reference
	struct indenter_info indenter_info
	get_info_struct(indenter_info)
	// align by the structure
	align_and_save_struct(indenter_info)
End Function
	
Static Function align_and_save_struct(indenter_info,[suffix_low_res])
	// Align and save, given a structure and suffix for the low resolution data
	// useful for (e.g.) saving an in-memory wave later on
	//
	// Args:
	//	indenter_info:  see arugment to get_info_struct
	//	suffix_low_res: Asylum-style number suffix (e.g. 0111 in Image0111)
	// Returns
	//	Nothing, saves out the wave
	struct indenter_info & indenter_info
	Variable suffix_low_res
	Variable suffix =  ModAsylumInterface#get_wave_suffix_number(indenter_info.x_wave_high_res)
	// low resolution is always saved first (the whole point of the callbacks)
	// so its suffix is assumed one lower
	if (ParamIsDefault(suffix_low_res))
		suffix_low_res = suffix-1
	EndIf
	// get the *x* waves (used to align the high resolution to the low
	Wave low_res_approach = ModAsylumInterface#get_force_review_wave("Defl_Ext",return_x=1,suffix=suffix_low_res)	
	Wave low_res_dwell = ModAsylumInterface#get_force_review_wave("Defl_Towd",return_x=1,suffix=suffix_low_res)	
	// align waves by maximum in (hopefully less noisy) z sensor
	String msg_z = "Must display Defl vs ZSnsr on Force Review for high resolution data to function properly"
	String low_res_approach_x_name = NameOfWave(low_res_approach)
	String high_res_approach_x_name = NameOfWave(low_res_approach)
	ModErrorUtil#Assert(ModIoUtil#substring_exists("ZSnsr",low_res_approach_x_name,insensitive=1),msg=msg_z)
	ModErrorUtil#Assert(ModIoUtil#substring_exists("ZSnsr",high_res_approach_x_name,insensitive=1),msg=msg_z)	
	// POST: using Defl, ZSnsr
	String low_res_note = note(low_res_approach)
	// Concatenate the low resolution approach and retract
	Make/FREE/N=0 low_res_approach_and_dwell
	// /NP: no promotion allowed
	Concatenate /NP {low_res_approach,low_res_dwell}, low_res_approach_and_dwell
	// Make sure we are still correctly connected after the force input (it changes the cross point)
	ModAsylumInterface#assert_infastb_correct()
	// Add the note to the higher-res waves
	Wave zsnsr_wave = $(indenter_info.x_wave_high_res)
	Wave defl_wave = $(indenter_info.y_wave_high_res)
	// update the frequency (all other information is the same)
	Variable freq = indenter_info.points_per_second
	Variable n = DimSize(defl_wave,0)
	// Before we do *anything* else, get the low resolution sampling rate
	// (this allows us to determine the indices to split the wave later )
	Variable freq_low = ModAsylumInterface#note_variable(low_res_note,"NumPtsPerSec")
	// update the triggering parameters
	low_res_note = ModAsylumInterface#update_note_triggering(low_res_note,low_res_approach_and_dwell,zsnsr_wave,freq_low,freq)
	// update the resolution variables 
	low_res_note = ModAsylumInterface#update_note_resolution(low_res_note,freq,n)
	// everything is set up; go ahead and set the notes 
	Note zsnsr_wave, low_res_note
	Note defl_wave, low_res_note
	// XXX delete the high resolution wave (in memory only)?
	// TODO: once software is safer, probably OK to save only to disk. Right
	// now, too volatile
	// Close all open files; useful in case of errors
	Close /A
	// save out the high resolution wave to *disk*	
	ModAsylumInterface#save_to_disk_volts(zsnsr_wave,defl_wave,note_to_use=low_res_note)	
	Variable n_calls = calls_remaining()
	set_calls_remaining(n_calls - 1)	
	if (n_calls-1 > 0)
		run_single()
	EndIf
End Function

Function prh_indenter_callback(ctrl_name)
	// callback which immediately calls the asylum callback, then forwards to the custom routine
	//
	// Note: callbacks __must__ not be static, otherwise we get an error
	//
	// Args:
	//	ctrl_name: see FinishForceFunc
	// Returns: 
	//	nothing
	String ctrl_name
	// Immediately call the 'normal' Asylum trigger
	prh_FinishForceFunc(ctrl_name,callback_string="prh_indenter_final()")

End Function

Static Function capture_indenter()
	// PRE: setup_indenter has been called
	// Calls Fast Capture and then sets up a single force curve
	//
	// Args/Returns: nothing 
	ModFastCapture#fast_capture_start()
	// Call the single force curve (using modified function from ForceModifications)
	ModForceModifications#prh_DoForceFunc("Single",non_ramp_callback="prh_indenter_callback")
End Function 

Static function setup_indenter([speed,timespan,zsnsr_wave,defl_wave])
	//	Starts the fast capture routine using the indenter panel, 
	//	accounting for the parameters and notes appropriately.
	//
	//	PRE: Defl must be connected to InFastB
	//Args:
	//		see ModFastIndenter#fast_capture_setup
	// Returns
	//		result of ModFastIndenter#fast_capture_setup
	Variable speed,timespan
	Wave zsnsr_wave,defl_wave
	// determine what the actual values of the parameters are
	speed = ParamIsDefault(speed) ? default_speed() : speed
	timespan=ParamIsDefault(timespan) ? default_timespan() : timespan
	// Determine the output wave names...
	String default_base = (ModAsylumInterface#default_wave_base_name() + default_wave_base_suffix())
	// Make sure the output folder exists
	String default_save = default_save_folder()
	setup_directory_sturcture()	
	// POST: data folder exists, get the output path
	String default_base_path = default_save + default_base
	String default_y_path = default_base_path + "Deflv"
	String default_x_path = default_base_path + "ZSnsr"
	if (ParamIsDefault(defl_wave))
		Make /O/N=0 $default_y_path
		Wave defl_wave = $(default_y_path)
	endif
	if (ParamIsDefault(zsnsr_wave))
		Make /O/N=0 $default_x_path
		Wave zsnsr_wave = $(default_x_path)
	endif
	// POST: all parameters set. Save out the structure info
	struct indenter_info inf_tmp
	inf_tmp.x_wave_high_res = ModIoUtil#GetPathToWave(zsnsr_wave)
	inf_tmp.y_wave_high_res = ModIoUtil#GetPathToWave(defl_wave)
	inf_tmp.points_per_second = ModFastCapture#speed_option_to_frequency_in_Hz(speed)
	save_info_struct(inf_tmp)
	// before anything else, make sure the review exists
	String review_name = ModAsylumInterface#force_review_graph_name()
	ModPlotUtil#assert_window_exists(review_name)
	// POST: review exists, set up the gui (e.g. pick Defl and ZSnsr as what
	// to display)
	setup_gui_for_fast_capture()
	// POST: review window exists. Make sure that defl is set up for InFastB
	ModAsylumInterface#assert_infastb_correct()
	// Zero the photo diode before each pull
	ZeroPD()
	// POST: inputs are correct, set up the fast capture
	Variable to_ret = ModFastCapture#fast_capture_setup(speed,timespan,defl_wave,zsnsr_wave)
	return to_ret
End Function

Static Function Main()
	// Runs the capture_indenter function with all defaults
	run_number_of_calls()
End Function

Static Function run_number_of_calls([number_of_calls])
	// captures number of serial high resoution curves
	//
	// Args:
	//	number_of_calls: how many serial force-extension curves to take
	// Returns:
	// 	nothing
	Variable number_of_calls
	number_of_calls = ParamIsDefault(number_of_calls) ? DEF_NUMBER_OF_CALLS : number_of_calls
	set_calls_remaining(number_of_calls)
	run_single()
End Function

Static Function run_single()
	// Runs a 'single' force extension curve, but 
	// executes another one if calls_remaining > 1 
	// before this is called
	// Args/Returns: 
	//	none 
	setup_indenter()
	capture_indenter()
End Function