// Use modern global access method, strict compilation
#pragma rtGlobals=3	

#pragma ModuleName = ModMenuNames

Static Structure CypherSetVariableInfo
	// Structure for setting a variable used in the Cyphers GUI
	
	// Which array we are using
	Wave ArrayPointer
	// name of the control
	String ControlName
	// name of the variable
	String VariableName
	// Series of indices used to acces the actual variable
	String Index1
	String Index2
	String Index3
	// What callback to make after we set the element
	Funcref SetVariableControl SetVariableCallback
EndStructure

Static Function CreateSetVariableInMatrix(ToCreate,Array,Callback,Index1,Index2,ControlName,VariableName)
	// Creates a structure for a CypherSetVariableInfo with an element residing in a 2-d matrix
	//
	// Args:
	//		ToCreate: Allocated structure to use 
	//		Array: Where the set variable lives
	//		Index1,Index2: The pair of indices giving the address in Array
	//      	Callback: what to use to inform the cypher the variable was changed
	//		ControlName,VariableName: Name of  the control and variable within the ocntrol
	// Returns:
	//     	Nothing, does update 'ToCreate'
	Struct CypherSetVariableInfo &ToCreate
	Wave Array
	Funcref SetVariableControl Callback
	String Index1,Index2,ControlName,VariableName
	ToCreate.ArrayPointer = Array
	ToCreate.Index1 = Index1
	ToCreate.Index2 = Index2
	// We only have two indics for the wave
	ToCreate.Index3 = ""
	//ToCreate.SetVariableCallback = CallBack 
End Function 

Static Structure MenuObject

End Structure

// Below are functions returning important control names
Static Function /S MasterScanSize()
	return "ScanSizeSetVar_0"
End Function

Static Function /S MasterScanRate()
	return "ScanRateSetVar_0"
End Function

Static Function /S MasterOffsetX()
	return "XOffsetSetVar_0"
End Function

Static Function /S MasterOffsetY()
	return "YOffsetSetVar_0"
End Function

Static Function /S MasterScanPixels()
	return "PointsLinesSetVar_0"
End Function
	
// Below are functions returning important panel names
Static Function /S MasterPanel()
	return "MasterPanel"
End Function

