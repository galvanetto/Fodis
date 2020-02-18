// Use modern global access method, strict compilation
#pragma rtGlobals=3	

#pragma ModuleName = ModNoiseTest
#include "::FastCapture:NewFC"
#include "::ForceModifications"
#include ":::Util:IoUtil"
#include ":::Util:PlotUtil"
#include ":::Util:Numerical"
#include "::asylum_interface"

Static Function capture_500Khz(timespan)
	// captures <timespan> length of 500KHz data. 
	// 
	// Args:
	//	timespan: how much data to acquire. 
	// Returns:
	//	nothing 
	Variable timespan
	Variable speed = 0
	// XXX get 10s first, then 300s (to prevent 'start' noise / hystereis?)
	NewDataFolder /O root:prh
	NewDataFolder /O root:prh:noise
	Make /O/N=0 root:prh:noise:defl, root:prh:noise:zsnsr
	ModFastCapture#fast_capture_setup(speed,timespan,root:prh:noise:defl,root:prh:noise:zsnsr)
	ZeroPD()	
	ModFastCapture#fast_capture_start()
End Function

Static Function Main([capture_seconds])
	// Runs the capture_indenter function with all defaults
	// Capture 10s of data first, then overwrite and capture 5s 
	// (this is to avoid noise with the fast capture starting)
	Variable capture_seconds
	capture_seconds = ParamIsDefault(capture_seconds) ? 100 : capture_seconds
	capture_500Khz(capture_seconds)
End Function
