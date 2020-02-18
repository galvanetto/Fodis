// Use modern global access method, strict compilation
#pragma rtGlobals=3	

#pragma ModuleName = ModStartUpUtil
#include ":PlotUtil"
#include ":Defines"

// if nukeLocal, Nukes everything in the current experiment, closes all windows and graphs 
Static Function FreshSlate([nukeLocal])
	Variable nukeLocal
	nukeLocal = ParamIsdefault(nukeLocal) ? ModDefine#False() : ModDefine#True()
	// May ave leftover waves saved (e.g. axhline). kill these)
	ModPlotUtil#ResetPlotUtil()
	if (nukeLocal)
		KillDataFolder /Z root:
	EndIf
	// Kill every path
	KillPath /A 
End Function