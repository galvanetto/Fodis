#pragma rtGlobals=3        // Use strict wave reference mode
#include ":Defines"
#include ":DataStructures"

#pragma ModuleName=ModErrorUtil

Static Constant MAX_ERRORS=100
// Note: All error numbers which are 'static'
// (ie: don't need the global error object)
// should be constant, and negative (defined here, used
// by lots of utility functions
Static Constant ERR_ASSERTION = -1
Static Constant ERR_WAVEEXIST = -2
Static Constant ERR_TYPE = -3
Static Constant ERR_OUT_OF_RANGE = -4
Static Constant ERR_PROGRAMMING = -5
Static Constant ERR_IO = -6
// Bad Wave reference
// Selector to get the entire stack trace
Static Constant RTStack_FullTrace = 3
// Constant for RTStack list separator
Static StrConstant RT_STACK_LISTSEP = ";"
// V-123. Alert has multiple types
Constant DOALERT_PROMPT_OK = 0
Constant DOALERT_PROMPT_YES_NO = 1
Constant DOALERT_PROMPT_YES_NO_CANCEL = 2
// V-108: DebuggerOptions
Constant DEBUGGEROPTIONS_ENABLE = 1 // enable, and debug on erro


Structure ErrorCodes
	Variable PROGRAMMING 
	Variable MISSING_FILE
EndStructure

Structure ErrorObj
	Struct ErrorCodes Codes
	// List of descriptions
	String Descr
	Variable NErrors
EndStructure


Static Function AddErrorToList(obj,descr,GlobalDef)
	// Returns the error code number for this description
	// Adds this new code/description to ErrorObj
	Struct ErrorObj &obj
	Struct Defines &GlobalDef
	String descr
	Variable toRet = obj.NErrors
	// add the descrption
	 obj.Descr += ModDataStructures#GetListString(descr,GlobalDef.ListSep)
	// Add another error (increment the ID)
	obj.NErrors += 1
	return toRet
End Function

Static Function InitErrorObjAndCodes(ToInitObj,Codes,GlobalDef)
	Struct ErrorObj &ToInitObj
	Struct Defines &GlobalDef
	Struct ErrorCodes &Codes
	// initialize the list of names...
	ToInitObj.Descr = ""
	// Set the number of errors to zero initially
	ToInitObj.NErrors = 0
	// Add the error codes one at a time
	 codes.PROGRAMMING = AddErrorToList(ToInitObj,"Programming Error",GlobalDef)
	 codes.MISSING_FILE= AddErrorToList(ToInitObj,"Required File Missing",GlobalDef)
End Function

Static Function InitErrorObj(ToInit,GlobalDef)
	Struct ErrorObj &ToInit
	Struct Defines &GlobalDef
	InitErrorObjAndCodes(ToInit,ToInit.Codes,GlobalDef)
End


Static Function ThrowFatalError(Code,Description,[SpecificDesc])
	Variable Code
	String Description,SpecificDesc
	String ExtraString = "",toPrint
	if (!ParamIsDefault(SpecificDesc))
		sprintf ExtraString,"Specific Information: [%s]",SpecificDesc
	EndIf
	String rtStack = GetRTStackInfo(RTStack_FullTrace)
	String stackTrNewline = ""
	Variable nItems = ItemsInList(rtStack,RT_STACK_LISTSEP)
	Variable i
	// Print each element of the stack trace on a separate line
	for (i=0; i<nItems; i+=1)
		stackTrNewline += StringFromList(i,rtStack,RT_STACK_LISTSEP) +"\r"
	EndFor
	// Format out all the information we have
	String abbreviated
	sprintf abbreviated,"Fatal Error, Code [%d].\rDescr: [%s]\r%s",Code,Description,ExtraString
	sprintf toPrint,"%s\rStackTr:\r%s",abbreviated,stackTrNewline
	print(toPrint)
	// Abort!!!
	// Change to the root directory, avoid problematic state changes on an error.
	SetDataFolder root:
	AlertUser(abbreviated)
	// Enable the debugger
	DebuggerOptions enable=(DEBUGGEROPTIONS_ENABLE), debugOnError=(DEBUGGEROPTIONS_ENABLE)
	// Break into the debugger
	Debugger
	AbortOnRTE
	Abort
End Function

Static Function DevelopmentError([description])
	String description
	String finalDescr = "Development (programming) error"
	Variable mCode = ERR_PROGRAMMING
	If(ParamIsDefault(description))
		ThrowFatalError(mCode,finalDescr)
	else
		ThrowFatalError(mCode,finalDescr,SpecificDesc=description)
	EndIf
End Funciton

Static Function OutOfRangeError([description])
	String description
	String finalDescr = "Out of Range Error"
	Variable mCode = ERR_OUT_OF_RANGE
	If(ParamIsDefault(description))
		ThrowFatalError(mCode,finalDescr,SpecificDesc=description)
	else
		ThrowFatalError(mCode,finalDescr)
	EndIf
End Function

Static Function IoError([description])
	String description
	String finalDescr = "Io Error"
	Variable mCode = ERR_IO
	If(ParamIsDefault(description))
		ThrowFatalError(mCode,finalDescr,SpecificDesc=description)
	else
		ThrowFatalError(mCode,finalDescr)
	EndIf
End Function

Static Function TypeError([description])
	String description
	String finalDescr
	Variable mCode = ERR_TYPE
	if (!ParamIsDefault(description))
		ThrowFatalError(mCode,finalDescr,SpecificDesc=description)
	else
		ThrowFatalError(mCode,finalDescr)
	EndIf
End Function

Static Function assert_wave_exists(toCheck,[msg])
	// throws an error if ToCheck doesnt exist
	//
	// Args: 
	//	ToCheck: wave of interest
	// 	msg: additional message to give the user
	// 
	// Returns: 
	//	Nothing
	Wave /Z toCheck
	String msg
	if (ParamIsDefault(msg))
		msg = ""
	EndIf
	if (!WaveExists(toCheck))
		Variable mCode = ERR_WAVEEXIST
		String mDesc ="Required wave " + NameOfWave(toCheck) + " doesn't exist.\n" + msg
		ThrowFatalError(mCode,mDesc)
	EndIf
End Function

Static Function WaveExistsOrError(toCheck)
	// see: assert_wave_exists, except toCheck is a string
	String toCheck
	assert_wave_exists($toCheck)
End Function

Static Function AssertLT(a,b,[errorDescr])
	// Assert that "a< b", or throw a fatal error
	Variable a,b
	String errorDescr
	if (a >= b)
		Variable mCode = ERR_ASSERTION
		String mDesc = "Assert first less than second Failed"
		// Throw a fatal error
		// XXX make non fatal version?
		// XXX make this into a general method using funcref?
		if (ParamIsDefault(errorDescr))
			ThrowFatalError(mCode,mDesc)
		else 
			ThrowFatalError(mCode,mDesc,SpecificDesc=errorDescr)
		EndIf
	endif
End Function

Static Function AssertGT(a,b,[errorDescr])
	// Assert that "a< b", or throw a fatal error
	Variable a,b
	String errorDescr
	if (a <= b)
		Variable mCode = ERR_ASSERTION
		String mDesc = "Assert first greater than second Failed"
		// Throw a fatal error
		// XXX make non fatal version?
		// XXX make this into a general method using funcref?
		if (ParamIsDefault(errorDescr))
			ThrowFatalError(mCode,mDesc)
		else 
			ThrowFatalError(mCode,mDesc,SpecificDesc=errorDescr)
		EndIf
	endif
End Function

Static Function AssertNeq(a,b,[errorDescr])
	Variable a,b
	String errorDescr
	if (a == b)
		Variable mCode = ERR_ASSERTION
		String mDesc = "Assert not equal failed"
		// Throw a fatal error
		// XXX make non fatal version?
		// XXX make this into a general method using funcref?
		if (ParamIsDefault(errorDescr))
			ThrowFatalError(mCode,mDesc)
		else 
			ThrowFatalError(mCode,mDesc,SpecificDesc=errorDescr)
		EndIf
	endif
End Function

Static Function AssertEq(a,b,[errorDescr])
	Variable a,b
	String errorDescr
	if (a != b)
		Variable mCode = ERR_ASSERTION
		String mDesc = "Assert equal failed"
		// Throw a fatal error
		// XXX make non fatal version?
		// XXX make this into a general method using funcref?
		if (ParamIsDefault(errorDescr))
			ThrowFatalError(mCode,mDesc)
		else 
			ThrowFatalError(mCode,mDesc,SpecificDesc=errorDescr)
		EndIf
	endif
End Function

Static Function AlertUser(Message,[type])
	String Message
	Variable type
	type = ParamIsDefault(type) ? DOALERT_PROMPT_OK : type
	// POST: we have type
	// XXX add in handles for yes, no, cancel buttons.
	// XXX add in handle for caller
	DoAlert /T=("Warning") type,Message
End Function


Static Function Assert(bool,[msg])
	// throws a fatal error if bool != 1
	// 	Args:
	//		bool: condition
	//		msg: the message to display on failure
	//	Returns:
	//		nothing
	Variable bool
	String msg
	if (ParamIsDefault(msg))
		msg = ""
	EndIf
	if (!bool)
		ThrowFatalError(ERR_ASSERTION,"Assertion Error",SpecificDesc=msg)
	EndIf
End Function