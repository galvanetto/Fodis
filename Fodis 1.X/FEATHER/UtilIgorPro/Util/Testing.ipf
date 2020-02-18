// Use modern global access method, strict compilation
#pragma rtGlobals=3	

#pragma ModuleName = ModTesting

Static Function assert_wave_dimensions_OK(saved_wave,n_cols_expected,n_rows_expected)
	// makes sure that the saved wave exists and has the right dimensions
	//
	// Args:
	//	saved_wave: what we saved out
	//	n_<rows/cols>_expected: how many rows or columns
	// Returns:
	//	Nothing, asserts that all the conditions are met. 
	Wave saved_wave
	Variable n_cols_expected,n_rows_expected
	// Make sure the waves exist 
	ModErrorUtil#assert_wave_exists(saved_wave)
	// Order appears to be [ZSnsr,ZSnsr(again),Defl_Meters]
	Variable n_rows = DimSize(saved_wave,0)
	Variable n_cols = DimSize(saved_wave,1)
	// make sure we got the correct number of rows and colujmns
	String err_rows = ("Got " + num2str(n_rows) + " rows, not " + num2str(n_rows_expected))
	String err_cols = ("Got " + num2str(n_cols) + " cols, not exactly " + num2str(n_cols_expected))
	ModErrorUtil#assert(n_rows == n_rows_expected,msg=err_rows)
	ModErrorUtil#assert(n_cols == n_cols_expected,msg=err_cols)
End Function

Static Function assert_note_contained(note_expected,note_to_test,[break_pattern])
	// Asserts that each element in the expected note are in the test note/
	// (allows for extra elements in the test note)
	//
	// Args:
	//	note_<expected/to_test>: the asylum-style note we are interested in
	// 	break pattern: if not default, matches this to each key:value\r pair in the 
	//	expected note. if the perl-style regex matches (using GrepString), then
	//	that element is ignored
	// Returns:
	//	nothing, throws an error if something is wrong
	String note_expected,note_to_test,break_pattern
	Variable nop = ItemsInList(note_expected,"\r")
	String CustomItem
	Variable Index,A
	for (A = 0;A < nop;A += 1)
		Index = 0
		CustomItem = StringFromList(A,note_expected,"\r")
		Index = strsearch(CustomItem,":",0,2)
		Variable break_boolean = ParamIsDefault(break_pattern) ? 0 : GrepString(CustomItem,break_pattern)
		if (Index < 0 || break_boolean)
			Continue
		endif
		String key = CustomItem[0,Index-1]
		String value = ModAsylumInterface#note_string(note_to_test,key)
		String expected_value = ModAsylumInterface#note_string(note_expected,key)
		String msg
		sprintf msg, "For Note key %s, expected '%s', found '%s'",key,expected_value,value
		ModErrorUtil#Assert(ModIoUtil#strings_equal(expected_value,value),msg=msg)
	endfor
End Function 

Static Function all_close(wave_a,wave_b,[rel_tol,abs_tol])
	// Ensures that the two waves are equal to eachother withing
	// a relative and absolute tolerance. not symmetric, since:
	//
	// element[i] is true iff
	//
	//	|WaveA-WaveB| <= |WaveA| * rel_tol + abs_tol
	//
	// Args:
	//	wave_<a/b>: the two waves to compare. 
	//	<rel/abs>_tol: the relative and absolute tolerances
	// Returns:
	//	true iff all elements of the waves are close 
	Wave wave_a,wave_b
	Variable rel_tol,abs_tol
	rel_tol = ParamIsDefault(rel_tol) ? 1e-6 : rel_tol
	abs_tol = ParamIsDefault(abs_tol) ? 0 : abs_tol 
	Variable n = DimSize(wave_a,0)
	Make /FREE/N=(n) bool_tmp,error_diff,max_error
	error_diff[] = abs(wave_a[p] - wave_b[p]) 
	max_error[] =  abs(wave_a[p]) * rel_tol + abs_tol
	bool_tmp[] = (error_diff[p] <= max_error[p])
	Variable number_less = (sum(bool_tmp)
	return (number_less == n)
End Function

