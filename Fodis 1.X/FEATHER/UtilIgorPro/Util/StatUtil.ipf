// Use modern global access method, strict compilation
#pragma rtGlobals=3	

#pragma ModuleName = ModStatUtil

Static Constant FINDLEVEL_RET_TRUE = 0

Structure WaveStat
	Variable stdev
	Variable average
	Variable rms
	Variable maxRowLoc
EndStructure

// Finds *index* where mWave first crosses mLevel, or returns startIDx/endIdx if searchBackwards is
// False,True
Static Function FindIdxLevelCrossing(mWave,mLevel,startIdx,endIdx,searchBackwards)
	Wave mWave
	Variable mLevel,startIdx,endIdx,searchBackwards
	// Do some santizzation on the inputs
	startIdx = max(0,startIdx)
	endIdx = min(endIdx,DimSize(mWave,0))
	// POST: indices are in bounds
	// V-173: /R specifies the indices in which to search
	// /Q: dont spam 
	if (searchBackwards)
		FindLevel /Q/R=[endIdx,startIdx],mWave,mLevel
	else
		FindLevel /Q/R=[startIdx,endIdx],mWave,mLevel
	EndIf
	Variable mIndexToReturn 
	if (V_flag != FINDLEVEL_RET_TRUE)
		// We didnt find the level
		// return the first point (if forwards searching) or last point (reverse searching)
		mIndexToReturn = searchBackwards ? startIdx : endIdx
	else
		// found the level
		mIndexToReturn = x2pnt(mWave,V_levelX)
	EndIf
	return mIndexToReturn
End Function

Static Function GetWaveStats(mWave,mStats,[StartIdx,EndIdx])
	Wave mWave
	Struct WaveStat & mStats
	Variable StartIdx,EndIdx
	// P V-746
	// /Q: quiet 
	// /R=[X,Y]: index from x to Y
	if (!ParamIsDefault(StartIdx) && !ParamIsDefault(EndIdx) )
		WaveStats /Q/R=[StartIdx,EndIdx] mWave
	Else
		WaveStats /Q mWave
	EndIf
		
	// WaveStats (by side effect, ick) creates variabes on  V-747
	mStats.stdev =  V_sdev
	mStats.average = V_avg
	mStats.rms = V_rms
	mStats.maxRowLoc = V_maxRowLoc
End Function
