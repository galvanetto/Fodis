// Use modern global access method, strict compilation
#pragma rtGlobals=3	

#pragma ModuleName = ModMenuUtil
#include ":::Util:ErrorUtil"
#include ":MenuNames"


Static Function AssertControlExists(ControlName,WindowName)
	// Asserts a specific contrl exists
	//
	// Args:
	//		ControlName: Name of the control we want
	//		Value: variableto set it to
	//      WindowName: Window to look for control
	// Returns:
	//      None
	// POST: control exists
	String ControlName,WindowName
	ControlInfo /W=$(WindowName) ControlName
	if (V_flag < 0)
		ModErrorUtil#OutOfRangeError(description="Bad Control Name")
	endif
	// POST: control exists
End Function

Static Function /S GetTopWindowName()
	// Returns the top window name
	//
	// Returns:
	//      Top window name, as a string
	// See: Igor manual, pp833, "WinName"
	Variable BinaryCode = 1 + 4 + 64
	// 0 codes for the first window
	return WinName(0,BinaryCode)
End Function

Static Function SetVariableSafe(ControlName,Value,[WindowName])
	// Sets up the cypher how we typically want it
	//
	// Args:
	//		ControlName: Name of the control we want
	//		Value: variableto set it to
	//      WindowName: Window to look for control
	// Returns:
	//      None
	String ControlName,WindowName
	Variable Value
	if (ParamIsDefault(WindowName))
		WindowName = GetTopWindowName()
	EndIf
	AssertControlExists(ControlName,WindowName)
	SetVariable ControlName win=$(WindowName), value=_NUM:Value
End Function

Static Function SetVariableMasterPanel(ControlName,Value)
	// Set a variable in the master panel
	//
	// Args:
	//		See: SetVariableSafe
	// Returns:
	//      None
	String ControlName
	Variable Value
	SetVariableSafe(ControlName,Value,WindowName=ModMenuNames#MasterPanel())
End Function

Static Function Main()
	// Sets up the cypher how we typically want it
	//
	// Args:
	//		Arg 1:
	//		
	// Returns:
	//
	//
End Function