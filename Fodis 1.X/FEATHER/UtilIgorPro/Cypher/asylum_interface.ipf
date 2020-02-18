// Use modern global access method, strict compilation
#pragma rtGlobals=3	

#pragma ModuleName = ModAsylumInterface
#include "::Util:IoUtil"
#include "::Util:PlotUtil"
#include ":ForceModifications"
#include ":OfflineAsylum"


Static Function /Wave get_force_review_wave(type,[return_x,suffix])
	// Gets the just-saved Wave, assuming it is displayed on the force review graph
	//
	// Args:
	//	type: the extension we want to use (e.g. 'ZSnsr_Ext')
	//	return_x: if true, return the *x* wave reference, instead of the y wave
	//	suffix: the suffix to look for. defaults to the last saved plot
	//
	// Returns: 
	//	reference to the last-saved wave (assuming it is plotted in the ForceReviewGraph)
	String type
	Variable return_x,suffix
	if (ParamIsDefault(suffix))
		suffix = ModOfflineAsylum#current_image_suffix()-1
	endif
	String base_name = ModOfflineAsylum#master_base_name()
	String trace_name = ModOfflineAsylum#formatted_wave_name(base_name,suffix,type=type)
	// set the current graph to the force review panel
	String review_name = ModOfflineAsylum#force_review_graph_name()	
	// get the note of DeflV on the force review graph
	if (return_x)
		Wave to_ret = ModPlotUtil#graph_wave_x(review_name,trace_name)
	else
		Wave to_ret = ModPlotUtil#graph_wave(review_name,trace_name)		
	endif
	return to_ret
End Function



Static Function save_to_disk_volts(zsnsr_volts_wave,defl_volts_wave,[note_to_use])
	// Saves the given waves (all in volts) to disk (in meters)
	// Args:
	// 	See: save_to_disk
	// Returns: 
	//	nothing
	Wave zsnsr_volts_wave,defl_volts_wave
	String note_to_use
	if (ParamIsDefault(note_to_use))
		note_to_use = Note(defl_volts_wave)
	endif
	Make /O/N=0 defl_meters,z_meters
	Variable z_lvdt_sensitivity = GV("ZLVDTSens")
	Variable invols = (GV("Invols"))
	volts_to_meters(zsnsr_volts_wave,defl_volts_wave,z_lvdt_sensitivity,invols,z_meters,defl_meters)
	// save the zsnsr and defl to the disk
	save_to_disk(z_meters,defl_meters,note_to_use)
	KillWaves /Z defl_meters,z_meters
End Function

Static Function save_to_disk(zsnsr_wave,defl_wave,note_to_use)
	// Saves the given ZSnsr and deflection to disk
	//
	// Args:
	//	zsnsr_wave: Assumed ends with "ZSnsr", the Z Sensor in meters
	//	defl_wave: the deflection in meters
	// 	note_to_use: the (optional) note to save with. defaults to just defl_wave
	// Returns
	//	Nothing
	Wave zsnsr_wave,defl_wave
	String note_to_use
	Variable save_to_disk = 0x2;
	Duplicate /O zsnsr_wave,raw_wave
	// For ARSaveAsForce... (modelled after DE_SaveFC, 2017-6-5)
	// Args:
	//	1: 0x10 means 'save to disk, not memory'
	//	2: "SaveForce" is the symbolis path name 
	//	3: what we are saving (in addition to ZSnsr, or 'raw', which is required)
	//	4,5 : the actual waves
	//	6-10: empty waves (not saving)
	//	11: CustomNote: the note we are using toe save eveything
	ModForceModifications#prh_ARSaveAsForce(save_to_disk,"SaveForce","ZSnsr;Defl",raw_wave,zsnsr_wave,defl_wave,$"",$"",$"",$"",CustomNote=note_to_use)
	// Clean up the wave we just made
	KillWaves /Z raw_wave
End Function


Static Function assert_infastb_correct([input_needed,msg_on_fail])
	// asserts that infastb on the cross point panel matches the needed input
	//
	// Args:
	//	input_needed: string (ADC name) we wand connected to infastb. Default: "Defl"
	//	msg_on_fail: what to do if we fail
	// Returns:
	//	Nothing, throws an error if things go wrong
	String input_needed,msg_on_fail
	String in_fast_a = ModAsylumInterface#get_InFastA() 
	// Determine the faillure method based on what we want to connect	
	if (ParamIsDefault(input_needed))
		input_needed = "Defl"
	endif
	if (ParamIsDefault(msg_on_fail))
		msg_on_fail = "InFastB must be connected to " + input_needed + ", not " + in_fast_a
	EndIf		
	Variable correct_input = ModIoUtil#strings_equal(in_fast_a,input_needed)
	ModErrorUtil#assert(correct_input,msg=msg_on_fail)	
End Function

Static Function /S get_InFastA()
	// Returns: 
	//	the name of the ADC connected to InFastA
	String crosspoint_panel = "CrosspointPanel"
	ModErrorUtil#assert(ModPlotUtil#window_exists(crosspoint_panel),msg="Crosspoint panel doesn't exist")
	ControlInfo /W=$(crosspoint_panel) CypherInFastBPopup
	// S_Value is 'set to text of the current item'
	return S_Value
End Function