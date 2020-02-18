// Use modern global access method, strict compilation
#pragma rtGlobals=3	

#pragma ModuleName = ModUnitTestFastCapture
#include ":::asylum_interface"
#include "::fast_indenter"
#include "::::Util:Testing"

Static Function setup(input_base,inf_tmp)
	// Sets up the file structure for the unit testing
	//
	// Args;
	//	input_base: the asylum-style 'stem' name of the wave we want to test (e.g.
	//	Image0010)
	//
	//	inf_tmp: the pass-by-reference struct we will use
	//Returns:
	//	nothing, but sets the structure appropriately
	String input_base
	struct indenter_info & inf_tmp
	ModFastIndenter#setup_directory_sturcture()
	String base = ModFastIndenter#default_save_folder()
	String base_path_high_resolution = base + input_base + ModFastIndenter#default_wave_base_suffix()
	inf_tmp.x_wave_high_res = base_path_high_resolution + "ZSnsr"
	inf_tmp.y_wave_high_res = base_path_high_resolution + "DeflV"
	inf_tmp.points_per_second = 5e5
	// Don't do any calls..
	ModFastIndenter#set_calls_remaining(0)
	// save out the indenter structure.
	ModFastIndenter#save_info_struct(inf_tmp)	
End Function


Static Function assert_data_matches(saved_wave,zsnsr_volts,defl_volts,tolerance_relative)
	// Ensures the saved data matches
	// 
	// Args: 
	//	saved_wave: the 2-D wave saved out, assumed that the not and 
	//	formatting is correct
	//	<zsnsr/defl>_volts: the expected z sensor and deflection in volts
	//
	// Returns:
	//	nothing, but throws an error if something goes wrong 
	Wave saved_wave,zsnsr_volts,defl_volts
	Variable tolerance_relative
	String note_expected = Note(zsnsr_volts)
	Make /O/N=0/FREE expected_z_meters,expected_defl_meters
	Variable invols = ModAsylumInterface#note_invols(note_expected)
	Variable z_sens = ModAsylumInterface#note_z_sensitivity(note_expected)
	ModAsylumInterface#volts_to_meters(zsnsr_volts,defl_volts,z_sens,invols,expected_z_meters,expected_defl_meters)
	Duplicate /FREE/O zsnsr_volts,ZSnsr_meters
	Duplicate /FREE/O defl_volts,Defl_meters
	ModErrorUtil#assert_wave_exists(saved_wave)	
	// asylum-saved Order appears to be [ZSnsr,ZSnsr(again),Defl_Meters]
	ZSnsr_meters[] = saved_wave[p][0]
	Defl_meters[] = saved_wave[p][2]
	ModErrorUtil#Assert(ModTesting#all_close(expected_z_meters,ZSnsr_meters),msg="ZSnsr not saved properly")
	ModErrorUtil#Assert(ModTesting#all_close(expected_defl_meters,Defl_meters),msg="Defl not saved properly")
End Function

Static Function reload_saved_wave_and_check(inf_tmp,suffix_before_save,tolerance_relative)
	// get the most-recently saved wave, make sure:
	//
	// (1) the size of the saved data is OK
	// (2) the note of the saved data is OK
	// (3) the data saved by the data is OK
	//
	// Args:
	//	inf_tmp: the indenter_info object holding string 'pointers'
	//	to the data we saved out
	//	suffix_before_save: the suffix before the save (ie: what the suffix
	//	should be for the data has been saved). E.g. "0010" for "Image0010"
	//
	//	tolerance_relative: the relative error tolerance as a fraction of the expected data
	// Returns:
	//	nothing, but asserts errors if the data is screwed up 
	struct indenter_info & inf_tmp
	Variable suffix_before_save,tolerance_relative
	// XXX TODO: read back in the file, make sure the data wasn't corrupted 
	Wave /T globals = root:packages:MFP3D:Main:Strings:GlobalStrings
	String path_to_save = globals[%SaveImage]
	// we saved at the current-1 (the suffix is updated when we save)
	Variable saved_suffix = ModAsylumInterface#current_image_suffix()-1
	ModErrorUtil#assert(suffix_before_save == saved_suffix,msg="After save, suffix not changed")
	// POST: suffix is consistent. go ahead and get the full path
	String base_name = ModAsylumInterface#master_base_name()
	String wave_name
	sprintf wave_name,"%s%04d",base_name,saved_suffix
	String save_path
	sprintf save_path,"%s%s",path_to_save,wave_name
	// Load the file
	LoadWave /H/O save_path
	// These waves are assumed both in volts. (the input wave 
	Wave x_wave_in_memory = $(inf_tmp.x_wave_high_res)
	Wave y_wave_in_memory = $(inf_tmp.y_wave_high_res)
	Wave saved_wave = $(wave_name)
	Variable n_cols_needed = 3
	Variable n_rows_expected = DimSize(x_wave_in_memory,0)
	ModTesting#assert_wave_dimensions_OK(saved_wave,n_cols_needed,n_rows_expected)
	// POST: size of the array is OK
	// Check that the expected note in contained in the actual note saved
	// (we dont care about SaveForce: or SaveImage: fields, which otherwise mess things up)
	String note_actual = Note(saved_wave)
	String note_expected = Note(x_wave_in_memory)
	ModTesting#assert_note_contained(note_expected,note_actual,break_pattern="^Save(Force|Image):")
	// POST: note is OK 
	// Check the data. First we need to convert the data we have into
	// meters
	assert_data_matches(saved_wave,x_wave_in_memory,y_wave_in_memory,tolerance_relative)
End Function

Static Function Main([input_base])
	// test that the fast capture is working
	//
	// Args:
	//		input_base: the input file to use, assumed part of the current experiment.
	//		e.g. 'Image0097'
	// Returns:
	//	 Nothing
	//
	String input_base
	if (ParamIsDefault(input_base))
		input_base = "Image2344"
	endIf
	// go ahead and manually save out the struct we want..
	struct indenter_info inf_tmp
	setup(input_base,inf_tmp)
	// // check saving out the data (test this before the gui-changing functions, below
	Variable suffix_before_save = ModAsylumInterface#current_image_suffix()
	ModFastIndenter#align_and_save_struct(inf_tmp)
	// Make sure the wave we just saved had the same data and same 
	// note as the wave in memory
	reload_saved_wave_and_check(inf_tmp,suffix_before_save,1e-6)
	// POST: data, note, etc are all OK. 
	// // make sure the GUI-handling works
	ModFastIndenter#setup_gui_for_fast_capture()
 	// POST: GUI-handling works as desired. 
	// // Check the the setup is OK
	ModFastIndenter#setup_indenter()	
	// POST: setup is also fine; only potential problem is the actual run-code, 
	// which can be unit tested by attempting to take data. 
End Function