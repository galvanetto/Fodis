// Use modern global access method, strict compilation
#pragma rtGlobals=3	

#include "::Feather"
#include ":::UtilIgorPro:Util:PlotUtil"
#include ":::UtilIgorPro:Util:IoUtil"
#include ":::UtilIgorPro:Util:OperatingSystemUtil"
#include ":::UtilIgorPro:Cypher:OfflineAsylum"



#pragma ModuleName = ModMainFeather


Static StrConstant DEF_PATH_NAME = "Example"
Static StrConstant DEF_INPUT_REL_TO_BASE ="Data:feather_example.pxp"

Static Function Main_Windows()
	// Runs a simple IWT on patrick's windows setup
	ModMainFEATHER#Main()
End Function 

Static Function Main_Mac()
	// Runs a simple IWT on patrick's mac setup 
	ModMainFEATHER#Main()
End Function

Static Function Main([base,input_file])
	// // This function shows how to use the IWT code
	// Args:
	//		base: the folder where the Research Git repository lives 
	//		input_file: the pxp to load. If not present, defaults to 
	//		<base>DEF_INPUT_REL_TO_BASE
	String base,input_file
	if (ParamIsDefault(base))
		base = ModIoUtil#pwd_igor_path(DEF_PATH_NAME,n_up_relative=3)
	EndIf
	if (ParamIsDefault(input_file))
		input_file  = base +DEF_INPUT_REL_TO_BASE
	EndIf
	KillWaves /A/Z
	ModPlotUtil#KillAllGraphs()
	// IWT options
	Struct FeatherOptions opt
	opt.tau = 0
	opt.threshold = 1e-3
	opt.tau = 1.5e-2
	// Load the wave
	String loc_tmp = "root:tmp"
	ModIoUtil#LoadFile(input_file,locToLoadInto=loc_tmp)
	// Add the meta information
	Variable n_waves_loaded =ModIoUtil#CountWaves(loc_tmp)  
	Variable valid = n_waves_loaded > 0
	ModErrorUtil#Assert(valid,msg="Didn't load waves")
	String tmp = ModIoUtil#GetWaveAtIndex(loc_tmp,0,fullPath=1)
	String note_v = note($tmp)
	opt.trigger_time = ModOfflineAsylum#note_variable(note_v,"TriggerTime",delim_pairs=",")
	opt.dwell_time = ModOfflineAsylum#note_variable(note_v,"DwellTime",delim_pairs=",")
	opt.spring_constant = ModOfflineAsylum#note_variable(note_v,"SpringConstant",delim_pairs=",")
	// add the file information
	opt.meta.path_to_input_file = input_file
	opt.meta.path_to_research_directory = base
	opt.meta.path_to_python_binary = ModOperatingSystemUtil#def_python_binary_string()
	// Make the output waves
	Struct FeatherOutput output
	Make /O/N=0, output.event_starts
	// Execte the command
	ModFeather#feather(opt,output)
	// Make a fun plot wooo
	LoadData /O/Q/R (ModOperatingSystemUtil#sanitize_path(input_file))
	Wave Y =  $("Image0994Force")
	y[] *= -1
	Wave X =  $("Image0994Sep")
	Display Y
	Variable n_events = DimSize(output.event_starts,0)
	Variable i
	for (i=0; i<n_events; i+=1)
		Variable event_idx = output.event_starts[i]
		ModPlotUtil#axvline(event_idx)
	endfor
	ModPlotUtil#xlabel("Extension (m)")
	ModPlotUtil#ylabel("Force (N)")
	Edit output.event_starts as "Predicted Event Indices in Wave"
End Function
