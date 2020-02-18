// Use modern global access method, strict compilation
#pragma rtGlobals=3	

#include ":MenuUtil"
#pragma ModuleName = ModSettingsImaging

Static Function ImagingDNA()
	Variable ScanSize = 4e-6
	Variable ScanRate = 0.5
	Variable ScanDim = 512
	Variable Offsets = 0
	ModMenuUtil#SetVariableMasterPanel(ModMenuNames#MasterScanSize(),ScanSize)
	ModMenuUtil#SetVariableMasterPanel(ModMenuNames#MasterScanRate(),ScanRate)
	ModMenuUtil#SetVariableMasterPanel(ModMenuNames#MasterScanPixels(),ScanDim)
	ModMenuUtil#SetVariableMasterPanel(ModMenuNames#MasterOffsetX(),Offsets)
	ModMenuUtil#SetVariableMasterPanel(ModMenuNames#MasterOffsetY(),Offsets)
End Function

Static Function Main()
	// Description goes here
	//
	// Args:
	//		Arg 1:
	//		
	// Returns:
	//
	//
End Function