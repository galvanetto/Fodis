// Use modern global access method, strict compilation
#pragma rtGlobals=3	

#pragma ModuleName = ModDataTagging
#include "::Util:IoUtil"
#include "::Util:PlotUtil"
#include "::Util:Numerical"
#include "::Util:ErrorUtil"
#include "::Cypher:OfflineAsylum"
#include "::Cypher:Util:ForceReview"


Macro DataTagging()
	ModDataTagging#Main()
End Macro

Static Function /S base_tagging_folder()
	return "root:prh:tagging:"
End Function

Static Function /S default_filtered_folder()
	// Returns: the folder where the filtered data lives. 
	return (base_tagging_folder() + "filtered:")
End Function

Static Function setup_tagging()
	// Sets up the file system for the tagging module
	NewDataFolder /O root:prh
	NewDataFolder /O root:prh:tagging
	NewDataFolder /O root:prh:tagging:filtered
End Function

Static Function filter_pct()
	Variable filter_pct = 2e-2
	return filter_pct 
End Function

Static Function /S get_output_path()
	// Using the global string variable (!) get the output path for the saved file
	// Returns:
	//		the output path for the file we want
	String my_file_name =ModIoUtil#current_experiment_name()
	SVAR base = prh_tagging_output_directory
	return base + my_file_name +"_events.txt"
End Function

Static Function delete_tmp_data(fig)
	// Deletes the temporary data from fig, as well as clearing out the
	// filtered data directory
	//
	// Args:
	//	fig: the figure to delete things from
	// Returns:
	//	nothing, deletes data from the graph and the storage directory
	String fig 
	String filtered_folder = default_filtered_folder()						
	String restore_folder = ModIoUtil#cwd()
	SetDataFolder $(filtered_folder)
	DFREF data_folder = GetDataFolderDFR()
	Variable i 
	do
		Wave /Z w = 	WaveRefIndexedDFR(data_folder,i)	
		if (!WaveExists(w))
			break
		EndIf
		// Remove the wave from the graph
		String trace_name = NameOfWave(w)
		if (ModPlotUtil#trace_on_graph(fig,trace_name))
			RemoveFromGraph /W=$(fig) $(trace_name) 
		EndIf
		i += 1
	while(1)
	KillWaves /A
	SetDataFolder $(restore_folder)
End Function

Function tagging_list_change_hook(InfoStruct)
	// 'Wrapper' function which deletes the data from the 
	// graph when the user changes the data they look at,
	//  then calls SelectFPByFolderProc. should only be used as a hook to
	// ForceReviewGraph, since it deletes data specifically to it
	//
	// NOTE: must not be static
	//
	// Args;
	//	see SelectFPByFolderProc
	// Returns:
	//	nothing
	Struct WMListBoxAction &InfoStruct
	// Delete the temporary data 
	delete_tmp_data(ModOfflineAsylum#force_review_graph_name())
	// Call the asylum function 
	SelectFPByFolderProc(InfoStruct)
End Function

Static Function update_filtered_data(fig)
	// updates the filtered data, on the named graph (prolly ForceReviewGraph)
	//
	// Args:
	//	fig: the figure to use
	// Returns:
	//	Nothing
	String fig
	String trace_list = ModPlotUtil#trace_list(fig)
	// Get the Number of elements in the trace list 
	String sep = ","
	Variable n = ItemsInList(trace_list,sep)
	if (n == 0)
		return(1)
	EndIf
	// POST: something on plot 
	String filtered_folder = default_filtered_folder()					
	String suffix = "_F"	
	String first = ModIoUtil#string_element(trace_list,0,sep=sep)
	if (!WaveExists($(filtered_folder + first + suffix)))
		delete_tmp_data(fig)
	else
		return(1)
	EndIf
	// POST: need to make all the waves
	Variable i
	For (i=0; i<n; i+= 1)
		String wave_name = ModIoUtil#string_element(trace_list,i,sep=sep)
		Wave /Z wave_tmp = TraceNameToWaveRef(fig,wave_name)
		if (!WaveExists(wave_tmp))
			continue
		EndIf
		String to_check = filtered_folder + wave_name + suffix
		// Then make it by filtering
		Duplicate /O wave_tmp $to_check
		Variable n_points = DimSize(wave_tmp,0) * filter_pct()
		ModNumerical#savitsky_smooth($to_check,n_points=n_points)
		// Add it to the graph
		// /Q: prevent other graphs from updating
		// /W: specify window
		// /C: specify color 
		AppendToGraph/L=$("L0")/Q/W=$(fig)/C=(0,0,0) $to_check
	EndFor
End function

Static Function save_event_on_keyboard_enter(s)
	// Given a window event, saves out the current cursor indices on
	// an enter
	//
	// Args:
	// 	s: the WMWinHookStruct of the event (we assume it is a keyboard event)
	// Returns
	//	Nothing, saves the data out 
	Struct WMWinHookStruct &s
	struct cursor_info info_struct
	// if we hit enter on the window, go ahead and save the cursor positions out.
	if (ModIoUtil#is_ascii_enter(s.keycode))
		String window_name = s.winName
		ModIoUtil#cursor_info(window_name,info_struct)
		// Get the data folder...
		// Args:
		//	kind: what to treturn
		// 		0 	Returns only the name of the data folder containing waveName.
		//		1 	Returns full path of data folder containing waveName, without wave name.
		//
		Variable kind =1
		String data_folder = GetWavesDataFolder(info_struct.trace_reference,kind)
		// Get the base name; we want to get the absolute offset for the entire trace...
		String base_name
		// our regex is anything, following by numbers, a (possible) single underscore, then letters
		String regex = "(.+?)[_]?[a-zA-Z]+$"
		SplitString /E=(regex) info_struct.trace_name,base_name
		Variable offset = ModForceReview#offset_from_wave_base(data_folder,base_name,info_struct.trace_name)
		Variable start_idx = info_struct.a_idx + offset
		Variable end_idx = info_struct.b_idx + offset
		// POST: have the A and B cursors. Save them to the output file
		String start_idx_print,end_idx_print
		sprintf start_idx_print,"%d",start_idx
		sprintf end_idx_print, "%d",end_idx
		Make/FREE/T/N=(1,3) tmp = {base_name,start_idx_print,end_idx_print}
		ModIoUtil#save_as_comma_delimited(tmp,get_output_path(),append_flag=2)
	EndIf
End function 

Function  save_cursor_updates_by_globals(s)
	// hook functgion; called when the window has an event
	//
	// Args:
	//		s: instance of Struct WMWinHookStruct &s
	// Returns:
	//		Nothing
	// Window hook prototype function which saves the 
	Struct WMWinHookStruct &s
	Variable status_code = 0
	// XXX check if filtered wave has been added 
	String fig = s.WinName	
	strswitch(s.eventname)
		case "modified":
			break
		case "mousemoved":
			update_filtered_data(fig)
		case "mousewheel":
			// XXX TODO: zoom in... not quite working right...
			break		
		case "keyboard":
			save_event_on_keyboard_enter(s)
	endswitch
	return status_code
End Function

Static Function hook_cursor_saver_to_window(window_name,file_directory)
	// sets up the hook for a window to point to save_cursor_updates_by_globals
	//
	// Args:
	//		window_name: name of the window to hook to
	//		file_directory: location where we want to save the file
	// Returns:
	//
	//	Nothing
	String window_name,file_directory
	// only way to get the file path to the save file, above, if via a global string X_X...
	// XXX try to fix?
	// Overwrite the global variables
	String /G prh_tagging_output_directory = file_directory
	// Check that the file path is real
	ModErrorUtil#Assert(ModIoUtil#FileExists(prh_tagging_output_directory))
	// Write the output file
	Variable ref
	// Open without flags: new file, overwrites
	String output_path = get_output_path()
      //       only create the file if it doesnt exist
       if (    ModIoUtil#FileExists(output_path))
               // append to the existing file
               Open /Z/A ref as output_path
       else
               //  Create a new file
               //      Open without flags: new file, overwrites
               Open /Z ref as output_path
       endif
       // check that we actually created the file
      	ModErrorUtil#Assert(ModIoUtil#FileExists(output_path))
	Close ref
	// Make sure the window exists
	ModPlotUtil#assert_window_exists(window_name)
	SetWindow $(window_name) hook(prh_hook)=save_cursor_updates_by_globals
End Function

Static Function hook_cursor_saver_interactive(window_name)
	// sets up the hook for a window to point to save_cursor_updates_by_globals, asking the
	//user to give the folder 
	//
	// Args:
	//		window_name: name of the window to hook to
	// Returns:
	//		Nothing
	String window_name
	String file_directory
	// we pass file_name by reference; updated if we succeed
	if (ModIoUtil#GetFolderInteractive(file_directory))
		hook_cursor_saver_to_window(window_name,file_directory)
	else
		ModErrorUtil#Assert(0,msg="couldn't find the file...")
	endif
End Function

Static Function hook_cursor_current_directory(window_name)
	// sets up the hook for a window to point to save_cursor_updates_by_globals, saving alongside
	// wherever this pxp is
	//
	// Args:
	//		window_name: name of the window to hook to
	// Returns:
	//		Nothing
	String window_name
	PathInfo home
	// according to PathInfo:
	// "V_flag	[is set to] 0 if the symbolic path does not exist, 1 if it does exist."
	ModErrorUtil#Assert( (V_Flag == 1),msg="To use current directory as save, must save .pxp")
	// POST: path exists
	String file_directory = S_Path
	hook_cursor_saver_to_window(window_name,file_directory)
End Function

Static Function Main([error_on_no_force_review])
	// Description goes here
	//
	// Args:
	//		error_on_no_force_review: if true (default), throws an
	//		error when there is no force review
	//		
	// Returns:
	//
	//
	Variable error_on_no_force_review
	if (ParamIsDefault(error_on_no_force_review))
		error_on_no_force_review = 1
	EndIf
	String window_name = ModOfflineAsylum#force_review_graph_name()
	setup_tagging()
	delete_tmp_data(window_name)	
	// Make sure the window exists, otherwise just do a top-level
	if (!ModIoUtil#WindowExists(window_name))
		print("Couldn't find force review panel, attempting top level graph instead")
		ModErrorUtil#assert(!error_on_no_force_review)
		window_name = ModPlotUtil#gcf()
	else
		ListBox $( ModOfflineAsylum#force_review_list_control_name()) win=$( ModOfflineAsylum#master_force_panel_name()),proc=$("tagging_list_change_hook")
	EndIf
	hook_cursor_current_directory(window_name)
End Function