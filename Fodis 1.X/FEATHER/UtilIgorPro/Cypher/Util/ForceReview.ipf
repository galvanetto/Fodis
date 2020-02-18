#pragma rtGlobals=3	

#pragma ModuleName = ModForceReview 
#include "::OfflineAsylum"

Static Function offset_from_wave_base(data_folder,base_name,trace)
	// Given a data folder, and a base name associted with the force review graph,
	// gets the full offset associated with trace (ie: if trace is just the retract, also adds
	// in the approach and dwell points for the 
	//
	// Args:
	//	data_folder: where all the traces live
	// 	base_name: the start of the name; we can add '_Ext' to this and get the
	//	(for example) approach wave name (e.g. "Image0010Defl")
	//	trace: the actual trace we want to offset
	// Returns:
	// 	The actual offset needed in the original data 
	String data_folder,base_name,trace
	// get the offset associated 
	String appr_str = "_Ext",dwell_str = "_Towd",ret_str="_Ret"
	String base_path = data_folder + base_name
	String ApproachName =  (base_path + appr_str)
	String DwellName =  (base_path + dwell_str)
	Variable offset  =0 
	if (!WaveExists($ApproachName) || !WaveExists($DwellName))
		offset = 0
		return offset
	endif
	// we want the absolute coordinate, regardless of whatever asylum says
	// It 'slices' the data in force review based on the 'indexes' note variable 
	String saved_idx=  ModOfflineAsylum#get_indexes(Note($ApproachName))
	Variable asylum_offset =  ModOfflineAsylum#get_index_field_element(saved_idx,0)
	offset = offset + asylum_offset			
	Variable n_approach = DimSize( $ApproachName,0)
	Variable n_dwell = DimSize($(DwellName),0)
	// get the actual offset
	if (ModIoUtil#string_ends_with(trace,appr_str))
		// no offset; dont do anything
		offset = 0 
	elseif(ModIoUtil#string_ends_with(trace,dwell_str))
		offset = n_approach
	else
		String err_message = "Dont recognize wave: " + base_path + trace
		ModErrorUtil#Assert(ModIoUtil#string_ends_with(trace,ret_str),msg=err_message)
		// POST: we know what is happening
		offset = n_approach + n_dwell
	endif
	return offset
End Function
