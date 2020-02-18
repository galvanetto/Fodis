// Use modern global access method, strict compilation
#pragma rtGlobals=3	

#pragma ModuleName = ModOperatingSystemUtil
#include ":ErrorUtil"
#include ":IoUtil"


// XXX TODO README:
// (1) python2.7
// (2) anaconda
// (3) on path!
//	(3a)	-- binary must be at:
//		Windows: "C:/Program Files/Anaconda2/python"
//		os x       : "//anaconda/bin/python"
//

Structure RuntimeMetaInfo
	// // User Specified Variables
	//path_to_research_directory: where Reseach lives
	String path_to_research_directory
	// path_to_input_file: where the input file lives
   String path_to_input_file
   // path_to_python_binary: where the binary file lives. Will be set it if doesn't exist
	String path_to_python_binary
	// // Do not set the following fields; they are set automagically / overwritten by Igor
	// Where the main file lives. 
	String path_to_main
	// path_to_output_file: where the output file lives
   String path_to_output_file
EndStructure


Static Function /S sanitize_path(igor_path)
	// Igor is evil and uses colons, defying decades of convention for paths. This function helps S
	//
	// Args:
	//		igor_path: the (raw) path to sanitize
	// Returns:
	//		the path as a string
	String igor_path
	if (!running_windows())
		igor_path = ModOperatingSystemUtil#sanitize_mac_path_for_igor(igor_path)
	else
		igor_path = ModOperatingSystemUtil#to_igor_path(igor_path)
	endif
	return igor_path
End Function

Static Function read_csv_to_path(basename,igor_path,[first_line])
	// reads a (simple) csv file into a wave specified 
	// Args:
	//		basename: the wave to read into; starts with <basename>0
	//		igor_path: the igor-style path to the file to read in
	//		first_line: skip the first y-1 lines
	// Returns;
	//		nothing, but reads each column of the wave into <basename><0,1,2,...>
	// Q: quiet
	// J: delimited text
	// D: doouble precision
	// K=1: all columns are numeric 
	// /L={x,y,x,x}: skip first y-1 lines
	// /A=<z>: auto name, start with "<z>0" and work up
	String basename, igor_path
	Variable first_line
	first_line = ParamIsDefault(first_line) ? 1 : first_line
	LoadWave/Q/J/D/K=1/L={0,first_line,0,0,0}/A=$(basename) igor_path	
End Function

Static Function /S windows_preamble()
	return "C:/"
End Function

Static Function execute_python(PythonCommand,input)
	// executes a python command, given the options
	//
	// Args:
	//	 	PythonCommand: the string to use 
	//		input: RuntimeMetaInfo object, for getting the python binary
	// Returns:
	//		nothing; throws an error if it finds one.
	String PythonCommand
	Struct RuntimeMetaInfo & input
	ModOperatingSystemUtil#assert_python_binary_accessible(input)
	// POST: we can for sure call the python binary
	if (!running_windows())
		PythonCommand = ReplaceString(mac_preamble(), PythonCommand, "/");
		PythonCommand = ReplaceString(":",PythonCommand,"/");		
	endif
	ModOperatingSystemUtil#os_command_line_execute(PythonCommand)
End Function

Static Function append_argument(Base,Name,Value,[AddSpace])
	// Function that appends "-<Name> <Value>" to Base, possible adding a space to the end
	//
	// Args:
	//		Base: what to add to
	//		Name: argument name
	//		Value: value of the argument
	//		AddSpace: optional, add a space. Defaults to retur
	// Returns:
	//		appended Base
	String & Base
	String Name,Value
	Variable AddSpace
	String Output
	AddSpace = ParamIsDefault(AddSpace) ? 1 : AddSpace
	sprintf Output,"-%s %s",Name,Value
	Base = Base + Output
	if (AddSpace)
		Base = Base + " "
	EndIf
End Function


Function running_windows() 
	// Flag for is running windows
	//
	// Returns:
	//		1 if windows, 0 if mac
	String platform = UpperStr(IgorInfo(2))
	Variable pos = strsearch(platform,"WINDOWS",0)
	return pos >= 0
End

Static Function /S def_python_binary_string()
	// Returns string for running python given this OS
	//
	// Returns:
	//		1 if windows, 0 if mac
	if (running_windows())
		return "C:/ProgramData/Anaconda2/python.exe"
	else
		return "//anaconda/bin/python2"
	endif
End Function

Static Function /S python_binary_string(input)
	// Returns string for running python given this OS and input
	//
	// Returns:
	//		relevant string (or default, if none exists)
	 Struct RuntimeMetaInfo & input
	 if (strlen(input.path_to_python_binary) > 0)
	 	return input.path_to_python_binary;
	 else
	 	return def_python_binary_string();
	 endif
End Function

Static Function assert_python_binary_accessible(input)
	// Function which checks that python is accessible; if not, it throws an error.
	//
	//	Args:
	//		input: RuntimeMetaInfo object
	//	Returns:
	//		None, interrupts execution if things are broken.
   Struct RuntimeMetaInfo & input
	String Command
	String binary = ModOperatingSystemUtil#python_binary_string(input)
	// according to python -h:
	// -V     : print the Python version number and exit (also --version)
	sprintf Command,"%s --version",binary
	// We want to do our own error handling
	Variable V_Flag = os_command_line_execute(Command,throw_error_if_failed=0)	
	String err
	sprintf err,"Python binary is inaccessible where we expect it (%s)", binary
	ModErrorUtil#Assert(V_Flag == 0,msg=err)
End Function

Static Function os_command_line_execute(execute_string,[throw_error_if_failed,pause_after])
	// executes a given string according to how the OS wants it (
	// ie: command-prompt style for windows or bashstyle for OS X)
	//
	// Args:
	//		execute_string: body of the command
	//		throw_error_if_failed: if true, throws an error if
	//		the command goes poorly. Defaults to true
	//		
	//		pause_after: if true, pauses excution after (XXX windows only)
	// Returns:
	//		V_flag, see ExecuteScriptText
	//
	String execute_string
	Variable throw_error_if_failed,pause_after
	throw_error_if_failed = ParamIsDefault(throw_error_if_failed) ? 1 : throw_error_if_failed
	pause_after = ParamIsDefault(pause_after) ? 0 : pause_after

	String Command
	if (!running_windows())
		// Pass to mac scripting system
		sprintf Command,"do shell script \"%s\"",execute_string
	else
		// Pass to windows command prompt
		sprintf Command,"%s",execute_string
	endif	
	// UNQ: remove leading and trailing double-quote (only for mac)
	print(Command)
	ExecuteScriptText /Z Command
	if (throw_error_if_failed)
		// according to ExecuteScriptText:
		// If the /Z flag is used then a variable named V_flag is
		// created and is set to a nonzero value if an error was generated by the script or zero if no error. 
		ModErrorUtil#Assert(V_flag == 0,msg="executing " + Command + " failed with return:"+S_Value)
	endif
	return V_flag
End Function

Static Function /S replace_double(needle,haystack)
	// replaces double-instances of a needle in haystaack with a single instance
	//
	// Args:
	//		needle : what we are looking for
	//		haystack: what to search for
	// Returns:
	//		unix_style, compatible with (e.g.) GetFileFolderInfo
	//
	String needle,haystack
	return ReplaceString(needle + needle,haystack,needle)
End Function

Static Function /S to_igor_path(unix_style)
	// convers a unix-style path to an igor-style path
	//
	// Args:
	//		unix_style : absolute path to sanitize
	// Returns:
	//		unix_style, compatible with (e.g.) GetFileFolderInfo
	//
	String unix_style
	String with_colons = ReplaceString("/",unix_style,":")
	// Igor doesnt want a leading colon for an absolute path
	if (strlen(with_colons) > 1 && (cmpstr(with_colons[0],":")== 0))
		with_colons = with_colons[1,strlen(with_colons)]
	endif
	return replace_double(":",with_colons)
End Function

Static Function /S sanitize_path_for_windows(path)
	// Makes an absolute path windows-compatible.
	//
	// Args:
	//		path : absolute path to sanitize
	// Returns:
	//		path, with leading /c/ or c/ replaced by "C:/"
	//
	String path
	Variable n = strlen(path) 
	if (GrepString(path[0],"^/"))
		path = path[1,n]
	endif
	// POST: no leading /
	path = replacestring(":",path,"/")
	path = replace_double("/",path)
	return replace_start("C/",path,"C:/")
End Function

Static Function /S replace_start(needle,haystack,replace_with)
	// Replaces a match of a pattern at the start of a string
	//
	// Args:
	//		needle : pattern we are looking for at the start
	//		haystack : the string we are searching in
	//		replace_with: what to replace needle with, if we find it
	// Returns:
	//		<haystack>, with <needle> replaced by <replace_with>, if we find it. 
	String needle,haystack,replace_with
	Variable n_needle = strlen(needle)
	Variable n_haystack = strlen(haystack)
	if ( (GrepString(haystack,"(?i)^" + needle)))
		haystack = replace_with + haystack[n_needle,n_haystack]
	endif 
	return haystack
End Function

Static Function /S sanitize_windows_path_for_igor(path)
	// Makes an absolute windows-style path igor compatible
	//
	// Args:
	//		path : absolute path to sanitize
	// Returns:
	//		path, with leading "C:/" replaced by /c/ 
	//
	String path
	return replace_start("C:/",path,"/c/")
End Function

Static Function /S mac_preamble()
	// Returns: the preamble used for mac
	return "Macintosh HD:"
End Function

Static Function /S sanitize_mac_path_for_igor(path)
	// Makes an absolute windows-style path igor compatible
	//
	// Args:
	//		path : absolute path to sanitize
	// Returns:
	//		path, with leading "C:/" replaced by /c/ 
	//
	String path;
	String igor_path = ModOperatingSystemUtil#to_igor_path(path);
	String expected_preamble =  mac_preamble();
	String actual_preamble =  igor_path[0,strlen(expected_preamble)];
	Variable preamble_exists = (cmpstr(actual_preamble,expected_preamble));
	if (!preamble_exists)
		igor_path = mac_preamble() + igor_path;
	endif
	// replace possible double colons
	igor_path = ModOperatingSystemUtil#replace_double(":",igor_path);
	return igor_path
End Function

Static Function get_updated_options(output)
	// Updates (by reference) output to account for operating system snafus
	//
	// Args:
	//	output: RuntimeMetaInfo object, fully set
	// Returns:
	//	nothing, but updates output appropriately 
	Struct RuntimeMetaInfo & output
	// POST: input has been copied to output. 
	// do some cleaning on the input and output...
	output.path_to_input_file = ModOperatingSystemUtil#replace_double("/",output.path_to_input_file)
	output.path_to_research_directory = ModOperatingSystemUtil#replace_double("/",output.path_to_research_directory)
	String input_file_igor, python_file_igor
	// first thing we do is check if all the files exist
	if (ModOperatingSystemUtil#running_windows())
		output.path_to_input_file = ModOperatingSystemUtil#sanitize_windows_path_for_igor(output.path_to_input_file)
		output.path_to_research_directory = ModOperatingSystemUtil#sanitize_windows_path_for_igor(output.path_to_research_directory)
		input_file_igor = ModOperatingSystemUtil#to_igor_path(output.path_to_input_file)
		python_file_igor = ModOperatingSystemUtil#to_igor_path(output.path_to_main)
	else
		input_file_igor = ModOperatingSystemUtil#sanitize_mac_path_for_igor(output.path_to_input_file)
		python_file_igor = ModOperatingSystemUtil#sanitize_mac_path_for_igor(output.path_to_main)
	endif
	// // ensure we can actually call the input file (ie: it should exist)
	Variable FileExists = ModIoUtil#FileExists(input_file_igor)
	String ErrorString = "Bad Path, received non-existing input file: " + output.path_to_input_file
	ModErrorUtil#Assert(FileExists,msg=ErrorString)
	// POST: input file exists
	// // ensure we can actually find the python file
	FileExists = ModIoUtil#FileExists(ModOperatingSystemUtil#to_igor_path(python_file_igor))
	ErrorString = "Bad Path, couldnt find python script at: " + python_file_igor
	ModErrorUtil#Assert(FileExists,msg=ErrorString)
	// POST: input and python directories are a thing!
	String output_file = output.path_to_output_file
	output.path_to_output_file = ModOperatingSystemUtil#sanitize_path(output_file)
	if (running_windows())
		// much easier just to use the user's input, assume it is OK at this point.
		// note that windows needs the <.py> file path to be something like C:/...
		output.path_to_research_directory = ModOperatingSystemUtil#sanitize_path_for_windows(output.path_to_research_directory)
	endif	
End Function

Static Function assert_run_generated_output(output)
	// Asserts that the output file listed in 'output' exists
	//
	// Args:
	// 		output: see get_updated_options
	// Returns:
	//		Nothing, throws an error if things go wrong. 
	Struct RuntimeMetaInfo & output
	// Ensure the file actually got made...	
	String igor_path = output.path_to_output_file
	Variable FileExists = ModIoUtil#FileExists(igor_path)
	String ErrorString = "IWT couldnt find output file at: " + igor_path
	ModErrorUtil#Assert(FileExists,msg=ErrorString)
End Function 

Static Function get_output_waves(waves_references,output,[skip_lines,base_name,kill_file])
	// Gets the output columns associated with the given csv output
	//
	// Args:
	//	waves_references: a wave of waves (made with 'Make /WAVE = {blah1,blah2}') which hold the in-order
	//	columns associted with the output file (e.g. if the columns are time,separation,force, the waves should be 
	//	in that order)
	//
	//	output: see get_updated_options
	//	skip_lines: how many lines to skip if the file hasa header. defaults to 0  (no header)
	// 	base_name: the name for the temporary waves that will be made. 
	//	kill_file: if the file should be deleted after being read. *default to true*, to avoid stale results
	//
	//	Returns:
	//		nothing, throws errors if the output file doesn't exist. 
	Wave /WAVE waves_references
	Struct RuntimeMetaInfo & output
	Variable skip_lines
	Variable kill_file
	String base_name
	if (ParamIsDefault(base_name))
		base_name = "prh_tmp_input"
	EndIf	
	skip_lines = ParamIsDefault(skip_lines) ? 0 : skip_lines
	kill_file = ParamIsDefault(kill_file) ? 1 : kill_file
	// Make sure the output file was make
	ModOperatingSystemUtil#assert_run_generated_output(output)
	// POST: run generated a file	
	Variable first_line = skip_lines+1
	Variable i
	Variable n = DimSize(waves_references,0)
	String igor_path = output.path_to_output_file
	// read the file in
	ModOperatingSystemUtil#read_csv_to_path(base_name,igor_path,first_line=first_line)
	// POST: reading went OK, read all the waves in
	for (i=0;  i<n ; i+=1)
		Wave m_tmp_wave = $(base_name + num2str(i))
		Wave tmp = waves_references[i]
		Duplicate /O m_tmp_wave,tmp
		// Kill the placeholder wave 
		KillWaves /Z m_tmp_wave
	EndFor
	// POST: all waves are read. clean up the file if we need to. 
	if (kill_file)
		// kill the output file
		// /Z: if the file doesn't exist, dont worry about it  (we assert we deleted below)
		DeleteFile /Z (igor_path)
		ModErrorUtil#Assert(V_flag == 0,msg="Couldn't delete output file: " + igor_path + " Is it open somewhere?")
	EndIf
End Function



Static Function append_numeric(s,name,value)
	// Pass-by-value function. converts value to a string, appends to s
	//
	// Args:
	//	see ModOperatingSystemUtil#append_argument
	// Returns:
	//	see ModOperatingSystemUtil#append_argument
	String & s
	String name
	Variable value
	return ModOperatingSystemUtil#append_argument(s,name,num2str(value))
End Function

Static Function append_if_not_default(s,name,value,[default_value])
	// See: append_numeric, except only appends if value != default_value
	String & s
	String name
	Variable value,default_value
	default_value = ParamIsDefault(default_value) ? 0 : default_value
	if (value != default_value)
		 append_numeric(s,name,value)
	EndIf
End Function


Static Function add_input_output_args(Output,meta,[add_space_at_end])
	// Adds the input and output arguments from meta.path_to_<input/output>_file.
	// Assumes  that the input and output file are correct, not including possible sanitization
	//
	// Args:
	//		Output: pass-by-reference string, see ModOperatingSystemUtil#append_argument
	//  		meta: RuntimeMetaInfo instance
	//		add_space_at_end: if 1, adds a space after the final argument. defaults to no.
	// Returns:
	//		nothing, but sets the 
	String & Output
	Struct RuntimeMetaInfo & meta
	Variable add_space_at_end
	add_space_at_end = ParamIsDefault(add_space_at_end) ? 0 : add_space_at_end
	String output_file = meta.path_to_output_file
	String input_file = meta.path_to_input_file
	// Windows is a special flower and needs its paths adjusted
	if (running_windows())
		output_file = ModOperatingSystemUtil#sanitize_path_for_windows(output_file)
		input_file = ModOperatingSystemUtil#sanitize_path_for_windows(input_file)
	endif
	ModOperatingSystemUtil#append_argument(Output,"file_input",input_file)
	ModOperatingSystemUtil#append_argument(Output,"file_output",output_file,AddSpace=add_space_at_end)
End Function

