// Use strict wave reference mode
#pragma rtGlobals=3
// define this modeules name and independence
#pragma ModuleName = ModDefine
// Independent module (shoudn't depend on anything else.)
//#pragma IndependentModule = pDefines
// Enabled the debugger for this module (see: Advanced Topics.ihf)
//SetIgorOption IndependentModuleDev=1

// The default separators for the list
StrConstant DEF_LISTSEP = ","
StrConstant DEF_DIRSEP = ":"
// Bad returns
Constant DEF_BADREFNUM = nan
StrConstant DEF_BADREFSTR = "nan"
// The Mode for StructGet and StructPut. Want to be explicit
// so this works across computers
Constant STRUCT_BYTE_IO = 2
// true and False, which aren't defined for some reason...
Constant DEF_TRUE = 1
Constant DEF_FALSE = 0
StrConstant LISTBOX_SEP_ITEMS = ";"

Structure Defines
	// string separator for a list
	String ListSep
	// string separator for directories
	String DirSep 
	// Bad return value for variable
	Variable BadVarRet
	// For IgorInfo, Argument 
	Variable IgorInfoScreenSel
	String IgorInfoScreenRegex
EndStructure

ThreadSafe Static Function True()
	return DEF_TRUE
End Function

ThreadSafe Static Function False()
	return DEF_FALSE
End Function

ThreadSafe Static Function /S DefListSep()
	return  DEF_LISTSEP
End Function

ThreadSafe Static Function /S DefDirSep()
	return DEF_DIRSEP
end Function

ThreadSafe Static Function StructFmt()
	return STRUCT_BYTE_IO
End Function	

ThreadSafe Static Function DefBadRetNum()
	return DEF_BADREFNUM
End Function

ThreadSafe Static Function /S DefBadRetStr()
	return DEF_BADREFSTR
End Function

Function InitDefines(Global)
	Struct Defines &Global
	// Initialize the Global structure
	Global.ListSep = DefListSep()
	Global.DirSep = DefDirSep()
	Global.BadVarRet = DefBadRetNum()
	// make the IgorInfo Defines
	//GlobaI.IgorInfoScreenSel = 0
	//Global.IgorInfoScreenRegex = "*RECT=(\d+),(\d+),(\d+),(\d+);"
End Function

ThreadSafe Static Function isNan(toCheck)
	Variable toCheck
	// any check with nan returns false (?)
	return toCheck != toCheck
End Function
