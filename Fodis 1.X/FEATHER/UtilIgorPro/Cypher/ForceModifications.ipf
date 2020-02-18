// Use modern global access method, strict compilation
#pragma rtGlobals=3	

#pragma ModuleName = ModForceModifications


//this handles all of the Force buttons
Static Function prh_DoForceFunc(ctrlName,[non_ramp_callback])
	// This is a very slight modification of DoForceFunc from Cypher 14.30.157 (copied 2017-6-6, prh)
	// Args:
	//	ctrlName: see  DoForceFunc
	//	non_ramp_callback: single-function function name (like "foo", *not* like "foo(arg)") 
	//	taking in the control name. Should *definitely* call FinishForceFunc before it does anything else
	//
	// Returns :
	//	see DoForceFunc
	string ctrlName,non_ramp_callback
	if (ParamIsDefault(non_ramp_callback))
		non_ramp_callback = "FinishForceFunc"
	EndIf 
	if (GV("DoThermal"))
		DoThermalFunc("ReallyStopButton_1")
	endif
	PV("ElectricTune;LateralTune;",0)
	
	Variable RemIndex = strsearch(ctrlName,"Force",0)-1
	if (RemIndex > 0)
		ctrlName = ctrlName[0,RemIndex]		//strip out the important part of the ctrlName
	endif
	String ErrorStr = ""


	Variable TabNum
	String TabStr, DoIVBias
	TabNum = ARPanelTabNumLookUp("ForcePanel")
	TabStr = "_"+num2str(TabNum)

	strswitch (ctrlName)
	
		case "RTUpdatePrefs":
			SVAR WhatsRunning = $InitOrDefaultString(GetDF("Main")+"WhatsRunning","")
			if (WhichListItem("Force",WhatsRunning,";",0,0) >= 0)
				IR_stopOutWaveBank(1)		//stop the updates from continuing.
				Print "Can not change prefernce mid-force plot, RT update turned off temporarily\rplease change prefernces after this force plot"
				DoWindow/H
				return(0)
			endif
			String OpsList = "Never;Auto;Always;"
			String ThisOps = UiMenu2("Update the Force Graph in Real Time?",OpsList,StringFromList(GV("DoRTForceUpdate"),OpsList,";"))
			if (Strlen(ThisOps))		//something was selected.
				Variable WhichOne = WhichListItem(ThisOps,OpsList,";",0,0)
				PV("DoRTForceUpdate",WhichOne)
			endif
				
			return(0)

		case "Split":

			PV("VelocitySynch",0)
			DoWindow/K MasterPanel
			if (V_flag)
				MakePanel("Master")
			endif
			DoWindow/K ForcePanel
			if (V_flag)
				MakePanel("Force")
			endif
			ForceSetVarFunc("ForceScanRateSetVar"+TabStr,GV("ForceScanRate"),"",":Variables:ForceVariablesWave[%ForceScanRate]")
			return 0

		case "Sync":

			PV("VelocitySynch",1)
			DoWindow/K MasterPanel
			if (V_flag)
				MakePanel("Master")
			endif
			DoWindow/K ForcePanel
			if (V_flag)
				MakePanel("Force")
			endif
			ForceSetVarFunc("ForceScanRateSetVar"+TabStr,GV("ForceScanRate"),"",":Variables:ForceVariablesWave[%ForceScanRate]")
			return 0

		case "Many":					//pull until told to stop
		case "ManyTrigger":
//			if (CheckContinuousTriggeredDwell())
//				DoAlert 0, "We can't do continuous triggered curves with dwell between the force curves at this time."
//				return 1
//			endif
			if (!CanWeGoYet(CtrlName))
				return(0)
			endif
			ARManageRunning("Engage;",0)
			AR_Stop(OKList="FreqFB;DriveFB;Force;PotFB;FMap;PMap;")
			ARManageRunning("Force",1)
			if (GV("ContForce") != 2)		//Not force Map
				ARStatus(1,"Continuous Force Plots Running")
				PV("ContForce",1)			//this means that we will keep pulling
			endif
			PV("ContinuousForceCounter",0)		//reset the counter.
			Switch (GV("MicroscopeID"))
				case cMicroscopeCypher:
				case cMicroscopeInfinity:
					PV("ARCZ",GV("ARCZ") | 0x2)
					Break
					
			endswitch
			HideForceButtons(ctrlName)		//this deals with the buttons
			//stop what is going on now
			ErrorStr += IR_StopInWaveBank(-1)
			ErrorStr += IR_StopOutWaveBank(-1)
			break

		case "Ramp":
		case "Single":				//pull once
		case "SingleTrigger":
			if (!CanWeGoYet(CtrlName))
				return(0)
			elseif (GV("ARDoIVFP") && GV("TriggerChannel"))
				DoIVBias = TheDoIVDAC()
				Struct ARTipHolderParms TipParms
				ARGetTipParms(TipParms)
				if (StringMatch(DoIVBias,"TipHeaterDrive") && !Strlen(TipParms.TipTempXPTName))
					DoAlert 0,"You can not drive the TipHeaterDrive with your tip holder."
					return(0)
				elseif (StringMatch(DoIVBias,"TipBias") && GV("TuneLockin"))
					DoAlert 1,"You can not drive the Tip Bias with the "+GetMicroscopeName()+" lockin yet.\rClick Yes to set the DDS to the ARC."
					Switch (V_Flag)
						case 1:
							TunePanelPopupFunc("TuneLockinPopup_X",1,StringFromList(0,GUS("TuneLockin"),";"))
							break
							
						default:
							return(0)
							break
					endswitch
				endif
			endif
			ARManageRunning("Engage;",0)
			AR_Stop(OKList="FreqFB;DriveFB;Force;PotFB;FMap;PMap;")
			ARManageRunning("Force",1)
			ARStatus(1,"Single Force Plot Running")

			PV("ContForce",0)
			Switch (GV("MicroscopeID"))
				case cMicroscopeCypher:
				case cMicroscopeInfinity:
					PV("ARCZ",GV("ARCZ") | 0x2)
					Break
					
			endswitch
			PV("ContinuousForceCounter",0)		//reset the counter.
			PV("RTForceSkipFactor",1)		//reset so we can retime things.
			HideForceButtons(ctrlName)		//this deals with the buttons
			//stop what is going on now
			ErrorStr += IR_StopInWaveBank(-1)
			ErrorStr += IR_StopOutWaveBank(-1)
			break

		case "StopTrigger":					//stop continuous pulling gracefully
		case "Stop":					//stop continuous pulling gracefully
		
		
			if (ItemsInList(GetRTStackInfo(0),";") <= 1)		//user clicked on button
				if (GV("FMapStatus"))
					Execute/P/Q/Z "DoScanFunc(\"StopScan_4\")"
					return(0)
				endif
			endif
		
			ARManageRunning("Force",0)
			ARStatus(0,"Ready")


			PV("ContForce",0)			//set this to one
			//clear the trigger, pulling will stop after the next one
			ErrorStr += num2str(td_WriteString("Event."+cForceStartEvent,"clear"))+","
			HideForceButtons("Single")		//this deals with the buttons
			ToggleSTM(0)
			return 0					//no need to do more

		case "Reset":					//stop everything now!
		case "ResetTrigger":
			ARManageRunning("Force",0)
			ARStatus(0,"Ready")

			//stop what is going on now
			ErrorStr += IR_StopInWaveBank(-1)
			ErrorStr += IR_StopOutWaveBank(-1)
			ErrorStr += SetLowNoise(0)
			HideForceButtons("Stop")		//reset the buttons
			ErrorStr += num2str(td_WriteString("CTFC.EventEnable","Never"))+","
			ErrorStr += num2str(td_WriteString("OutWave0StatusCallback",""))+","
			ClearEvents()
			ToggleSTM(0)
			return 0					//we are through

//		case "Graph":					//make a graph
//			oldMakeForceGraph()			//this does that
//			return 0

		case "Channel":
			string graphStr = StringFromList(0,WinList("*",";","WIN:64"))	//the panel the button is on should be on top
			MakePanel("ForceChannel")									//make the force channel panel
			AttachPanel("ForceChannelPanel",graphStr)						//stick it to the panel with the just pushed button
			return 0

		case "Save":
			if (!(4 & GV("SaveForce")))
				PV("SaveForce",GV("SaveForce")+4)
			endif
			if (!GV("ContForce"))
				SaveForceFunc()
				ForceRealTimeUpdateOffline()
			endif
			return 0

		case "Go":
			GoToSpot()
			return 0

		case "Clear":
		case "Draw":
		case "Done":
			DrawSpot(ctrlName)
			return 0

		case "Review":
			MakePanel("MasterForce")
			return 0
			
		default:
		
			return 1
			
			
	endswitch

	UpdateInvolsBySum()
	string SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:MFP3D:Force:		//all of the Force waves live in here
	
	UpdateAllControls("StopEngageButton",cEngageButtonTitle,"SimpleEngageButton","SimpleEngageMe",DropEnd=2)
	
	Variable limitValue = GV("MaxContinuousForce")
	if ((numtype(LimitValue) == 0) && GV("ContForce"))
		ARStatusProgBar(1,"Force Plots",LimitValue,0)
	endif
	SwapZDAC(0)		//CTFC can't run the Cypher Z DAC and out waves can't either
	if (CheckYourZ(0))		//if we are engaged, set the Start distance to the Force distance above where we currently are.
		Struct WMButtonAction ButtonStruct
		ButtonStruct.Win = "MasterPanel"
		ButtonStruct.CtrlName = "ForceStartDistButton"+"_2"
		ButtonStruct.EventMod = 2^3
		ButtonStruct.EventCode = 2
		ButtonStruct.UserData = ""
		ARButtonFunc(ButtonStruct)
	endif
	ir_StopPISLoop(NaN,LoopName="HeightLoop")
	ErrorStr += SetLowNoise(1)
	if (!GV("DontChangeXPT"))
		SVAR CurrentXPT = root:Packages:MFP3D:XPT:Current
		SVAR State = root:Packages:MFP3D:XPT:State
		if (GV("ForceCrosspointChange") || !(stringmatch(CurrentXPT,"*Force") && stringmatch(State,"Loaded")))
			//AdjustXPT("Force","Force")
			LoadXPTState("Force")
			//Wave/T AllAlias = root:Packages:MFP3D:Hardware:AllAlias
			//Wave/T XPTLoad = root:Packages:MFP3D:XPT:XPTLoad
			If (GVU("InputRange") && (GV("ImagingMode") == cACMode) && GrepString(ir_ReadALias("Deflection"),"Fast"))
				SetAutoInputRange(1,freeAirAmp=9)
			endif
		endif
	endif
	Variable Error = DoubleCheckInputRange()
	if (Error)
		ForcePlotCleanup()
		return(0)
	endif

	variable rampInterp = 0
	variable startDist, startDistVolts, zLVDTSens = GV("ZLVDTSens")
	
	startDist = GV("StartDist")
	startDistVolts = startDist/GV("ZPiezoSens")
	
	String Callback = ""
	if (StringMatch(CtrlName,"Ramp*"))
		Callback = "ZRampCallback()"
	else
		Callback = non_ramp_callback + "(\""+ctrlName+"\")"
	endif
	
	String RampChannel, TriggerChannel, Event, EventRamp, EventDwell
	Variable TriggerPoint,IsGreater,RampVelocity
	Variable DoTrigger = GV("TriggerChannel")
	Variable ForceDistSign = GV("ForceDistSign")	
	Event = cForceStartEvent
	EventRamp = cForceRampEvent
	EventDwell = cForceDwellEvent
	if (!DoTrigger)
		EventRamp = "Always"
		EventDwell = "Never"
		ir_StopPISLoop(naN,LoopName="DwellLoop")
//		//also clear PISloop1 if it is set to.
//		Wave/T PISLoopWave = root:Packages:MFP3D:Main:PISLoopWave
//		if (StringMatch(PISLoopWave[1][6],"Z%output"))
//			ErrorStr += num2str(ir_stopPISLoop(1))+","
//		endif
		
	endif
		
	Variable IsAbsTrig = GV("TriggerType")
	
	Variable ForceMode = GV("ForceMode")
	
	if (ForceMode)
		startDistVolts = (startDistVolts-70)*GV("ZPiezoSens")/GV("ZLVDTSens")+GV("ZLVDTOffset")
		Struct ARFeedbackStruct FB
		ARGetFeedbackParms(FB,"outputZ")
		FB.StartEvent = EventRamp
		FB.StopEvent = EventDwell
		if (DoTrigger)
			FB.StopEvent += ";"+cFMapStartEvent
		endif
		ErrorStr += ir_WritePIDSloop(FB)
		RampChannel = "$"+FB.LoopName+".Setpoint"//"Setpoint%PISLoop2"
		if (DoTrigger)
			ErrorStr += num2str(td_WriteString("Event."+EventDwell,"Clear"))+","
			ErrorStr += num2str(td_WriteString("Event."+EventRamp,"Set"))+","
		endif
	else
		ir_StopPISLoop(naN,LoopName="outputZLoop")
		ir_StopPISLoop(naN,LoopName="HeightLoop")
		RampChannel = "Output.Z"
	endif
	CheckYourZ(1)

	
	if (ForceMode)
		RampVelocity = 5
	else
		RampVelocity = 50
	endif
	
	if (DoTrigger)
		Struct ARForceChannelStruct ForceChannelParms
		GetForceChannelParms(ForceChannelParms)
		if ((GV("ImagingMode") == cPFMMode) && IsForceChannel(ForceChannelParms,"Frequency") && GV("DualACMode"))
			PV("DFRTOn",1)
			PV("AppendThermalBit",GV("AppendThermalBit") | 2^GetThermalBit("AppendDFRTFreqBox"))
		endif

		Struct ARCTFCParms CTFCParms
		ARGetCTFCParms(CTFCParms)

		CTFCParms.RampDistance[0] = StartDistVolts-td_ReadValue(CTFCParms.RampChannel)
		CTFCParms.RampDistance[1] = 0
	
		CTFCParms.RampRate[0] = RampVelocity*Sign(CTFCParms.RampDistance[0])
		CTFCParms.RampRate[1] = 0
		CTFCParms.DwellTime[0] = 0
		CTFCParms.DwellTime[1] = 0
		CTFCParms.TriggerChannel[1] = "output.Dummy"
		CTFCParms.Callback = Callback
		CTFCParms.RampEvent = EventRamp
		CTFCParms.StartEvent = Event
		CTFCParms.DwellEvent = cForceInitDwellEvent
		if (((CTFCParms.RampDistance[0] < 0) && (ForceDistSign > 0)) || ((CTFCParms.RampDistance[0] > 0) && (ForceDistSign < 0)))
			CTFCParms.TriggerChannel[0] = "output.Dummy"
		endif
		ErrorStr += ir_WriteCTFC(CTFCParms)
		ErrorStr += num2str(TD_WriteString("Event."+event,"once"))+","
	else	
		
		ErrorStr += num2str(td_SetRamp(4,RampChannel,RampVelocity,startDistVolts,"",0,0,"",0,0,Callback))+","
	endif
	PV("ZStateChanged",0)
	
	ARReportError(ErrorStr)
	SetDataFolder(SavedDataFolder)
End Function //DoForceFunc




function prh_FinishForceFunc(ctrlName,[callback_string])			//this finishes off the Force
	string ctrlName,callback_string
	if (ParamIsDefault(callback_string))
		callback_string = "TriggerScale()"	
	EndIf
	//Override List (list of ipfs that can override this function)
	//ForceReiviewDemo

	string SavedDataFolder = GetDataFolder(1)
	SetDataFolder root:Packages:MFP3D:Force:		//all of the Force waves live in here
															//make all of the waves	
	if (GV("ZStateChanged"))
		DoForceFunc(ctrlName+"Force")
		SetDataFolder(SavedDataFolder)
		return 1
	endif


	//just read these things, to clear the <edit> built up in there.
	td_ReadString("Head.Temperature")
	td_ReadString("Scanner.Temperature")


	variable sampleRate = GV("NumPtsPerSec")
	Variable ForceScanRate = GV("ForceScanRate")
	variable forceDecimation = GV("ForceDecimation")
	Variable StartDist = GV("StartDist")
	variable displayPoints = round(sampleRate/ForceScanRate)		//you MUST round this or there will be trouble, MBV
	variable test, inputPoints, dwellTime = 0, inputDwellPoints = 0, displayDwellPoints = 0, drivePoints = 0
	Variable InputDwellPoints0, InputDwellPoints1
	variable useDwellRate = GV("UseDwellRate")
	variable dwellRate = GV("DwellRate")
	variable triggerChannel = GV("TriggerChannel")
	variable dwellSetting = GV("DwellSetting")
	Variable DoIndent = GV("IndentMode")
	Variable DoIV = GV("ARDoIVFP")
	Variable IndentMode = GV("DwellRampMode")
	Variable ForceDistSign = GV("ForceDistSign")
	variable zPiezoSens = GV("ZPiezoSens")
	variable zLVDTSens = GV("ZLVDTSens")
	variable forceDist = GV("ForceDist")
	variable ratio = .5
//	variable PGain = GV("ProportionalGain")/10		//grab the gains
//	variable IGain = GV("IntegralGain")*100
//	variable SGain = GV("SecretGain")/1e+12
	variable zLVDTOffset = GV("ZLVDTOffset")
//	Variable Scale		//to scale the trigger point
	Variable TriggerPoint, IsGreater, TriggerTime
	Variable ForceMode = GV("ForceMode")
	variable dualACMode = GV("DualACMode")
	Variable RampVelocity, ForceDistVolts, StartDistVolts
	Variable i, Divisor
	Variable approachVelocity, retractVelocity
//	Variable Factor		//used for Virtual deflection scaling.
	Variable TrigAtStart
	Variable CurrentPos, GetOut//, ZScale
	Variable FMapStatus = GV("FMapStatus")
	Variable DisplayXYLVDT = GV("FMapDisplayLVDTTraces")*FMapStatus
	Variable ImagingMode = GV("ImagingMode")
	Variable IsAbsTrig = GV("TriggerType")
	String DataFolder = GetDF("Force")

	String TriggerStr = ""
	String ErrorStr = ""
	String tempSeconds = ""
	String RampChannel = ""
	Variable A, nop
	Struct ARCTFCParms CTFCParmStruct
	Wave/T CTFCParms = InitOrDefaultTextWave("CTFCParms",0)

	
	if (GV("VelocitySynch") == 0)
		ratio = GV("RetractVelocity")/(GV("ApproachVelocity")+GV("RetractVelocity"))
	endif

	if (ForceMode)
		RampChannel = "$OutputZLoop.Setpoint"
	else
		RampChannel = "Output.Z"
	endif

	if (triggerChannel)
		triggerStr = GetTriggerString()
//		scale = GetTriggerScale()
		ForceDistVolts = -ForceDist/zPiezoSens
		StartDistVolts = StartDist/ZPiezoSens
		RampVelocity = 50
		
		//well then we must have done a triggered ramp.
		//to get in here the first time
		//so we read back that to make sure we are working with the correct values.
		//technically I think I can just use the wave send down from CTFCRamp
		//I should probably just read that wave instead of asking the controller.
		ErrorStr += Num2str(td_ReadGroup("CTFC",CTFCParms))+","
		
		//Nope, we can't do that.
		//Say they engage on the surface with a relative trigger.
		//The Trigger Ramp sets a poor trigger point
		//so we need to recalc the trigger point after they get to start position
		StrSwitch (TriggerStr)
			Case "Indent"://"LinearCombo.Output":
				IsAbsTrig = 1
				break
				
		endswitch
		
		TriggerPoint = str2num(CTFCParms[%TriggerPoint1])
		TriggerTime = str2num(CTFCParms[%TriggerTime1])
		

//		if (IsAbsTrig)
//			TriggerPoint = GV("TriggerPoint")/Scale
//		else
//			if (stringmatch(StringFromList(TriggerChannel,ActiveForceList()),"AmpPercent"))
//				triggerPoint = limit(td_ReadValue(TriggerStr)*GV("TriggerPoint")/100,.1,9.5/10^(GV("ADCgain")/20))
//			else
//				triggerPoint = limit(td_ReadValue(TriggerStr)*scale+GV("TriggerPoint"),GVL("TriggerPoint")/2,GVH("TriggerPoint")/2)/scale
//			endif
//		endif
		
		//TriggerPoint = str2num(CTFCParms[%TriggerValue1][0])
		IsGreater = WhichListItem(CTFCParms[%TriggerCompare1][0],"<=;>=;",";",0,0)*2-1
		//IsGreater does not change between ramp and force plot.
		//ZScale = ZPiezoSens
		
		if (ForceMode)
			//ForceDistVolts *= zPiezoSens/ZLVDTSens
			StartDistVolts = startDistVolts*zPiezoSens/ZLVDTSens+zLVDTOffset
			RampVelocity = 5
			//ZScale = ZLVDTSens
		endif

		
		TrigAtStart = 0
		if (TriggerTime && (TriggerTime < 4e5))
			if (IsGreater > 0)
				if (TriggerPoint <= td_ReadValue(TriggerStr))
					TrigAtStart = 1
				endif
			else
				if (TriggerPoint >= td_ReadValue(triggerStr))
					TrigAtStart = 1
				endif
			endif
		endif
		

		if (TrigAtStart)
			CurrentPos = td_ReadValue("Height")
			GetOut = 0
			if (!ForceMode)
				if ((CurrentPos+StartDistVolts)*ZPiezoSens < GVL("StartDist"))
					GetOut = 1
				endif
			else
				CurrentPos = (td_ReadValue("ZSensor")*ZLVDTSens/ZPiezoSens+70)
				if (CurrentPos < GVL("StartDist"))
				//bacically we trigger before we get to the "start" of the closed loop force plot range.
					GetOut = 1
				endif
			endif
			
			SetDataFolder(SavedDataFolder)		//either way we are done, set the folder
			if (GetOut)
				Print "Ran out of Z Range, Either move the tip up, or fix your trigger point"
				DoWindow/H
				ForcePlotCleanup()
//				HideForceButtons("Stop")
//				ForceSetVarFunc("StartDistSetVarFunc_2",CurrentPos*ZPiezoSens,"",":Variables:ForceVariablesWave[%StartDist]")
//				PV("FMapStatus",0)
//				SetLowNoise(0)
//				GhostForceMapPanel()
				//maybe this should call ForcePlotCleanup...
			else			
				//Ramp back ForceDist
				if (ForceMode)
					CurrentPos = td_ReadValue(RampChannel)
				endif
				ErrorStr += num2str(td_SetRamp(4,RampChannel,RampVelocity,CurrentPos+ForceDistVolts,"",0,0, "",0,0,GetFuncName()+"(\""+CtrlName+"\")"))+","
			endif					
			ARReportError(ErrorStr)
			return(0)
		endif
		
		//************************************************************************************************************
		//This code gets 99% of the CTFC setup.
		if (ARGetCTFCParms(CTFCParmStruct))
			return(0)		//there was a failure setting up the CTFC.
			//the user has been warned, we have to get out.
		endif
		CTFCParmStruct.Callback = callback_string
		//************************************************************************************************************
		
	endif	

	variable dwellPoints0, dwellPoints1, ramp, rampPoints0, rampPoints1, dwellPointsInput0, dwellPointsInput1, dwellTime0, dwellTime1


	
	if ((DoIndent || DoIV) && triggerChannel)
		
		useDwellRate = 0
		DwellRate = SampleRate
		DwellSetting = DwellSetting | ((ForceDistSign == -1) + 1)
		
		
	elseif (DwellSetting)
	elseif (FMapStatus)
		useDwellRate = 0
	endif
	if (TriggerChannel)
		DwellTime0 = CTFCParmStruct.DwellTime[0]
		DwellTime1 = CTFCParmStruct.DwellTime[1]
	elseif ((DwellSetting & 0x3) == 0x3)
		DwellTime0 = GV("DwellTime")
		DwellTime1 = GV("DwellTime1")
	elseif (((DwellSetting == 1) && (ForceDistSign > 0)) || ((DwellSetting == 2) && (ForceDistSign < 0)))
		dwellTime0 = GV("DwellTime")
		dwellTime1 = 0
	elseif (DwellSetting)
		dwellTime0 = 0
		dwellTime1 = GV("DwellTime")
	endif

	DwellTime = DwellTime0+DwellTime1
	inputDwellPoints = round(sampleRate*DwellTime)
	inputDwellPoints0 = Round(SampleRate*DwellTime0)
	InputDwellPoints1 = Round(SampleRate*DwellTime1)
	drivePoints = DisplayPoints+inputDwellPoints
	inputPoints = DrivePoints*2*forceDecimation


	if (!useDwellRate)
		dwellRate = sampleRate
	endif
	dwellPoints0 = round(dwellTime0*dwellRate)
	dwellPoints1 = round(dwellTime1*dwellRate)
	dwellPointsInput0 = round(dwellTime0*sampleRate)
	dwellPointsInput1 = round(dwellTime1*sampleRate)
	ramp = round(displayPoints)			//the dwell hasn't been added in yet to displayPoints
	rampPoints0 = round(ramp*ratio)
	rampPoints1 = round(ramp*(1-ratio))
	displayPoints += dwellPoints0+dwellPoints1
	
	i = Max(ceil(log(displayPoints/4096)/Log(2)),0)
	i = max(Ceil(log(DrivePoints/86000)/Log(2)),i)

	divisor = 2^i

	if (triggerChannel)
		if (GV("VelocitySynch"))
			approachVelocity = GV("Velocity")
			retractVelocity = approachVelocity
		else
			approachVelocity = GV("ApproachVelocity")
			retractVelocity = GV("RetractVelocity")
		endif
		
		inputPoints = round(sampleRate*(150*ZPiezoSens-StartDist)/approachVelocity+sampleRate*ForceDist/retractVelocity+inputDwellPoints+sampleRate)
		inputPoints *= forceDecimation
	endif

	inputPoints -= mod(inputPoints,32)
	PV("InputTime",inputPoints/sampleRate/forceDecimation)

	Wave TimeWave = $DataFolder+"TimeWave"
	SetScale d,0,0,"s",TimeWave
	Wave MarkerNumWave = $DataFolder+"MarkerNumWave"
	Wave RealDrive = $DataFolder+"RealDrive"
	Wave Setpoint = $DataFolder+"Setpoint"
//	Wave DriveVolts = $DataFolder+"DriveVolts"
	Wave RawZSensor = $DataFolder+"RawZSensor"
	Redimension/N=(drivePoints/divisor) RealDrive, Setpoint

	if (!triggerChannel)	//if triggered then we have no idea what size to use, so it is done in TriggerScale()
		Redimension/N=(displayPoints) MarkerNumWave, TimeWave

	//this calc is in FinishForceFunc, TriggerScale and RTForceWriteFunc
		TimeWave[0,rampPoints0-1] = p/sampleRate
		TimeWave[rampPoints0,rampPoints0+dwellPoints0-1] = rampPoints0/sampleRate+(p-rampPoints0)/dwellRate
		TimeWave[rampPoints0+dwellPoints0,rampPoints0+dwellPoints0+rampPoints1-1] = rampPoints0/sampleRate+dwellTime0+(p-(rampPoints0+dwellPoints0))/sampleRate
		if ((displayPoints-1) >= (rampPoints0+dwellPoints0+rampPoints1))
			TimeWave[rampPoints0+dwellPoints0+rampPoints1,displayPoints-1] = (rampPoints0+rampPoints1)/sampleRate+dwellTime0+(p-(rampPoints0+dwellPoints0+rampPoints1))/dwellRate
		endif
		if (ForceMode)
			MakeSetpointDrive(Setpoint,startDist,forceDist,forceDistSign,zLVDTSens,ratio,inputDwellPoints0/divisor,inputDwellPoints1/divisor)					//this makes the drive wave
			Setpoint += zLVDTOffset
			ErrorStr += ir_xSetOutWave(0,cForceStartEvent+","+cForceStartEvent,RampChannel,Setpoint,Num2char(7),ARGetDeci(SampleRate/Divisor))
			CopyScales/P Setpoint RealDrive
		else
			MakeDrive(RealDrive,startDist,forceDist,forceDistSign,zPiezoSens,ratio,inputDwellPoints0/divisor,InputDwellPoints1/Divisor)
			ErrorStr += IR_xSetOutWave(0,cForceStartEvent+","+cForceStartEvent,RampChannel,RealDrive,Num2char(7),ARGetDeci(-SampleRate/Divisor))
		endif
	else
		Variable PPS = cMasterSampleRate/ARGetDeci(SampleRate/Divisor)
		SetScale/P x,0,1/PPS,"s",RealDrive
		ErrorStr += IR_StopOutWaveBank(0)
	endif
	

	

//************************************************************************************************************************************************************************************************
//																Data Channel Loop.
//************************************************************************************************************************************************************************************************

	Struct ARForceChannelStruct ForceChannelParms
	GetForceChannelParms(ForceChannelParms)
	variable stop, DeltaTime, HaveChannel
	wave/T ForceChannels = root:Packages:MFP3D:Force:ForceChannels
	String ParmName, DataList, Units
	Struct ARDataTypeInfo DataTypeParms
	DataTypeParms.GraphStr = "RealTime"
	stop = FindDimLabel(ForceChannels,0,"UserCalc")
	DeltaTime = DimDelta(RealDrive,0)/divisor
	Variable DontHaveSize = 200		//Make this a bit more different than the stock 2016, so it is more obvious when there is an error
	
	for (i = 0;i < stop;i += 1)
		ParmName = GetDimLabel(ForceChannels,0,i)
		wave InputWave = InitOrDefaultWave(DataFolder+"Input"+ParmName,0)
		Wave FilteredWave = InitOrDefaultWave(DataFolder+"Filtered"+ParmName,0)
		Wave DisplayWave = InitOrDefaultWave(DataFolder+ParmName,0)
		nop = ItemsInList(ForceChannels[i][0],";")
		Units = Get3DScaling(ParmName,InfoStruct=DataTypeParms)
		HaveChannel = IsForceChannel(ForceChannelParms,ParmName)		//IsForceChannel works
		//HaveChannel = WhichListItem(ParmName,ForceChannelParms.FullDataList,";",0,0) >= 0	//this does not, FullDataList is funky if the channel is displayed but not saved
		if (HaveChannel)
			if (!triggerChannel)
				Redimension/N=(displayPoints) DisplayWave
//				Redimension/N=(rampPoints0+rampPoints1+dwellPointsInput0+dwellPointsInput1) FilteredWave
				Redimension/N=(inputPoints/2) FilteredWave
			endif
			Redimension/N=(inputPoints) InputWave
		else
			Redimension/N=(DontHaveSize) DisplayWave
			Redimension/N=(DontHaveSize) FilteredWave
			Redimension/N=(DontHaveSize*2) InputWave
		endif
		SetScale/P x,0,DeltaTime,"s",DisplayWave
		SetScale d,0,0,units,DisplayWave


			
		for (A = 0;A < nop;A += 1)
			Wave/Z DisplayWave = $DataFolder+StringFromList(A,ForceChannels[i][0],";")
			if (!WaveExists(DisplayWave))
				continue
			endif
			Units = Get3DScaling(NameOfWave(DisplayWave),InfoStruct=DataTypeParms)
			SetScale/P x,0,DeltaTime,"s",DisplayWave
			SetScale d,0,0,units,DisplayWave
			if (!TriggerChannel && HaveChannel)
				Redimension/N=(displayPoints) DisplayWave
			elseif (!HaveChannel)
				Redimension/N=(DontHaveSize) DisplayWave
			endif
			
		endfor
		
	endfor
	Wave UserCalc = $DataFolder+"UserCalc"
	if (WhichListItem("UserCalc",ForceChannelParms.FullDataList,";",0,0) >= 0)
		if (!TriggerChannel)
			Redimension/N=(DisplayPoints) UserCalc
		else
			Redimension/N=(inputPoints) UserCalc
		endif
	else
		Redimension/N=(DontHaveSize) UserCalc
	endif
	Wave UserCalcB = $DataFolder+"UserCalcB"
	if (WhichListItem("UserCalcB",ForceChannelParms.FullDataList,";",0,0) >= 0)
		if (!TriggerChannel)
			Redimension/N=(DisplayPoints) UserCalcB
		else
			Redimension/N=(inputPoints) UserCalcB
		endif
	else
		Redimension/N=(DontHaveSize) UserCalcB
	endif
		

//************************************************************************************************************************************************************************************************
//															End Data Channel Loop.
//************************************************************************************************************************************************************************************************



	Wave SaveWave = MakeSaveWave()					//this makes the wave used for saves to disk

	String NoteStr = ARNoteFunc(RawZSensor,"ForcePlot")
	
	if (FMapStatus)
		Variable XScanSize, YScanSize, D
		Struct ARFMapParms Parms
		GetARFMapParms(Parms)		//this structure is used elsewhere in this function
		Struct ARFMapImageData ImageStruct
		ImageStruct.Init(ImageStruct)
		ARFMap_SetHeader(ImageStruct.FileRef,"",NoteStr)		//Force Note
		Wave ImageStruct.ImageWave = InitFMapImage()
		ImageStruct.DataType = GetDimLabels(ImageStruct.ImageWave,2)
		
		//these 2 lines  will proabably be in a loop
		ImageStruct.SetData(ImageStruct)
		//UpdateImageCalcList(ImageWave,FuncName,Layer)
		ARFMap_SetHeader(ImageStruct.FileRef,"Image0",Note(ImageStruct.ImageWave))		//This will need adjustment when Bill finalizes
		Struct ARFMapDimData DimData
		DimData.Init(DimData)

		XScanSize = Parms.ScanSize/Max(1/Parms.ScanRatio,1)		//Max(1/Parms.ScanRatio,1) is SlowRatio, since we know one of the values has to be 1
		YScanSize = Parms.ScanSize/Max(Parms.ScanRatio,1)		//Max(Parms.ScanRatio,1) is FastRatio, since we know one of the values has to be 1

		Struct ARFMapRegionParms FMapRegionParms
		FMapRegionParms.Init(FMapRegionParms)

		DimData.NumPoints = Parms.nopX
		DimData.StartPoint = 0
		DimData.Delta = XScanSize/(DimData.NumPoints-1)
		DimData.Units = "m"
		FMapRegionParms.DimData[0] = DimData
		
		DimData.NumPoints = Parms.nopY
		DimData.StartPoint = 0
		DimData.Delta = YScanSize/(DimData.NumPoints-1)
		DimData.Units = "m"
		FMapRegionParms.DimData[1] = DimData

		DimData.NumPoints = 0
		DimData.StartPoint = 0
		DimData.Delta = 1/SampleRate
		DimData.Units = "s"
		FMapRegionParms.DimData[2] = DimData
		FMapRegionParms.DimData[3] = DimData		//just in case, this dim does not mean anything, but I do this much, much as well fill them all in.
		
		
		FMapRegionParms.NumOfDims = 3
		FMapRegionParms.NumberOfDataSets = -1
		FMapRegionParms.ChannelList = GetDimLabels(SaveWave,1)
		FMapRegionParms.DataUnitsList = ""
		Wave DataTypeParms.DataWave = RawZSensor		//I think that now that we have the note, we can work in offline mode
		DataTypeParms.GraphStr = ""
		for (D = 0;D < Dimsize(SaveWave,1);D += 1)
			FMapRegionParms.DataUnitsList += Get3DScaling(StringFromList(D,FMapRegionParms.ChannelList,";"),InfoStruct=DataTypeParms)+";"
		endfor
		FMapRegionParms.SparseChannels = 0
		FMapRegionParms.SegmentList = GetDirectionList(DwellTime0,DwellTime1,FMapStatus,ForceDistSign,StringByKey("DwellRampFunc",NoteStr,":","\r",0),DoIndent)
		FMapRegionParms.ExtraParmNameList = cExtraParmList
		
		ARFMap_InitForceRegion(FMapRegionParms)
		ErrorStr += DAMSetup("FMap")
	else
		ErrorStr += DAMSetup("Force")
	endif
	
	wave DetrendParm = root:Packages:MFP3D:Force:DetrendParm
	wave OldDetrendParm = root:Packages:MFP3D:Force:OldDetrendParm

	OldDetrendParm = DetrendParm
	PV("LastUsedVirtDeflSlope",GV("VirtDeflSlope"))
	PV("LastUsedVirtDeflOffset",GV("VirtDeflOffset"))

	if (!GV("ForceFilter"))		//check to see if the filter panel is in charge
		SetForceBandwidth(GV("ForceFilterBW"))
	endif
	ErrorStr += num2str(td_WriteString("Event."+cForceStartEvent,"Clear"))+","
	

	Make/O/B/N=(displayPoints) ColorWave			//this is fine as 8bit integer
	Struct ARFeedbackStruct FB
	variable contForce = GV("ContForce")
	Variable NumOfCustomDrive = 0
	if (triggerChannel)
		//ErrorStr += IR_StopOutWaveBank(0)

		
		//td_NewSetSTFC("0", distApproach, distRetract, slopeApproach, slopeRetract,triggerStr,TriggerPoint,IsGreater,"TriggerScale()")
		
		ir_WriteCTFC(CTFCParmStruct)
		PV("UpdateTrigger",0)
		variable dFRTOn = GV("DFRTOn")
		Variable WhichLoop
		if (!ForceMode)
			WhichLoop = 2		//use the Z loop for the dwells.
		else
			WhichLoop = 5
		endif
		if (DwellTime)
			
			SetupIndenting("Check")
			Switch (IndentMode)
				case 0:
					ARGetFeedbackParms(FB,"Height",ImagingMode=cContactMode)
					break
					
//				case 2:		//indenting
//					ARGetFeedbackParms(FB,"Height",ImagingMode=cContactMode)
//					FB.Input = "LinearCombo.Output"
//					break
//				
				case 1:
					//break
					
				case 2:
				default:
					ARGetFeedbackParms(FB,"ZSensor")
					FB.PGain = 0
					FB.IGain = 10^(GV("ZIGain")-.5)
					FB.SGain = 0
					if (IndentMode == 2)
						FB.Input = "Indent"
						//FB.Input = "LinearCombo.Output"
					endif
					break
					
			endswitch
			FB.Bank = WhichLoop
			
			FB.StartEvent = cForceDwellEvent
			if (!DFRTon && !DwellTime0 && DwellTime1)		//we are not doing fancy Dart loops, and we are only doing the second dwell
				FB.StartEvent = cFMapStartEvent
			elseif ((IndentMode == 1) && !DFRTOn && DwellTime0 && DwellTime1 && !DoIndent && !DoIV)		//if we are not doing a ramped dwell
				//and we have Z loop setup
				//and we have both dwells on (mostly Fmaps with dwell)
				//and we are not doing special loops
				//then this loop can run for both dwells
				FB.StartEvent += ";"+cFMapStartEvent
			endif
			FB.StopEvent = cForceRampEvent
			FB.Setpoint = NaN
			FB.DynamicSetpoint = 1
			FB.LoopName = "DwellLoop"
			ErrorStr += ir_WritePIDSloop(FB)

			if (dFRTOn)
				Wave FeedbackCoef = root:Packages:MFP3D:Main:FeedbackCoef
				FeedbackCoef = {0,-1,1}
				
//				wave/T DynamicAlias = $GetDF("Alias")+"DynamicAlias"
//				DynamicAlias[%Frequency][0] = "$DDSFrequency0"//td_ReadString("Alias:DDSFrequency0")//"Lockin.0.Freq"
//				WriteAllAliases()
				errorStr += ir_WriteValue("DDSFrequencyOffset0",0)
				errorStr += ir_WriteValue("DDSFrequencyOffset1",0)
				ErrorStr += ir_SetLinearCombo("DartAmp","Amplitude1",FeedbackCoef,"Amplitude")
				//errorStr += num2str(td_SetLinearCombo("Amplitude1",root:Packages:MFP3D:Main:FeedbackCoef,"Amplitude"))+","
				
				ARGetFeedbackParms(FB,"Drive",ImagingMode=cPFMMode)		//PFM
				FB.StartEvent = cForceDwellEvent
				FB.StopEvent = cForceRampEvent
				if (ContForce)
					FB.StopEvent = "Never"
				endif
				ErrorStr += IR_WritePIDSloop(FB)
				
				ARGetFeedbackParms(FB,"Frequency",ImagingMode=cPFMMode)		//PFM
				FB.StartEvent = cForceDwellEvent
				FB.StopEvent = cForceRampEvent
				ErrorStr += IR_WritePIDSloop(FB)
			endif
			NumOfCustomDrive = ARSetupCustomDwellDrive()		//sets up additional drive waves
			//for indent and DoIV.  can add user outputs in the future.
			
		endif
	else
		DoColorWave(ColorWave,displayPoints-(dwellPoints0+dwellPoints1),dwellPoints0,ForceDistSign,DwellSetting,ratio)
//		CopyScales RawLVDT SmallLVDT
//		FastOp Drive = (zPiezoSens)*DriveVolts				//calculate a metric version of the DriveVolts for display purposes
	endif


	variable total = 0
	String DoIVBias = TheDoIVDAC()
	string channelList = "Deflection;Amplitude;Phase;"+ListMultiply("UserIn",MakeValueStringList(cMaxRealTimeUserChannels-1,0),";")+";Lateral;Frequency;Dissipation;Current;Current2;Count;Count2;InputI;InputQ;Bias;Drive;Potential;TipHeaterDrive;TipHeaterPower;TipTemperature;"//blueThermPower;"//ZThermResistivity;"
	
	if (dualACMode)
		ChannelList = ReplaceString(";Amplitude;",ChannelList,";Amplitude1;Amplitude2;")
		ChannelList = ReplaceString(";Phase;",ChannelList,";Phase1;Phase2;")
	endif
	ChannelList += ListMultiply("BackPackIn",MakeValueStringList(MaxRTBackPackChannels()-1,0),";")

	

	String SelectedChannelList = "", DataWaveList = "", ChannelName, WaveStr = "", DisplayList = "", aliasList = "", aliasName
//	string chan1Str = "", chan2Str = "", chan3Str = "", chan4Str = "", chanStr = "", waveStr = ""
	wave/T XPTCurrent = root:Packages:MFP3D:XPT:XPTCurrent
	Variable haveDeflection, Index

	String DisplayStr = ""

	String Force32BitChannel = "ZSensor"//GTS("Force32BitChannel")


	for (i = 0;i < ItemsInList(channelList);i += 1)
		
		channelName = StringFromList(i,channelList,";")
		if (!IsForceChannel(ForceChannelParms,channelName))
			Continue
		endif
		AliasName = LongChannel2Alias(ChannelName)
		strswitch (channelName)
			
			case "Deflection":
				waveStr = "DeflVolts"
				DisplayStr = "DeflVolts;Deflection;Force;"
				break
				
			case "Amplitude":
				waveStr = "AmpVolts"
				DisplayStr = "Amplitude;AmpVolts;"
				break
			
			case "Amplitude1":
				waveStr = "Amp1Volts"
				DisplayStr = "Amplitude1;Amp1Volts;"
				break

			case "Amplitude2":
				waveStr = "Amp2Volts"
				DisplayStr = "Amplitude2;Amp2Volts;"
				break

			case "Frequency":
				waveStr = channelName
				Switch (ImagingMode)
					case cACMode:
					case cFMMode:
					case cACFastMapMode:
						if (!GV("FreqGainOn"))
							FMCheckBoxFunc("FreqGainOnBox_0",1)
						endif
						break

				endswitch
				DisplayStr = channelName+";"
				break
				
			case "Dissipation":
				waveStr = channelName
				If (!GV("DriveGainOn"))
					FMCheckBoxFunc("DriveGainOnBox_0",1)
				endif
				DisplayStr = channelName+";"
				break
				
			case "Potential":
				waveStr = channelName
				ElectricBoxFunc("PotentialGainOnBox",3)
				DisplayStr = channelName+";"
				break
				
			case "Count2":
				ErrorStr += CountCheck(ChannelName)
				//Dont Break
			case "TipHeaterDrive":
			case "Phase":						//Single unit data types, only volts or no volts.
			case "Phase1":
			case "Phase2":
			case "Count":
			case "Count0":
			case "Count1":
			case "InputI":
			case "InputQ":
			case "Bias":
				wavestr = channelName
				DisplayStr = channelName+";"
				break
			
			case "ZThermResistivity":
				//Placeholder
				break
				
			case "blueThermPower":	
			case "TipHeaterPower":		//special in that we don't ever show the volts version
			case "Current":
			case "Current2":
				wavestr = channelName
				DisplayStr = channelName+";"
				WaveStr += "Volts"
				break

			case "TipTemperature":
			case "UserIn0":					//Volts and scaled data types.
			case "UserIn1":
			case "UserIn2":
			case "UserIn2":
			case "UserIn3":
			case "UserIn4":
			case "UserIn5":
			case "UserIn6":
			case "UserIn7":
			case "UserIn8":
			case "UserIn9":
			case "BackPackIn0":					//Volts and scaled data types.
			case "BackPackIn1":
			case "BackPackIn2":
			case "BackPackIn2":
			case "BackPackIn3":
			case "BackPackIn4":
			case "BackPackIn5":					//Volts and scaled data types.
			case "BackPackIn6":
			case "BackPackIn7":
			case "BackPackIn8":
			case "BackPackIn9":
			case "Lateral":
			case "Drive":
			default:
				waveStr = channelName
				DisplayStr = WaveStr+";"+WaveStr+"Volts;"
				WaveStr += "Volts"
				break
			

		endswitch
		
		waveStr = "Input"+waveStr
		
		SelectedChannelList += ChannelName+";"
//		ADCList += ChanStr+";"
		DataWaveList += WaveStr+";"
		aliasList += aliasName+";"
		Total += 1
		DisplayList += DisplayStr+","
		
			
		
	endfor
	

	variable decimation = ARGetDeci(SampleRate)/ForceDecimation

	Variable FirstBank = 0
	Variable SecondBank = 1
	Variable LVDTBank = 0		//the bank the XY LVDTs will be on.

	if ((Total > (fARNumOfChannels(ModeStr="Image")-2)) && DisplayXYLVDT)
		DoAlert 0,"You can not ask for more than "+num2str(fARNumOfChannels(ModeStr="Image")-2)+" channels And display The XYLVDT\rSo I just turned off the Display LVDT for you"
		FMapBoxFunc("FMapDisplayLVDTTracesBox_4",0)
		DisplayXYLVDT = 0
	elseif (DisplayXYLVDT)		//we will be displaying the XY LVDT
		//Get our waves.
		//Figure out our decimation.
		Wave DistWave = InitOrDefaultWave(Parms.DataFolder+"DistWave",0)
		Redimension/N=(DimSize(Parms.XPoints,0)-1) DistWave
		if (Parms.XYClosedLoop)
			DistWave = sqrt(((Parms.XPoints[P+1]-Parms.XPoints[P])*abs(Parms.XLVDTSens))^2+((Parms.YPoints[P+1]-Parms.YPoints[P])*abs(Parms.YLVDTSens))^2)
		else
			DistWave = sqrt(((Parms.XPoints[P+1]-Parms.XPoints[P])*Parms.XPiezoSens)^2+((Parms.YPoints[P+1]-Parms.YPoints[P])*Parms.YPiezoSens)^2)
		endif
		Variable MaxTime = WaveMax(DistWave)/Parms.ScanSpeed
		MaxTime = Max(MaxTime,30e-3)		//at least collect 10 ms
		Variable LVDTnop = MaxTime*sampleRate
		LVDTNop += (32-mod(LVDTnop,32))*(!!mod(LVDTnop,32))
		Variable LVDTDeci = ARGetDeci(LVDTNop/MaxTime)
		LVDTNop = round(cMasterSampleRate*MaxTime/LVDTDeci)
		LVDTNop += (32-mod(LVDTnop,32))*(!!mod(LVDTnop,32))
		Wave XLVDTWave = InitOrDefaultWave(Parms.DataFolder+"XLVDTWave",0)
		Wave YLVDTWave = InitOrDefaultWave(Parms.DataFolder+"YLVDTWave",0)
		Redimension/N=(LVDTNop) XLVDTWave, YLVDTWave
		
		
		ErrorStr += IR_XSetInWavePair(LVDTBank,cFMapStartEvent+","+cFMapStartEvent,"XSensor",XLVDTWave,"YSensor",YLVDTWave,"FMapLVDTDisplayCallback()",LVDTDeci)
	
	endif

	String EventStr = cForceStartEvent
	if ((stringmatch(ctrlName,"Many")))// || TriggerChannel)
		EventStr += ","+cForceKeepGoingEvent
	endif
	
	String Force32ADC = selectstring(GV("IsBipolar"), "ZSensor", "Height") 	//no Z%Input for open loop scanner
	String Data32WaveStr = "InputZSensorVolts"
	String Display32 = "ZSensorVolts;RawZSensor;ZSensor;"
	//AdjustforceChannels(Force32BitChannel,Force32ADC,Data32WaveStr,SelectedChannelList,ADCList,DataWaveList)
	//AdjustforceChannels(Force32BitChannel,Force32ADC,Data32WaveStr,Display32,SelectedChannelList,aliasList,DataWaveList,DisplayList)

	switch (total)
		case 1:
			Wave Data0 = $StringFromList(0,DataWaveList,";")
			FixDecimation(StringFromList(0,aliasList,";"),"",Decimation)
			ErrorStr += IR_XSetInWave(SecondBank,EventStr,StringFromList(0,aliasList,";"),Data0,"",decimation)
			SetupRTForceUpdate2(StringFromList(0,DisplayList,","),Data0,-1)

			break

		case 3:
			Wave Data0 = $StringFromList(2,DataWaveList,";")
			FixDecimation(StringFromList(2,aliasList,";"),"",Decimation)
			ErrorStr += IR_XSetInWave(FirstBank,EventStr,StringFromList(2,aliasList,";"),Data0,"",decimation)
			SetupRTForceUpdate2(StringFromList(2,DisplayList,","),Data0,-1)
			//Dont break
		case 2:
			Wave Data0 = $StringFromList(0,DataWaveList,";")
			Wave Data1 = $StringFromList(1,DataWaveList,";")
			FixDecimation(StringFromList(0,aliasList,";"),StringFromList(1,aliasList,";"),Decimation)
			ErrorStr += IR_XSetInWavePair(SecondBank,EventStr,StringFromList(0,aliasList,";"),Data0,StringFromList(1,aliasList,";"),Data1,"",decimation)
			SetupRTForceUpdate2(StringFromList(0,DisplayList,","),Data0,-1+(Total==3)*2)
			SetupRTForceUpdate2(StringFromList(1,DisplayList,","),Data1,1)
			break
	
		case 5:
		case 4:
			Wave Data0 = $StringFromList(0,DataWaveList,";")
			Wave Data1 = $StringFromList(1,DataWaveList,";")
			FixDecimation(StringFromList(0,aliasList,";"),StringFromList(1,aliasList,";"),Decimation)
			ErrorStr += IR_XSetInWavePair(SecondBank,EventStr,StringFromList(0,aliasList,";"),Data0,StringFromList(1,aliasList,";"),Data1,"",decimation)
			SetupRTForceUpdate2(StringFromList(0,DisplayList,","),Data0,-1)
			SetupRTForceUpdate2(StringFromList(1,DisplayList,","),Data1,1)
			
			Wave Data0 = $StringFromList(2,DataWaveList,";")
			Wave Data1 = $StringFromList(3,DataWaveList,";")
			FixDecimation(StringFromList(2,aliasList,";"),StringFromList(3,aliasList,";"),Decimation)
			ErrorStr += IR_XSetInWavePair(FirstBank,EventStr,StringFromList(2,aliasList,";"),Data0,StringFromList(3,aliasList,";"),Data1,"",decimation)
			SetupRTForceUpdate2(StringFromList(3,DisplayList,","),Data1,1)
			SetupRTForceUpdate2(StringFromList(2,DisplayList,","),Data0,1)
			break
			
	endswitch
	
	string Callback, driveAmpStr = "Amplitude*;Phase*;InputI;InputQ;Frequency;Dissipation;"
	variable stopDrive = 1
	stop = ItemsInList(driveAmpStr)
	for (i = 0;i < stop;i += 1)
		if (GrepString(selectedChannelList,StringFromList(i,driveAmpStr)))
			stopDrive = 0
			Break
		endif
	endfor
	if (stopDrive)
		errorStr += ir_WriteValue("DDSAmplitude0",0)
	endif
	
	
//PV("InputTime",rightx(InputLVDTVolts))	
	
	Wave Data32 = $Data32WaveStr
	FixDecimation(Force32ADC,"",Decimation)
	if (Total == 5)
		ErrorStr += ir_xSetInWavePair(2,EventStr,Force32ADC,Data32,StringFromList(4,aliasList,";"),$StringFromList(4,DataWaveList,";"),"",decimation)
	else
		ErrorStr += ir_xSetInWave(2,EventStr,Force32ADC,Data32,"",decimation)
	endif
	if (!triggerChannel)
		ErrorStr += num2str(td_WriteString("OutWave0StatusCallback","ForceScale()"))+","
	endif
	SetupRTForceUpdate2(Display32,Data32,1)
	if (Total >= 5)
		SetupRTForceUpdate2(StringFromList(4,DisplayList,","),$StringFromList(4,DataWaveList,";"),1)
	endif
	
	SetupRTForceUpdate2("TimeWave",ColorWave,1)


	//***********************************
	//RTUpdates
	Variable DoUpdates = GV("DoRTForceUpdate")
	if (DoUpdates == 1)		//auto
		if (FMapStatus)
			DoUpdates = 0
		elseif (displayPoints >= 1e6)
			DoUpdates = 0
		elseif (TriggerChannel)
			DoUpdates = DwellTime >= 2
		else
			DoUpdates = (DwellTime+(rampPoints0+rampPoints1)/sampleRate) >= 5
		endif
	endif
	if ((ImagingMode == cPFMMode) && FMapStatus)
		DoUpdates = 0		//we are too close to the DSP cycle overflow
		//we don't have enough DSP cycles to run RTUpdates
	elseif (NumOfCustomDrive >= 2)
		DoUpdates = 0		//we are using both out wave banks to get this done
		//So we can't do updates
	endif
	if (DoUpdates)
		//2 points wave at 4 Hz, even though the wave only goes to .125 seconds, the callback happens when 
		//the outwave *Really* ends, which is 1 points after the last point.
		Make/N=(2)/O RTUpdateWave
		Wave RTUpdateWave = RTUpdateWave
		Callback = ""
		if (triggerChannel)
			Callback = "RTForceTimerFunc(\"CTFC\")"
		else
			Callback = "RTForceTimerFunc(\"Normal\")"
		endif
		ErrorStr += IR_XSetOutWave(1,cForceStartEvent+","+cForceKeepGoingEvent,"output.Dummy",RTUpdateWave,Callback,ARGetDeci(8))
		
		
		PV("RTForceStartIndex;UpdateWrittenPoints;",0)
	endif
	
	if (Exists("UserFinishForceFunc"))
		FuncRef DoNothing UserFunc=$"UserFinishForceFunc"
		UserFunc()
	endif
	
	//End RTUpdates

	Variable Event2Start = 2^str2num(cForceStartEvent)+2^str2num(cFrameEvent)		//we need to hit the frame event once for the DAM
	ErrorStr += num2str(td_WriteString("Event."+cForceKeepGoingEvent,"Set"))+","
	if (stringmatch(ctrlName,"Many"))
		//do bunches and bunches
		ErrorStr += ir_WriteValue("Events.Set",Event2Start)
		//ErrorStr += num2str(td_WriteString("Event."+cForceStartEvent,"Set"))+","
		if ((GV("MaxContinuousForce") == 1) && (ContForce != 2))
			ErrorStr += ir_WriteValue("Events.Clear",Event2Start)
			//ErrorStr += num2str(td_WriteString("Event."+cForceStartEvent,"Clear"))+","
			PV("ContForce",0)
		else
			ErrorStr += num2str(td_WriteString("Events.Clear",cFrameEvent))+","
		endif
	else
		//single means just do one
		//ErrorStr += num2str(td_WriteString("Event."+cForceStartEvent,"Once"))+","
		ErrorStr += ir_WriteValue("Events.Once",Event2Start)
	endif
	
	
	ARReportError(ErrorStr)

	SetDataFolder(SavedDataFolder)
end Function //prh_FinishForceFunc

Static Function prh_ARSaveAsForce(SaveBit,PName,DataTypeList,Wave0,Wave1,Wave2,Wave3,Wave4,Wave5,Wave6[,CustomNote])
	Variable SaveBit
	String PName, DataTypeList
	Wave Wave0
	Wave/Z Wave1, Wave2, Wave3, Wave4, Wave5, Wave6
	String CustomNote
	
	
	//Function to Save Waves as Asylum Force Plots.
	//Save Bit 0x1 = Save to Mem
	//0x2 = Save to disk
	//	PName Name of Symbolic path that you want to save to disk to.
	//DataTypeList, ; seperated list of dataTypes for Wave1,Wave2 ... Wave6 [Wave0 is always Raw]
	//	Wave0, Raw data Type, must have this wave
	//[Wave1...wave6 optional waves (if you don't have a wave pass it $"")
	
	
	Variable MaxWaves = 7
	
	
	
	Variable WaveCount = WaveExistS(Wave0)+WaveExists(Wave1)+WaveExists(Wave2)+WaveExists(Wave3)+WaveExists(Wave4)+WaveExists(Wave5)+WaveExists(Wave6)
	
	
	
	

	Variable XPos = Td_ReadValue("XSensor")
	Variable YPos = td_ReadValue("YSensor")
	
	String SavedDataFolder = GetDataFolder(1)
	String EmptyFolder = GetDF("Empty")
	SetDataFolder(BuildDataFolder(EmptyFolder))		//go somewhere quiet to work
	//if there are a lot of waves in the folder, things will get slower.




	Wave TimeWave = root:Packages:MFP3D:Force:TimeWave
	wave MVW = root:Packages:MFP3D:Main:Variables:MasterVariablesWave
	wave FVW = root:Packages:MFP3D:Main:Variables:ForceVariablesWave
	Wave RVW = root:Packages:MFP3D:Main:Variables:RealVariablesWave
	SVAR FWL = root:Packages:MFP3D:Force:ForceWavesList
	SVAR SFWL = root:Packages:MFP3D:Force:ShortForceWavesList
	SVAR gBaseName = root:Packages:MFP3D:Main:Variables:BaseName
	String BaseName = gBaseName		//take a local copy, to protect the global


	wave TVW = root:Packages:MFP3D:Main:Variables:ThermalVariablesWave
	Wave UserParms = root:Packages:MFP3D:Main:Variables:UserVariablesWave
	Wave/T GSW = $GetDF("Strings")+"GlobalStrings"
	wave XPTwave = root:Packages:MFP3D:XPT:XPTLoad
	wave AllAlias = root:packages:MFP3D:Hardware:AllAlias
//	NVAR VerDate = root:Packages:MFP3D:Main:Variables:VerDate





	Variable AllowMDB = 1
	string suffixStr = num2strlen(MVW[%BaseSuffix][0],4)
	string tempSeconds
	String DataType = ""
	String LongDataType = ""
	String NoteStr = ""
	Variable SaveNop, DataNop, SaveFactor, StartIndex, StopIndex
	String Indexes = "0,"
	String Directions = "NaN,"

	Indexes += "0,"+num2istr(DimSize(Wave0,0)-1)+","+num2istr(DimSize(Wave0,0)-1)+","
	Directions += "1,0,-1,"

	
	variable i
	variable column = 1
	

	String OfflineSubFolder = "Memory"
	
	//make sure we can still save to disk
	if (SaveBit & 0x2)
		if (!SafePathInfo(PName))			//what happened to our path!
			SaveBit = SaveBit & ~0x2
		else
			PathInfo $Pname
			OfflineSubFolder = ForceSubFolderCleanUp(LastDir(S_Path))
		endif
	endif
	
	
	

	StopIndex = WhichListItem("ZSensor",FWL,";",0,0)
	
	String DataFolder = ARGetForceFolder("",OfflineSubFolder,BaseName+SuffixStr)
	//Don't ever set to root:ForceCurves, it can get very slow when there are lots of force plots in memory
	//This also keeps the empty string input, this is the only way into the "memory" folder (besides double click loaders).
	




	Variable TheWeatherOutside = NaN, A, nop
	Variable ImagingMode = MVW[%ImagingMode][%Value]



	NoteStr = ReplaceNumberbyKey("VerDate",NoteStr,VersionNumber(),":","\r")
	NoteStr = ReplaceStringByKey("Version",NoteStr,VersionString(),":","\r")
	NoteStr = ReplaceStringByKey("XOPVersion",NoteStr,td_XopVersion(),":","\r")
	NoteStr = ReplaceStringByKey("OSVersion",NoteStr,StringByKey("OS",IgorInfo(3),":",";",0),":","\r",0)
	NoteStr = ReplaceStringByKey("IgorFileVersion",NoteStr,StringByKey("IgorFileVersion",IgorInfo(3),":",";",0),":","\r",0)
	NoteStr = ReplaceNumberByKey("XLVDT",NoteStr,td_ReadValue("XSensor")*abs(MVW[%XLVDTSens][%value]),":","\r")
	NoteStr = ReplaceNumberByKey("YLVDT",NoteStr,td_ReadValue("YSensor")*abs(MVW[%YLVDTSens][%value]),":","\r")
	SVAR/Z ForceNote = root:Packages:MFP3D:Main:Variables:ForceNote
	SVAR/Z TipSerialNumber = Root:Packages:MFP3D:Main:Variables:TipSerialNumber
	if (SVAR_EXISTS(ForceNote))
		NoteStr = ReplaceStringByKey("ForceNote",NoteStr,ForceNote,":","\r")
	endif
	If (SVAR_EXISTS(TipSerialNumber))
		NoteStr = ReplaceStringByKey("TipSerialNumber",NoteStr,TipSerialNumber,":","\r")
	endif

	noteStr += GetWaveParms(FVW)
	NoteStr = ReplaceStringByKey("TriggerChannel",NoteStr,GTS("TriggerChannel"),":","\r",0)
	NoteStr = ReplaceStringByKey("DwellRampFunc",NoteStr,GTS("DwellRampFunc"),":","\r",0)
	NoteStr = ReplaceStringByKey("DwellRampMode",NoteStr,GTS("DwellRampMode"),":","\r",0)
	NoteStr = ReplaceStringBykey("ForceMode",NoteStr,GTS("ForceMode"),":","\r",0)
	NoteStr = ReplaceStringByKey("ForceSaveList",NoteStr,GTS("ForceSaveList"),":","\r",0)
	nop = cMaxRTForceGraphs
	for (A = 0;A < nop;A += 1)
		NoteStr = ReplaceStringByKey("ForceDisplay"+num2str(A),NoteStr,GTS("ForceDisplay"+num2str(A)),":","\r",0)
	endfor
	noteStr += GetWaveParms(XPTWave)
	noteStr += GetWaveParms(MVW)
	NoteStr = ReplaceStringByKey("MicroscopeModel",NoteStr,GetMicroscopeName(MicroscopeID=MVW[%MicroscopeID][0]),":","\r",0)
	NoteStr = ReplaceStringByKey("ImagingMode",NoteStr,GTS("ImagingMode"),":","\r",0)
	NoteStr = ReplaceNumberByKey("NumPtsPerSec",NoteStr,1/DimDelta(Wave0,0),":","\r",0)
	noteStr += GetWaveParms(TVW)
	NoteStr += GetWaveParms(GSW)
	if (FVW[%ARDoIVFP][%Value])
		Wave DoIVWave = root:Packages:MFP3D:Main:Variables:ARDoIVVariablesWave
		NoteStr += GetWaveParms(DoIVWave)
		NoteStr = ReplaceStringByKey("ARDoIVFunc",NoteStr,GTS("ARDoIVFunc"),":","\r")
		Wave/Z ExtraParms = $GetDF("DoIV")+"UserParmWave"
		if (WaveExists(ExtraParms))
			for (A = 0;A < DimSize(ExtraParms,0);A += 1)
				NoteStr += "ARDoIVParm"+num2str(A+4)+":"+num2str(ExtraParms[A])+"\r"
			endfor
		endif
	endif
	NoteStr += GetWaveParms(UserParms)
	if (ImagingMode == cFMMode)
		Wave FMVW = $cFMVW
		NoteStr += GetWaveParms(FMVW)
	endif
	NoteStr += GetWaveParms(AllAlias)
	
	NoteStr = ReplaceStringByKey("Indexes",NoteStr,Indexes,":","\r",0)
	NoteStr = ReplaceStringByKey("Direction",NoteStr,Directions,":","\r",0)
	
	
	//sprintf tempSeconds, "%u", DateTime
	tempSeconds = ARNum2Str(DateTime)
	
	//Variable Tic = StopMsTimer(-2)
	NoteStr = RemoveStringByKey(NoteStr,"StartHeadTemp",":","\r")		//to move this to bottom of note?
	NoteStr = RemoveStringByKey(NoteStr,"StartScannerTemp",":","\r")
	//print StopMsTimer(-2)-tic
	
	variable readTemp = 0
	switch (MVW[%MicroscopeID][0])

		case cMicroscopeInfinity:
		case cMicroscopeMFP3D:
	
			NoteStr = ReplaceStringByKey("StartHeadTemp",NoteStr,td_ReadString("Head.Temperature"),":","\r",0)
			NoteStr = ReplaceStringByKey("StartScannerTemp",NoteStr,td_ReadString("Scanner.Temperature"),":","\r",0)
			NoteStr = ReplaceStringByKey("StartTempSeconds",NoteStr,TempSeconds,":","\r",0)

			Struct HeaterTempParms HeaterParms
			HeaterTempNoteFunc(HeaterParms,NoteStr,0)
			HeaterTempNoteFunc(HeaterParms,NoteStr,1)

			readTemp = 1				//we might read temperature later
			NoteStr = ReplaceStringByKey("EndHeadTemp",NoteStr,"None Yet",":","\r",0)
			NoteStr = ReplaceStringByKey("EndScannerTemp",NoteStr,"None Yet",":","\r",0)
			NoteStr = ReplaceStringByKey("EndTempSeconds",NoteStr,"0",":","\r",0)
			break
		
		case cMicroscopeCypher:		//cypher has none of this
			
			NoteStr = RemoveByKey("StartTempSeconds",NoteStr,":","\r",0)

			NoteStr = RemoveByKey("EndHeadTemp",NoteStr,":","\r",0)
			NoteStr = RemoveByKey("EndScannerTemp",NoteStr,":","\r",0)
			NoteStr = RemoveByKey("EndTempSeconds",NoteStr,":","\r",0)
			
	endswitch	
	


////////////////////
//Clean up the note







	//sprintf tempSeconds, "%u", DateTime
	tempSeconds = ARNum2Str(DateTime)
	NoteStr = ReplaceStringByKey("Date",NoteStr,ARU_Date(),":","\r",0)
	NoteStr = ReplaceStringByKey("Time",NoteStr,Time(),":","\r",0)
	NoteStr = ReplaceNumberbyKey("BaseSuffix",NoteStr,MVW[%BaseSuffix][0],":","\r",0)
	NoteStr = ReplaceStringByKey("Seconds",NoteStr,TempSeconds,":","\r",0)
	if (AllowMDB && readTemp)
		NoteStr = ReplaceStringByKey("EndHeadTemp",NoteStr,td_ReadString("Head.Temperature"),":","\r",0)
		NoteStr = ReplaceStringByKey("EndScannerTemp",NoteStr,td_ReadString("Scanner.Temperature"),":","\r",0)
		NoteStr = ReplaceStringByKey("EndTempSeconds",NoteStr,TempSeconds,":","\r",0)
		
	endif
	NoteStr = ReplaceNumberByKey("XLVDT",NoteStr,XPos*abs(MVW[%XLVDTSens][%value]),":","\r",0)
	NoteStr = ReplaceNumberByKey("YLVDT",NoteStr,Ypos*abs(MVW[%YLVDTSens][%value]),":","\r",0)
	NoteStr = ReplaceNumberByKey("DDSAmplitude",NoteStr,td_ReadValue("DDSAmplitude0"),":","\r",0)



	if (!ParamIsDefault(CustomNote) && Strlen(CustomNote))
		nop = ItemsInList(CustomNote,"\r")
		String CustomItem
		Variable Index
		for (A = 0;A < nop;A += 1)
			CustomItem = StringFromList(A,CustomNote,"\r")
			Index = strsearch(CustomItem,":",0,2)
			if (Index < 0)
				Continue
			endif
			NoteStr = ReplaceStringByKey(CustomItem[0,Index-1],NoteStr,Customitem[Index+1,Strlen(CustomItem)-1],":","\r",0)
		endfor
	endif
//Note is all set now

	
	if (SaveBit & 0x1)				//Memory
		Column = 1			//make sure it is still 1.
		OfflineFPLookup(BaseName+SuffixStr,OfflineSubFolder,1)		//add the new FP to the lookup Table.
		SetDataFolder(EmptyFolder)
		SetScale d,0,0,"m",Wave0
		Duplicate/O Wave0 $DataFolder+BaseName+suffixStr+"Raw"
		Wave Temp = $DataFolder+BaseName+suffixStr+"Raw"
		Note/K Temp
		Note Temp,NoteStr
		
		for (A = 1;A < MaxWaves;A += 1)
			Switch (A)
				case 1:
					Wave/Z Data = Wave1
					break
					
				case 2:
					Wave/Z Data = Wave2
					break
				
				case 3:
					Wave/Z Data = Wave3
					break
					
				case 4:
					Wave/Z Data = Wave4
					break
					
				case 5:
					Wave/Z Data = Wave5
					break
					
				case 6:
					Wave/Z Data = Wave6
					break
					
			endswitch
			if (!WaveExists(Data))
				continue
			endif
			
			Duplicate/O Data $DataFolder+BaseName+suffixStr+StringFromList(A-1,DataTypeList,";")
			Wave Data = $DataFolder+BaseName+suffixStr+StringFromList(A-1,DataTypeList,";")
			Note/K Data
			Note Data,NoteStr
			SetScale d,0,0,Get3DScaling(StringFromList(A-1,DataTypeList,";")),Data
		endfor
		
	endif


	Variable FileRef, SaveIndex
	String LabelStr

	
	if (SaveBit & 0x2)			//save to disk
		SaveIndex = 0
		Make/O/N=(DimSize(Wave0,0),WaveCount) $BaseName+SuffixStr
		Wave SaveWave = $BaseName+SuffixStr
		SetDimLabel 1,SaveIndex,$"Raw",SaveWave
		SaveWave[][SaveIndex] = Wave0[p]
		SaveIndex += 1
		CopyScales/P Wave0, SaveWave
		Note/K SaveWave
		Note SaveWave,NoteStr



		for (A = 1;A < MaxWaves;A += 1)
			Switch (A)
				case 1:
					Wave/Z Data = Wave1
					break
					
				case 2:
					Wave/Z Data = Wave2
					break
				
				case 3:
					Wave/Z Data = Wave3
					break
					
				case 4:
					Wave/Z Data = Wave4
					break
					
				case 5:
					Wave/Z Data = Wave5
					break
					
				case 6:
					Wave/Z Data = Wave6
					break
					
			endswitch
			if (!WaveExists(Data))
				continue
			endif

			SaveWave[][SaveIndex] = Data[P]
			SetDimLabel 1,SaveIndex,$StringFromList(A-1,DataTypeList,";"),SaveWave
			SaveIndex += 1
		endfor



		Save/C/O/P=$Pname SaveWave
		
		// XXX 2017-6-9. this line kills the fast capture data...
		//Put on the footer
		//Open/A/P=$Pname FileRef as BaseName+SuffixStr+".ibw"
		//TagFPFooter(FileRef,SaveWave,UpdateOffline=0)
		//Close(FileRef)
		KillWaves SaveWave
	endif
	
	
	
	IncSuffix()

	SetDataFolder(SavedDataFolder)
	ForceRealTimeUpdateOffline()
End //prh_ARSaveAsForce

