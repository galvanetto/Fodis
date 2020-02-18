#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName = ModReportUtil
#include "::Util:PlotUtil" 


Static Function FEC_Plot(WaveX,WaveY,[split_idx,XFactor,YFactor,Title,NFilterPoints,OffsetY,OffsetX,SignX,SignY,LegendLoc,SortByX])
	Wave WaveX,WaveY
	Variable XFactor,YFactor,NFilterPoints,OffsetY,OffsetX,SignX,SignY,SortByX,split_idx
	String Title,LegendLoc
	// Get the waves (copies) we need
	String NamePlotX = (NameOfWave(WaveX) + "_Plot")
	String NamePlotY = (NameOfWave(WaveY) + "_Plot")
	// Get the Y approach and retract
	String NameApprY = NamePlotY + "_Ap"
	String NameRetrY = NamePlotY + "_Re"
	// Get the x approach and retract
	String NameApprX = NamePlotX + "_Ap"
	String NameRetrX = NamePlotX + "_Re"
	KillWaves /Z $NamePlotX,$NamePlotY,$NameApprY,$NameRetrY,$NameApprX,$NameRetrX
	Duplicate /O WaveY,$NamePlotY
	Duplicate /O WaveX,$NamePlotX
	Wave SepBilayer = $NamePlotX
	Wave ForceBilayer = $NamePlotY
	// Set up the defaults
	if (ParamIsDefault(Title))
		Title = ""
	EndIf
	if (ParamIsDefault(LegendLoc))
		LegendLoc = ANCHOR_TOP_LEFT
	EndIf
	NFilterPoints = ParamIsDefault(NFilterPoints) ? 1 : NFilterPoints
	// if the user doesnt specify a factor, dont do anything
	XFactor = ParamIsDefault(XFactor) ? 1 : XFactor
	YFactor = ParamIsDefault(YFactor) ? 1 : YFactor
	OffsetY = ParamIsDefault(OffsetY) ? 0 : OffsetY
	OffsetX = ParamIsDefault(OffsetX) ? 0: OffsetX
	SignX = ParamIsDefault(SignX) ? -1 : SignX
	SignY = ParamIsDefault(SignX) ? -1 : SignY
	SortByX = ParamIsDefault(SortByX) ? 0 : SortByX
	Variable MinX = WaveMin(SepBilayer)
	Variable MinY = WaveMin(ForceBilayer)
	// Zero out the X
	SepBilayer[] = SepBilayer[p] - OffsetX
	// Zero out the Y 
	ForceBilayer[] = ForceBilayer[p] - OffsetY
	// Convert to the units specified
	ForceBilayer[] = ForceBilayer[p]*YFactor * SignY
	SepBilayer[] = SepBilayer[p] * XFactor * SignX
	// Get the approach and retract separately
	if (ParamIsDefault(split_idx))
		WaveStats /Q WaveY 
		split_idx  = V_maxRowLoc
	EndIf
	// Duplicate the Y waves accordingly
	Duplicate /O/R=[0,split_idx] ForceBilayer,$NameApprY
	Duplicate /O/R=[split_idx,Inf] ForceBilayer,$NameRetrY
	// Now the X
	Duplicate /O/R=[0,split_idx] SepBilayer,$NameApprX
	Duplicate /O/R=[split_idx,Inf] SepBilayer,$NameRetrX
	// If we need to, sort the Y by the x...
	if (SortByX)
		String IdxWave1name= NamePlotX + "I1"
		String IdxWave2name= NamePlotX + "I2"
		Duplicate /O $NameApprX $IdxWave1name
		Duplicate /o $NameRetrX $IdxWave2name
		Wave IdxWave1 =$IdxWave1name 
		IdxWave1[] = p
		Wave IdxWave2 = $IdxWave2name
		IdxWave2[] = p
		MakeIndex $NameApprX,IdxWave1
		MakeIndex $NameRetrX, IdxWave2
		// Sort everything
		IndexSort IdxWave1,$NameApprY,$NameApprX
		IndexSort IdxWave2,$NAmeRetrY,$NameRetrX
	EndIf
	// Plot everything
	String LabelStr
	String ApprColor = "r"
	String RetrColor = "b"
	if (NFilterPoints > 1)
		ModPlotUtil#PlotWithFiltered($NameApprY,X=$NameApprX,nFilterPoints=NFilterPoints,color=ApprColor)
		ModPlotUtil#PlotWithFiltered($NameRetrY,X=$NameRetrX,nFilterPoints=NFilterPoints,color=RetrColor)
		 LabelStr =",Approach,,Retract,"
	else
		ModPlotUtil#Plot($NameApprY,linestyle="",marker=".",mX=$NameApprX,color=ApprColor)
		ModPlotUtil#Plot($NameRetrY,linestyle="",marker=".",mX=$NameRetrX,color=RetrColor)
		LabelStr = "Approach,Retract"
	EndIf
	ModPlotUtil#ylabel("")
	ModPlotUtil#xlabel("")
	ModPlotUtil#pLegend(labelStr=LabelStr,location=LegendLoc)
	return split_idx
End Function