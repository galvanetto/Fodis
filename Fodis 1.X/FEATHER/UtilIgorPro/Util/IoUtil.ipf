// Use modern global access method, strict compilation
#pragma rtGlobals=3	
#pragma ModuleName = ModIoUtil
#include ":DataStructures"
#include ":ErrorUtil"

// Name for root directory
StrConstant DEF_ROOTNAME = "root"
// Font Defaults
StrConstant DEF_FONTNAME = "Helvetica"
Constant DEF_FONTSIZE = 16
Constant DEF_FONTSTYLE = 0
// For objetc countObject/GetIndexedObjName
Constant COUNT_WAVES = 1
Constant COUNT_DATAFOLDERS = 4
// 0 for reverse grep (get everything that DOESNT match
// See igor manual, pp V-243 'GrepList'
Constant GREP_SELECT_MATCHING = 0
// Window type is 1 for graphs (see V-761, Wintype)
Constant WINTYPE_NOT_A_WINDOW = 0
// Secs2Time: format V-563 of igor manual. Want military time with seconds and optional
Constant SEC2TIME_FMT_ELAPSED_FULL = 3
// Give time down to this number of fractional digits
Constant SEC2TIME_DIG = 6
// GetDataFolder full path
Constant GETDATAFOLDER_FULLPATH = 1
// Loading constants 
Constant LOADDATA_DEF_OVERWRITE = 2 // Mix-in overwrite: don't destroy if we dont have to
// Regex for a file
StrConstant DEFAULT_REGEX_FILE = ".*:([^:]+)"
// UniqueName -- DataFolder V-729
StrConstant DEF_PATHNAME = "tmpPath"
Constant UNQUENAME_DEF_SUFFIX =0
Constant UNIQUENAME_GRAPH = 6
Constant UNIQUENAME_PANELWINDOW = 9
Constant UNIQUENAME_DATAFOLDER = 11
Constant UNIQUENAME_PATH = 12
Constant UNIQUENAME_Control = 15
Constant UNIQUENAME_ANNOTATION = 14 
// UniqueName: Wave
Constant UNIQUENAME_WAVE = 1
Constant CLEANUP_NAME_STRICT = 0
// GetFileFolderInfo: V-215
Constant GETFILEFOLDER_RETSUCESS = 0
Constant GETFILEFOLDER_ONLYEXISTING = 1 // dont display a dialog if the file doesnt exist
Constant GETFILEFOLDER_INTERACTIVE = 2 // *do* display a dialog if the file doesnt exist
//NumType return for a normal number V-471
 Constant NUMTYPE_NORMAL = 0
// Separator for dates
StrConstant DEF_DATE_SEP = "/"
// Igor V-562, Secs2Date
// If format is -2, the format is YYYY-MM-DD.
Constant SEC2DATE_FMT = -2
// constants used to calculate the time, below
Static Constant secsPerMin = 60
Static Constant secsPerHour = 3600
// See Igor Api V-230
Static Constant GETWAVES_DF_FULL_PATH = 2
//V-314, Inddexed Dir
Static Constant INDEXEDDIR_FULL_PATH = 1
Static StrConstant INDEXEDDIR_ALL_FILES = "????"
Static Constant INDEXDIR_DEF_LEVEL = 0
// Start of a file extension
Static StrConstant EXT_START = "."
//See V-488, pathinfo
Static Constant PATHINFO_EXISTS = 1
// Maximum String length
Static Constant MAX_STRLEN = 31
// Constants for loading in files
Static StrConstant FILE_EXT_IGOR_PACKED_EXP = ".pxp"
Static StrConstant FILE_EXT_IGOR_BIN_WAVE = ".ibw"
Static StrConstant FILE_EXT_IGOR_TXT = ".itx"
Static StrConstant FILE_EXT_CSV = ".csv"
Static StrConstant FILE_EXT_TXT = ".txt"
// Constants for loading files.
// See V-359 LoadWave, 
//k=0: Deduces the nature of the column automatically.
Static Constant LOADWAVE_COLTYPE_AUTO = 0
// See V-259 LoadWave
// Essentially,  all zeros doesn't do any function conversions
Static StrConstant LOADWAVE_SKIPCHARS = "$" // This is aprameterly spaces
Static Constant LOADWAVE_DEF_CONVERSIONS = 0
Static Constant LOADWAVE_DEF_FLAGS = 0
Static StrConstant LOAD_FOLDER_NO_EXTRA_DIR = ""
Static StrConstant DEF_LOADFILE_DELIM = "\t," // CSV or tab by default, see LoadWave /V flag
// Regex for matching the *last* directory/folder, with optional pre-directories
// and file names. Something like "root:foobar:Image2401Time_Ret" --> "foobar"
StrConstant MATCH_LAST_DIR = ".*:([^:]+):[^:]*"
// For 'newpath', pp V-455, V_flag is zero if we succeeed 
Constant PATH_RET_SUCESS = 0
// default wave name for initialization
StrConstant DEF_WAVE_NAME = "prhWave"
// Useful ASCII codes
Constant ASCII_ENTER = 13
Static Function is_ascii_enter(d)
	Variable d
	return d == 13
End Function

Structure Font
	String FontName
	Variable FontSize,FontStyle
EndStructure

Structure cursor_info
	// structure containing information about two cursors placed on a plot 
	Variable a_idx 
	Variable b_idx
	String trace_name
	Wave trace_reference
EndStructure

Static Function FontDefault(ToGet)
	Struct Font &ToGet
	ToGet.FontName = DEF_FONTNAME
	ToGet.FontSize = DEF_FONTSIZE
	ToGet.FontStyle = 0
End Function

Static Function DefFontSize()
	return DEF_FONTSIZE
End Function

Static Function /S DefFontName()
	return DEF_FONTNAME
End Function

Static Function /S DefFileRegex()
	return DEFAULT_REGEX_FILE 
End Function

// Appends 'toAppend' to 'base' using mSep (directories, by default)
ThreadSafe Static Function /S AppendedPath(Base,toAppend,[mSep])
	String base,toAppend
	String mSep
	// Assume we are using directory separating, by default
	if (ParamIsDefault(mSep))
		mSep = ModDefine#DefDirSep() 
	EndIf
	String toRet = base + mSep + toAppend
	// replace repitions of the separator by a single separator
	// XXX ensure base doesn't end with a colon (probably fastest way)
	// XXX make a 'sanitization' routine?
	toRet = ReplaceString(mSep + mSep,toRet,mSep)
	return toRet
End Function

Static Function /S EnsureEndsWith(Base,ensure)
	// Returns 'base' after making sure it ends with 'ensure'
	String Base, ensure
	return ModIoUtil#AppendedPath(Base,"",mSep=ensure)
End Function

Static Function /S GetFuncName(FuncRefInfoStr)
	// FuncRefInfoStr is the output of FuncRefInfo
	String FuncRefInfoStr
	String Expr = "NAME:([^;]+)",toRet
	// XXX return error if this doesn't work?
	 SplitString /E=Expr FuncRefInfoStr,toRet
	 return toRet
End Function

Static Function CountWaves(path)
	String path
	// PP V-79 of the igor manual
	return CountObjects(path,COUNT_WAVES)
End Function


Static Function /S GetWaveAtIndex(path,index,[fullPath])
	String path
	Variable index,fullPath
	fullPath = ParamIsDefault(fullPath) ? ModDefine#False() : fullPath
	String mName = GetIndexedObjName(path,COUNT_WAVES,index)
	if (fullPath)
		return ModIoUtil#appendedPath(path,mName)
	else
		return mName
	EndIf
End Function

Static Function CountDataFolders(path)
	String path
	return CountObjects(path,COUNT_DATAFOLDERS)
End Function	

Static Function /S GetDataFolderAtIndex(path,index)
	String path
	Variable Index
	return GetIndexedObjName(path,COUNT_DATAFOLDERS,index)
End Function

Static Function ListDataFoldersInDir(path,mWave)
	String path,mWave
	Variable nDirs = CountDataFolders(path)
	Wave /T mRef = $mWave
	Redimension /N=(nDirs) mRef
	mRef[] = GetDataFolderAtIndex(path,p)
End Function


Static Function /S GetDataFolders(path,waveToPop)
	String path
	Wave /T waveToPop
	// wave to pop must already be made
	// ensure 'tmp' is gone
	KillWaves /Z tmp
	// puts all the data folder names in 'waveTopop'
	Variable nObjects = CountDataFolders(path)
	Variable i=0;
	Make /O/N=(nObjects)/T tmp
	String tmpFolder
	for (i=0; i < nObjects; i+= 1)
		tmpFolder = GetDataFolderAtIndex(path,i)
		tmp[i] = tmpFolder
	EndFor
	// POST: tmpRef (and $waveToPop) 
	Duplicate /O/T tmp,waveToPop
	KillWaves /Z tmp
	// have every folder. XXX redimension wave?
End Function

Static Function /S current_experiment_name()
	//	Returns the file name (not path) of the current experiment
	//	Args:
	//		None
	//	Returns:
	//		String of the current experiment name
	return IgorInfo(1)
End Function

Static Function cursor_info(graph_name,info_struct)
	//	updates the given references to the A and B cursors on the given image
	//	Args:
	//		graph_name: name of a graph to look for
	//		a/b_idx_ref: reference to the index where the a/b cursor is
	//		trace_name: reference name of the trace the cursors are on 
	//	Returns:
	//		nothing, but updates the name and index references
	struct cursor_info & info_struct
	String graph_name
	String a_info = CsrInfo(A,graph_name)
	String b_info = CsrInfo(B,graph_name)
	Variable a_idx = NumberByKey("POINT",a_info)
	Variable b_idx = NumberByKey("POINT",b_info)
	String trace_name = StringByKey("TNAME",a_info)
	info_struct.a_idx = a_idx
	info_struct.b_idx =b_idx
	info_struct.trace_name = trace_name
	Wave info_struct.trace_reference = TraceNameToWaveRef(graph_name,trace_name)
End Function

Static Function strings_equal(a,b)
	//	returns true if the strings are equal
	//
	//	Args:
	//		a/b: the two strings 
	//	Returns:
	//		0/1 if we didn't / did find them equal
	String a,b
	//cmpstr returns the following values:
	// -1:	str1  is alphabetically before str2.
	//  0:	str1  and str2  are equal.
	//  1:	str1  is alphabetically after str2.
	return (cmpstr(a,b) == 0)
End Function

Static Function string_ends_with(haystack,needle)
	//	returns true if haystack ends with needle
	//
	//	Args:
	//		haystack: where to search the end of 
	//		needle: the string we are looking for at the end of haystack
	//		(note that this defines a minimum length for haystack for this to work)
	//	Returns:
	//		0/1 if we didn't / did find them equal
	String haystack,needle
	Variable n_haystack = strlen(haystack), n_needle = strlen(needle)
	if (n_haystack < n_needle)
		return 0
	endif
	// POST: at least as many characters as we need (ie: n_needle)
	return ModIoUtil#strings_equal(haystack[n_haystack-n_needle,n_haystack],needle)
End Function


Static Function GetWindowLeftTopRightBottom(WindowName,left,top,right,bottom)
	String WindowName
	Variable &left,&top,&right,&bottom
	if (!WindowExists(WindowName))
		ModErrorUtil#DevelopmentError()
	EndIf
	// POST: window exists, go ahead and get the size
	// V-231, GetWindo
	// wsize Reads window dimensions into V_left, V_right, V_top, and V_bottom 
	// in points from the top left of the screen. For subwindows, values are local coordinates in the host.
	GetWindow $WindowName, wsize
	left = V_left
	right = V_right
	top = V_top
	bottom = V_bottom
End Function

Static Function GetScreenHeightWidth(width,height)
	Variable &width,&height
	// 0-th screen
	String InfoStr = IgorInfo(0)
	//	XXX check that regex doesnt fail
	String mRegex = ".*RECT=(\d+),(\d+),(\d+),(\d+);"
	String left,top,right,bottom
	SplitString/E=(mRegex) InfoStr, left,top,right,bottom
	width = str2num(right)-str2num(left)
	height= str2num(bottom)-str2num(top)
End Function

// Return if a given symbolic path exists
Static Function IgorPathExists(pathName)
	String pathName
	return strlen(PathList(pathName,ModDefine#DefListSep(),"")) > 0 
End Function

// Create an igor path for this system path. Does *not* overwrite by default. 
// If no path name is given, just gets a generic unique name (recommended)
Static Function /S GetIgorPathFromSys(sysPath,[pathName])
	String sysPath,pathName
	// Get the name of this path
	if (ParamIsDefault(pathName))
		pathName = UniquePathName()
	EndIf
	// make a path to the folder
	String mMessage = "Looking for folder [" + sysPath + "]..."
	NewPath /Q/M=(mMessage) $(pathName) (sysPath)
	if (V_FLAG != PATH_RET_SUCESS)
		ModErrorUtil#IoError(description="Couldn't make path [" + sysPath + "]")
	EndIf
	return pathName
End Function

Static Function  GetWavesWithStems(List,toRet,RecStems,[Sep])
	// Look through each element of "List", and return those which 
	// have waves with all extensions in "RecStems"
	Wave /T List
	Wave /T toRet
	String RecStems,Sep 
	if (ParamIsDefault(Sep))
		Sep = ModDefine#DefListSep()
	EndIF
	Variable NWaves = DimSize(List,0),NStems=ItemsInList(RecStems,Sep)
	// Make a wave at least as big as the incoming
	Make /O/N=(NWaves) /T spaceToRet
	Variable i=0, j=0,allStems=1, nFound = 0
	String tmp,tmpStem
	for (i=0; i< NWaves; i+=1)
		tmp = List[i]
		// Start off assuming we found everything
		allStems = 1
		// Ensure this wave has all stems
		for (j=0; j<NStems; j +=1)
			tmpStem = StringFromList(j,RecStems,Sep)
			// If the wave doesn't exist, go ahead and don't add to the list
			String checkExists = tmp + tmpStem
			If (!WaveExists($checkExists))
				allStems = 0
				break
			Endif
		EndFor
		// If we had every stem, add this
		if (allStems == 1)
			spaceToRet[nFound] = tmp
			nFound += 1
		EndIf
	EndFor
	// XXX assert nFound >= 1?
	Duplicate /O/R=[0,nFound-1]/T spaceToRet,toRet
	// Done with spaceToRet, kill freely
	KillWaves /Z spaceToRet
End Function

Static Function /S GetDirs(DirToSearch)
	String DirToSearch
	// Get the current working directory, to return
	String returnFolder = cwd()
	SetDataFolder $DirToSearch
	// get only data folders
	Variable mode = 1 
	// (For DataFolderDir)
	// Remove the last semi-colon/FOLDERS: predix
	// the separator string used by DataFolderDir
	String RegexDataFolderDir = "FOLDERS:([^;]+);"
	String OtherDirs = DataFolderDir(mode)
	// Remove the annoying prefix/suffix
	SplitString/E=(RegexDataFolderDir) OtherDirs, OtherDirs
	// return to the original folder
	SetDataFolder $returnFolder
	return OtherDirs
End

Static Function /S GetStems(StrList,StemRegex,Sep)
	// XXXX TODO: defunct, should call GetWaveStems
	String &StrList,StemRegex,Sep
	String tmp,ToRet="",tmpStem,tmpFull
	// Sort numerically (2), so "wave9" is before "wave10"
	Variable i, nStr =ItemsInList(StrList,Sep)
	// loop through each file, find the uniqu ones.
	for (i=0; i <nStr; i+=1)
		tmpFull = StringFromList(i,StrList,Sep)
		tmpStem = ModDataStructures#GetNameRegex(StemRegex,tmpFull)
		// new stem! Add tmpStem and incremenet the count
		toRet += ModDataStructures#GetListString(tmpStem,Sep)
	EndFor
	return toRet
End Function

Static Function GetWaveStems(mWaveList,toRet,StemRegex)
	Wave /T mWaveList
	Wave /T toRet
	String stemRegex
	Variable i, nStr = DimSize(mWaveList,0)
	// XXX make sure toRet is the same size?
	// loop through each file, find the uniqu ones.
	String tmpStem
	Redimension /N=(nStr) toRet
	for (i=0; i <nStr; i+=1)
		tmpStem = ModDataStructures#GetNameRegex(StemRegex,mWaveList[i])
		// new stem! Add tmpStem and incremenet the count
		toRet[i] = tmpStem
	EndFor
End Function

Static Function /Wave GetUniqueIndex(StrList,Sep)
	// place the uniquue indices of StrList into IdxWave
	// XXX assumes that IdxWave has been created
	String strList,Sep
	// Make a text wave for the list
	Wave /T tmp = ModDataStructures#MakeWaveForList("TmpUni",StrList,Sep)
	ModDataStructures#pListToTextWave(tmp,StrList,Sep=Sep)
	return GetUniTxtWaveIndex(tmp)
End Function 


Static Function GetSet(mWave,toRet)
	Wave /T mWave
	Wave /T toRet
	Wave mIndex = GetUniTxtWaveIndex(mWave)
	Variable nSet = DimSize(mIndex,0)
	Redimension /N=(nSet) toRet
	toRet[] = mWave[mIndex[p]]
End Function


Static Function /Wave GetUniTxtWaveIndex(StringWave)
	Wave /T StringWave
	// Keep track of what is unique...
	String Sep = ModDefine#DefListSep()
	String uniqueSorted =""
	Variable nPoints = DimSize(StringWave,0)
	// Make an array for the sorting index, and for the sorted array
	Make /O/N=(nPoints) sortIndex
	// Make an array to eventually return the sorted indices
	Make /O/N=(nPoints) retIdx
	Duplicate /T/O StringWave,sorted
	// Get the index to sort the array alphanumerically
	MakeIndex /A StringWave,sortIndex
	// sort 'sorted' by the appropriate index
	IndexSort sortIndex,sorted
	// POST: index is the ordering to sort tmp, sorted is the sorted version
	//Loop through the wave and determine which entries are unique
	Variable i=0,nUnique = 0,lastSortIdx =0
	// XXX assuming we have a first index...
	// Start at 1, since the first thing in sorted should be unique
	uniqueSorted = sorted[0] + Sep
	retIdx[0] = sortIndex[0]
	nUnique = 1
	for (i=1; i< nPoints; i += 1)
		lastSortIdx = nUnique-1
		String tmpStr = sorted[i]
		if (WhichListItem(tmpStr,uniqueSorted,Sep,lastSortIdx) < 0)
			// didnt find sorted[i] in uniqueSorted; add it
			uniqueSorted += ModDataStructures#GetListString(tmpStr,Sep)
			retIdx[lastSortIdx+1] = sortIndex[i]
			nUnique += 1
		EndIf
	EndFor
	// Duplictae only the indices we are interested in. 
	// Just get the first nUnique (0 to N-1)
	Duplicate /O/R=[0,nUnique-1] retIdx,UniIdx
	// Done with retIdx, sortIdx, and sorted go ahead and kill
	KillWaves /Z retIdx,sortIndex,sorted
	return UniIdx
End Function

Static Function /S GetFileName(Str,[DirSep,RemoveExt])
       String Str,DirSep
       Variable RemoveExt
       // Get a file name from a <DirSep>-separated string, assumign the file name
       // is everything from the last colon onwards
       if (ParamIsDefault(DirSep))
               DirSep = ModDefine#DefDirSep()
       endIf
       RemoveExt = ParamIsDefault(RemoveExt) ? ModDefine#False() : RemoveExt
       if (RemoveExt)
               // Remove the extension of the string before returning it
               str = RemoveExt(str)
       EndIf
       Variable colonIndex = GetLastIndex(str,DirSep)
       if (colonIndex > 0)
               // found a colon! Get the string from here to the end.
               return str[colonIndex+1,Inf]
       else
               // just return the whole thing, no colon found, no path/
               // XXX warning?
               return str
       EndIf
End Function

Static Function /S RemoveAfterLast(toMod,strToLookForLast)
       String toMod,strToLookForLast
       Variable colonIndex = GetLastIndex(toMod,strToLookForLast)
       if (colonIndex > 0)
               return toMod[0,colonIndex-1]
       else
               return toMod
       EndIf
End Function

Static Function /S RemoveExt(filePath)
       String filePath
       return RemoveAfterLast(filePath,EXT_START)
End Function

Static Function /S GetFileExt(filePath)
       String filePath
       Variable colonIndex = GetLastIndex(filePath,EXT_START)
       if (colonIndex > 0)
               return filePath[colonIndex,Inf]
       else
               return filePath
       EndIf
End Function

Static Function substring_exists(needle,haystack,[insensitive])
	// Returns: 1 if needle in haystack, false otherwise
	String needle,haystack
	Variable insensitive
	insensitive = ParamIsDefault(insensitive) ? 0 : insensitive
	Variable options = 0 
	// From  strsearch (last is optional)
	// 1:	Search backwards from start.
	// 2:	Ignore case.
	// 3:	Search backwards and ignore case.	
	If (insensitive)
		options = options | 0x2	 
	EndIf 
	// strsearch returns -1 if the substring exists; otherwise just the index 
	return strsearch(haystack,needle,0,options) > -1
End Function 

Static Function GetLastIndex(Str,Sep)
	// Returns: the last index of sep in string
       String str,Sep
       Variable optSearchBackwards = 1
       Variable colonIndex = strsearch(str,Sep,Inf,optSearchBackwards)
       return colonIndex
End Function

// gets the directory of a file name (everything before  the first colon)
Static Function /S GetDirectory(filePath,[DirSep])
	String filePath,DirSep
	if (ParamISDefault(DirSep))
		DirSep = ModDefine#DefDirSep()
	EndIf
	Variable colonIndex = GetLastIndex(filePath,DirSep)	
	if (colonIndex > 0)
		return filePath[0,colonIndex]
	Else
		// entire thing was a path
		return filePath
	EndIf
End Function

Static Function /S GetAllFileNames(StrList,ListSep,DirSep)
	String StrList,ListSep,DirSep
	String toRet="", tmpPath,tmpFile
	Variable i, nItems = ItemsInList(StrList,ListSep)
	for (i=0; i<=nItems; i+= 1)
		tmpPath= StringFromList(i,StrList,ListSep)
		tmpFile = GetFileName(tmpPath,DirSep=DirSep)
		toRet += ModDataStructures#GetListString(tmpFile,ListSep)
	EndFor
	toRet = ReplaceString(ListSep + ListSep,toRet,ListSep)
	return toRet
End Function	

Static Function /S GetDirPathFromFilePath(FilePath,[Sep])
	// Return everything 
	String FilePath,Sep
	If (ParamISDefault(Sep))
		Sep = ModDefine#DefDirSep()
	EndIf
	String toRet ="",File=""
	// Everything up to and including the colon
	String mRegex = "(.+:)(.+)"
	SplitString /E=(mRegex) FilePath,toRet,File
	return toRet
End Function

Static Function EnsurePathExists(mPath,[Sep])
	// Follows the same concention as NewDataFolder, but adds directories one at a time
	// In other words, if the path does *not* start with root,
	String mPath
	String Sep
	If (DataFolderExists(mPath))
		// We are done here! Fast short-circuit
		return ModDefine#True()
	EndIF
	if (ParamIsDefault(Sep))
		Sep = ModDefine#DefDirSep()
	EndIf
	// POST: we know the separation. 
	// From out point of view, each directory is an element in a string list
	Variable nSubDirs = ItemsInList(mPath,Sep)
	// XXX check that itemsinList >= 1
	Variable i=0
	String tmpPath
	// Determine if this is a relative path, or a path from root.
	// If we are starting from root, don't both checking (skip over root)
	if (cmpstr(StringFromList(0,mPath,Sep),DEF_ROOTNAME) != CMPSTR_MATCH)
		// this is a path relative to the current folder. Need to add a separator
		tmpPath = Sep
		i=0
	Else
		// Starts from root
		tmpPath = "root:"
		// start with the second path, if there is one
		i=1
	EndIf
	// POST: tmpPath is set up properly for absolute and relative paths
	// Note that the starting index is set based on if this is relative or abs
	For (; i< nSubDirs; i+= 1)
		tmpPath += StringFromList(i,mPath,Sep)
		if (!DataFolderExists(tmpPath))
			// Then make it
			NewDataFolder $tmpPath
		EndIf
		// add a separator for the next path
		tmpPath += Sep
	EndFor
End Function
	
Static Function/S GetWaveList(RootFolder, ListSep,DirSep,[RegExpr])
	// This function is used to get the names of all waves in RootFolder.
	// This is useful (for example), since the cypher apparently likes to
	// label everything under invisible subfolders
	String RootFolder,ListSep,DirSep,RegExpr
	String toRet,tmpStem
	// Save the original path, so we can go back
	String original = cwd()
	// set to the appropriate
	// XXX check that this folder exists?
	// XXX whenever we set, should make it safe, set back when we are done
	SetDataFolder $RootFolder
	// Get the list of waves here (get everything "*")
	toRet = WaveList("*",ListSep,"")
	// Prepend, so we have the full path. Make sure that there are no double colons in RootFolder,
	// but ensure it ends in a colon, by removing all double colons
	RootFolder = ReplaceString(DirSep+DirSep,RootFolder + DirSep,DirSep)
	toRet = ModDataStructures#PrependToItems(toRet,RootFolder,ListSep)
	// Match the Regex
	if (!ParamIsDefault(Regexpr))
		toRet = GrepList(toRet,RegExpr,GREP_SELECT_MATCHING,ListSep)
	EndIf
	// Get the other dirs, rootedHere
	String OtherDirs =GetDirs(RootFolder)
	// If there is nothing left to check, don't recurse
	Variable nDirs = ItemsInList(OtherDirs,ListSep)
	If (nDirs == 0)
		return toRet
	EndIf
	// POST: at least one directory to check
	Variable i
	String newDir
	String subWaves
	for (i=0; i< nDirs; i += 1)		
		// Note: rootfolder ends in a colon
		newDir = RootFolder + StringFromList(i,OtherDirs,ListSep)
		If (!DataFolderExists(newDir))
			String mErrStr
			sprintf mErrStr,"Folder %s should exist, but I can't find it\n",newDir
			MOdErrorUtil#DevelopmentError(description=newDir)
		EndIf
		if (!ParamIsDefault(Regexpr))
			subWaves = GetWaveList(newDir,ListSep,DirSep,RegExpr=RegExpr)
		Else
			subWaves = GetWaveList(newDir,ListSep,DirSep)
		endif
		// concatenate toRet with subwaves, and overright suwaves
		ModDataStructures#ConcatLists(toRet,subWaves,toRet,ListSep)
	endfor
	SetDataFolder $original
	return toRet
End

Static Function WindowExists(mName)
	// Returns true if the given window exists
	// 	Args:
	//		mFile: the igor-style path to the window
	//	Returns:
	//		0/1 if the file exists/doesnt exist
	String mName
	Variable Type = WinType(mName)
	return type != WINTYPE_NOT_A_WINDOW
End Function

Static Function SafeKillWindow(mName)
	String mName
	if (WindowExists(mName))
		// Save to kill it
		KillWindow $mName
	EndIf
End Function

Static Function Tic()
	return DateTime
End Function

Static Function /S SecsToTime(secs)
	Variable secs
	return Secs2Time(secs,SEC2TIME_FMT_ELAPSED_FULL,SEC2TIME_DIG)
End Function	

Static Function /S SecsToDate(secs,[sep])
	Variable secs
	String Sep
	if (ParamIsDefault(Sep))
		Sep = DEF_DATE_SEP
	EndIf
	return Secs2Date(secs,SEC2DATE_FMT,DEF_DATE_SEP)
End Function

Static Function DateFmtToSecs(year,month,day,hour,minute,second,fraction)
	Variable year,month,day,hour,minute,second,fraction
	Variable secs = date2secs(year,month,day)
	// add in the fractional parts of the day
	secs += fraction + second + secsPerMin*minute + secsPerhour*hour
	return secs
End Function	

Static Function Toc(ticVal,[printTime])
	Variable ticVal, printTime
	printTime = ParamIsDefault(printTime) ? ModDefine#True() : printTime
	Variable now = DateTime
	Variable delta = now-ticVal
	if (printTime)
		String mTime= SecsToTime(delta)
		Printf "HH/MM/SS:.ss: %s\r",mTime
	EndIF
	return now
End Function

Static Function /S GetPathFromString(StrV)
	// Given a string, returns the full, system path
	// If StrV points to an igor path, uses that
	// If no such path exists, throws an error
	String StrV
	String mPath = StrV
	if (!FileExists(mPath))
		// Look for this as an igor path
		mPath = SysPathFromIgor(StrV)
		ModErrorUtil#Assert(FileExists(mPath),msg="Couldn't find path")
	EndIf
	return mPath
End Function

Static Function /S string_element(list,index,[sep])
	// convenience wrapper for using igor-style string lists
	//
	// Args;
	//	list: the <separator> separated list
	//	index: which 0-based element is wanted
	//	sep: third argument to stringfromlist; separator in list 
	// Returns
	//	Relevant element, assuming index is in bounds. Else, see StringFromList
	String list,sep
	Variable index
	If (ParamIsDefault(sep))
		sep = ";"
	EndIf
	return StringFromList(index,list,sep)
End Function

Static Function /S pwd_igor_path(path_name,[n_up_relative])
	// prints the OS-specific working directory at path_name, moving up 
	// n_up_relative times 
	//
	// Args;
	// path_name: the igor path name of interest
	// n_up_relative: the (defaulted zero) number of steps *up* to take,
	// relative to path_name.  
	
	// Returns
	//	the absolute OS-specific path 
	// /Z: Get ingormation only if it eists
	String path_name
	Variable n_up_relative;
	GetFileFolderInfo /Q/Z/P=$(path_name);
	ModErrorUtil#Assert(V_flag == 0 ,msg=("Couldn't find path" + path_name));
	// POST: found the path.
	String current_path = S_path;
	if (n_up_relative > 0)
		//The optional options parameter is a bitmask specifying the search options:
		// 1: Search backwards from start.
		String path_delim = ":";
		Variable options = 0x1;
		Variable start = strlen(S_path);
		Variable n_found = 0
		do
			Variable loc = strsearch(current_path,path_delim,start,options);
			ModErrorUtil#Assert(loc > 0 ,msg=("Couldn't find enough levels in" + current_path));
			start = loc-1
			n_found = n_found + 1
		while (n_found < n_up_relative)
		// POST: have a substring we care about; modify the path 
		current_path = current_path[0,loc];
	endif
	return current_path
End Function

Static Function FileExists(mFile)
	// Returns true is the give igor-style path for mFile exists
	// 	Args:
	//		mFile: the igor-style file path passed to GetFileFolderInfo
	//	Returns:
	//		0/1 if the file exists/doesnt exist
	String mFile
	// For flags, see get folder interactive.
	GetFileFolderInfo /Q/Z=(GETFILEFOLDER_ONLYEXISTING) mFile
	Return V_FLAG == GETFILEFOLDER_RETSUCESS
End Functon

Static Function GetFolderInteractive(NameReference)
	// If user picks a folder, sets NameReference to it, returns true.
	// Else (doesn't exist, user cancelled), returns false
	//
	//	Args:
	//		NameReference: reference to a string, which will be set to what the user says 
	//		on success 
	//	Returns:
	//		True on success, false on failure
	String &NameReference
	// /D : opens dialog
	// /Q: quiet
	// /Z: only get information about existing files
	// V-214 of igor manual
	GetFileFolderInfo /D/Q/Z=(GETFILEFOLDER_INTERACTIVE)
	// Side effect: this sets 
	// XXX check that this is really a folder?
	// V_Flag is zero if the file or folder was foud 
	if (V_Flag == GETFILEFOLDER_RETSUCESS)
		NameReference = S_Path
		return ModDefine#True()
	Else
		return ModDefine#False()
	endIf
End Function

Static Function GetFileInteractive(NameReference)
	String & NameReference
	// V-214
	// /Q: quiet
	// /Z: way to handle errors
	// No file name given: use dialogue
	GetFileFolderInfo /Q/Z=(GETFILEFOLDER_INTERACTIVE)
	if (V_FLAG == GETFILEFOLDER_RETSUCESS && V_isFile)
		// Then we found the file!
		NameReference = S_Path
		return ModDefine#True()
	Else
		return ModDefine#False()
	EndIf
End Function

// A function to take a file (e.g. a pxp file) which will be loaded, and  determine a folder name for it
// XXX add uniqueness condition?
Static Function /S GetDataLoadFolderName(mFilePath,[isDir])
	String mFilePath
	Variable isDir
	isDir = ParamIsDefault(isDir) ? ModDefine#False() : isDir
	String mFileName
	if (!isDir)
		mFileName = GetFileName(mFilePath,RemoveExt=ModDefine#True())
	Else 
		mFileName = GetLastDirectory(mFilePath)
	EndIf
	 return Sanitize(mFileName)
End Function

// Function to get the loadable extensions of files
Static Function /Wave GetLoadableExt()
	Make /O/T IoLoadable = {FILE_EXT_IGOR_PACKED_EXP, FILE_EXT_IGOR_BIN_WAVE,FILE_EXT_IGOR_TXT}
	return IoLoadable
End Function

// Function to load all relevant files from mFolder into dataFolder locToLoadInto,
// looking for files in validExtensions recursively.
Static Function LoadIgorFilesInFolder(mFolder,[locToLoadInto,validExtensions])
	String mFolder,locToLoadInto
	Wave /T validExtensions
	// If we don't specify a location, just load here
	if (ParamIsDefault(locToLoadInto))
		LocToLoadInto = cwd()
	EndIf
	// If we don't specify valid extensions, use them all
	if (ParamIsDefault(validExtensions))
		Wave /T validExtensions = GetLoadableExt()
	EndIf
	// POST: know where to load with what extensions
	// XXX check that folder exists?
	Variable i, nExts = DimSize(validExtensions,0)
	Make /O/T/N=(0) mFiles
	Make /O/T/N=(0) tmpFiles
	// Loop through every extension, get all the files
	for (i=0; i <nExts; i+=1)
		// 'rezero' tmpFiles, so we dont continuously add them 
		DeletePoints 0,Inf,tmpFiles
		ModIoUtil#GetFoldersAndFiles(mFolder,tmpFiles,extension=validExtensions[i])
		// Concatenate the tmp wave with the normal file wave
		Concatenate /NP/DL/T {tmpFiles},mFiles
	EndFor
	// POST: mFiles has all the files we want.
	// Go ahead and load them all.
	Variable nFiles = DimSize(mFiles,0)
	for (i=0; i<nFiles; i+=1)
		LoadFile(mFiles[i],locToLoadInto=locToLoadInto)
	EndFor
	// POST: all files loaded.
	KillWaves /Z validExtensions,tmpFiles,mFiles
End Function

// Loads "mFilePath" into  "locToLoadInto". If "ifPresentLoadIntoFileFolder" is set,
// derives (ie: sets and uses) "locToLoadInto" from a (sanitized) version of mFilePath
Static Function LoadInteractive(mFilePath,locToLoadInto,[ifPresentLoadIntoFileFolder,subfolder])
	// Savely and interactively loads, acconting for overwrites
	// Sets "mFilePath" to the full (system) path loaded
	// Sets "folderRelLocToLoad" to where the data was loaded, relative to locToLoad
	// Returns true if something was loaded (ie: user didn't cancel)
	String locToLoadInto,subfolder
	String & mFilePath // the full Path, to be updated by referende
	String & ifPresentLoadIntoFileFolder
	if (ParamIsDefault(subFolder))
		subfolder = ""
	EndIf
	if (GetFileInteractive(mFilePath))	
		if (!ParamIsDefault(ifPresentLoadIntoFileFolder))
			// Then we need to determine the folder name for this file.
			ifPresentLoadIntoFileFolder = GetDataLoadFolderName(mFilePath)
			// Append the path to mFileFolder
			locToLoadInto = ModIoUtil#AppendedPath(locToLoadInto,ifPresentLoadIntoFileFolder)
		EndIf
		// return whether load file worked.
		return LoadFile(mFilePath,locToLoadInto=locToLoadInto,subfolder=subfolder)
	else	
		// We didn't load anything
		return ModDefine#False()
	EndIf
End Function


// Funcion to load system file "mFilePath" into data folder "locToLoadInto",
// IF getRelLocFromFileName, then we set folderRelLoc to a new folder based on the file name
// and load there
Static Function LoadFile(mFilePath,[locToLoadInto,subfolder,delimStr,skipLines])
	// XXX allow for non-interactive
	// XXX check that incoming file names are unique.
	String mFilePath // the full Path, *assumed already populated*
	String locToLoadInto,subfolder,delimStr
	Variable skipLines
	// Whether or not we loaded
	Variable toRet = ModDefine#False()
	if (ParamIsDefault(skipLines))
		skipLines = 0
	EndIF
	if (ParamIsDefault(delimStr))
		delimStr = DEF_LOADFILE_DELIM 
	EndIf
	if (ParamIsDefault(subfolder))
		subfolder = LOAD_FOLDER_NO_EXTRA_DIR
	EndIf
	if (ParamIsDefault(locToLoadInto))
		// just load here.
		locToLoadInto = ModIoUtil#cwd()
	EndIf
	// POST: RelLocToLoad exists. 
	// See: V-354
	// /O: overwrite mode
	// /T=<string>: load into loacation
	// /Q: quietly load
	// /R: recursively load subfolders
	// Don't need a file string, since file choice will be done interactively
	// Then the user actually selected something. Assumng we can load it, we return true
	toRet = modDefine#True()
	// Want to give this file its own experiment. Use its file name 
	String mFileExt = GetFileExt(mFilePath)
	// Go to the temporary directory
	String original = ModIoUtil#cwd()
	// Ensure where we want to go exists
	ModIoUtil#EnsurePathExists(locToLoadInto)
	// Change to wherever we are loading.
	SetDataFolder $(locToLoadInto)
	// POST: in the proper directory, figure out how to load this file
	strswitch (mFileEXT)
	// XXX check that this name is of an appropriate size.
		case FILE_EXT_IGOR_PACKED_EXP:
			// Load the data as normal (see binary wave, below)
			LoadData /O=(LOADDATA_DEF_OVERWRITE)/Q/R/S=(subfolder)(mFilePath)
			break
		case FILE_EXT_IGOR_BIN_WAVE:
			// Load the waves present in this file
			// V-362
			// /W: read wave names form the file
			// /D: double precision
			// /H: load into the current experiment
			// /O: overwrite
			// /Q: silent.
			LoadWave /Q/O/W/D/H (mFilePath)
			break
		case FILE_EXT_IGOR_TXT:
			// See FILE_EXT_IGOR_BIN_WAVE, but we need to add:
			// /T: igor text format
			LoadWave /Q/O/W/D/H/T (mFilePath)
			break
		case  FILE_EXT_CSV:
		case  FILE_EXT_TXT:
			// /A, /W: skip the name diaalogue, get from the file
			// /M: load as (single) matrix
			// /J: delimited text format
			// /K: determine how to get columns types
			LoadWave /Q/O/W/D/H/M/A/J/K=(LOADWAVE_COLTYPE_AUTO) /V={delimStr,LOADWAVE_SKIPCHARS,LOADWAVE_DEF_CONVERSIONS,LOADWAVE_DEF_FLAGS}/L={0,skipLines,0,0,0} (mFilePath)
			break
		default:
			// XXX add in supported extension
			String mAlert
			sprintf mAlert, "Didn't recognize how to load file type with extension %s.\nGiving up on loading input file:\n%s.\n",mFileExt,mFilePath
			ModErrorUtil#AlertUser(mAlert)
			// we *didnt* actually load the file, so return false
			toRet = ModDefine#False()
	EndSwitch
	SetDataFolder $(original)
	return toRet
End Function


Static Function /S cwd()
	// Returns: the path of the current working directory
	return GetDataFolder(GETDATAFOLDER_FULLPATH)
End Function

Static Function /S UniqueGraphName(base,[startSuffix])
	String base
	Variable startSuffix
	startSuffix =  ParamIsDefault(startSuffix) ? 0 : startSuffix
	return UniqueName(base,UNIQUENAME_GRAPH,startSuffix)
End Function


Static Function /S UniqueAnnotationName(graphName,[base,startSuffix])
	String base,graphName
	Variable startSuffix
	if (ParamIsDefault(base))
		base = "Text"
	EndIf
	startSuffix =  ParamIsDefault(startSuffix) ? 0 : startSuffix
	return UniqueName(base,UNIQUENAME_ANNOTATION,startSuffix,graphName)
End Function

Static Function /S UniqueControlName(base,[startSuffix])
	String base
	Variable startSuffix
	startSuffix =  ParamIsDefault(startSuffix) ? 0 : startSuffix
	return UniqueName(base,UNIQUENAME_Control,startSuffix)
End Function

Static Function /S UniquePanelWindowName(base,[startSuffix])
	String base
	Variable startSuffix
	startSuffix =  ParamIsDefault(startSuffix) ? 0 : startSuffix
	return UniqueName(base,UNIQUENAME_PANELWINDOW,startSuffix)
End Function

Static Function /S UniqueFolder(base,[startSuffix])
	String base
	Variable startSuffix
	startSuffix =  ParamIsDefault(startSuffix) ? 0 : startSuffix
	return UniqueName(base,UNIQUENAME_DATAFOLDER,startSuffix)
End Function

Static Function /S UniqueWave(base,[StartSuffix])
	String base
	Variable startSuffix
	startSuffix =  ParamIsDefault(startSuffix) ? UNQUENAME_DEF_SUFFIX : startSuffix
	return UniqueName(base,UNIQUENAME_Wave,startSuffix)
End Function

// initialize a unique wave. only recommended for plotting; could cause memory leaks
Static Function /Wave InitUniWave([base])
	String base
	if (ParamIsDefault(base))
		base = DEF_WAVE_NAME
	EndIf
	String trueName = UniqueWave(base,startSuffix=UNQUENAME_DEF_SUFFIX)
	// *dont* use /O: should be unique...
	Make /N=0 $trueName
	Wave toRet = $trueName
	return toRet
End Function

Static Function /S UniquePathName([base,startSuffix])
	String base
	Variable startSuffix
	if (ParamIsDefault(base))
		base = DEF_PATHNAME
	EndIf
	startSuffix =  ParamIsDefault(startSuffix) ? UNQUENAME_DEF_SUFFIX : startSuffix
	return UniqueName(base,UNIQUENAME_PATH,startSuffix)
End Function

Static Function /S Sanitize(mStr)
	String mStr
	return CleanupName(mStr,CLEANUP_NAME_STRICT)[0,MAX_STRLEN-1]
End Function

Static Function InWave(Needle,HayStack,[Index])
	Variable Needle
	Wave HayStack
	// set the index *value* (pass by reference) if we want it)
	Variable & index
	// V-182: FindVaule sets V_Value to -1 if it is not found
	// Note that we are using Long precision numbers.
	FindValue /U=(Needle) HayStack
	if (!ParamIsDefault(index))
		index = V_Value
	EndIf
	// if V_Value>=0, then the index was found
	return V_Value >=0
End Function 

Static Function IsFinite(Value)
	Variable Value
	return numtype(Value) == NUMTYPE_NORMAL
End Function

Static Function save_as_comma_delimited(output_wave,file_path,[append_flag,newline])
	// saves the (assumed 1D) wave to a row of the output_wave
	// XXX allow for saving matrices
	//
	// 	Args:
	//		output_wave: (text) wave to save out
	//		file_path: igor-style full path to save
	//		append_flag: passed to the /A flag of "Save". Defaults to 0 (dont append)
	//		newline: what to use for a newline. defaults to \n (Unix)
	Wave /T output_wave
	String file_path,newline
	Variable append_flag
	append_flag = ParamIsDefault(append_flag) ? 0 : append_flag
	if (ParamIsDefault(newline))
		newline = "\n"
	endIf
	// POST: we know all the parametes
	// go ahead and make the comma list
	Variable columns = min(1,DimSize(output_wave,1))
	Variable rows = DimSize(output_wave,0)
	Variable n = rows
	// Add in commas betwen each element for a csv
	Make /FREE/T/N=(2*n-1) with_commas 
	// very last character will be a newline
	Variable n_with_commas = DimSize(with_commas,0)
	// all even elements are just the data (p runs from 0,2,4,... so p/2 is 0,1,2,...)
	with_commas[0,n_with_commas-1;2] = output_wave[p/2]
	// all odd elements are commas
	with_commas[1,n_with_commas-1;2] = ","
	// Transpose the matrix; igor has awful conventions
	MatrixTranspose with_commas
	// /A=2: append as-is, dont add newline (A=1 adds newline)
	// /G: save in general text format
	// /J: tab delimited
	Save /A=(append_flag)/G/M="\n" with_commas as file_path
End Function

 Static Function SaveWaveDelimited(ToSave,Folder,[Name])
	Wave ToSave
	// Save the wave "ToSave" to "FilePath:Name"
	// If  Name is null, just uses the wave name
	// XXX make sure wave exists?
	String Folder,Name
	Variable SaveXScale
	If (ParamIsDefault(Name))
		Name = NameOfWave(ToSave)
	EndIf
	Folder = GetPathFromString(Folder)
	String FullPath = AppendedPath(Folder,Name)
	// Make sure we have an itx format
	FullPath= EnsureEndsWith(FullPath,FILE_EXT_IGOR_TXT)
	// V-546
	// /O: Overwrites
	// /J: saves as tab-delimited format
	// /T: save as igor text file
	// /W: includes wave name
	Save /O/T/W ToSave as FullPath	
End Function

Static Function DateStrToTime(str,[sep])
	// assume sep is like <year>[sep]<month>[sep]<day>
	String str,sep
	if (ParamIsDefault(Sep))
		Sep = DEF_DATE_SEP
	EndIf
	String DateRegex
	sprintf DateRegex,"(\d{4})%s(\d{1,2})%s(\d{1,2})",sep,sep
	String yearStr,monthStr,dayStr
	SplitString /E=(DateRegex) str,yearStr,monthStr,dayStr
	Variable year = str2num(yearStr)
	Variable month = str2num(monthStr)
	Variable day = str2num(dayStr)
	Variable mStrtime = date2secs(year,month,day)
	return mStrtime
End Function

Static Function /S GetPathToWave(mWave)
	//
	// Args:
	//		mWave:  wave to get 
	// Returns:
	//'		The *full* path to the wave (including the wave name itself)
	Wave mWave
	return GetWavesDataFolder(mWave,GETWAVES_DF_FULL_PATH)
End Function

Static Function /S path_to_wave_name(wave_str)
	// See : GetPathToWave, except takes a string as input
	// Args:
	//	wave_str: string name of wave
	// Returns:
	//	see GetPathToWave
	String wave_str
	Wave tmp = $(wave_str)
	return GetPathToWave(tmp)
End Function

Static Function /S MakeSymbolicPath(osPath)
	String osPath
	String pathName = ModIoUtil#UniquePathName()
	// V-455
	// /O: overwrite if it exists
	// /Q: surpresses printing in history
	NewPath /O/Q $(pathName), (osPath)
	return pathName
End Function

Static Function /S SysPathFromIgor(IgorPath)
	String IgorPath
	if (!PathExists(IgorPath))
		// XXX throw error?
		return ""
	EndIf
	PathInfo $IgorPath
	// Sets S_Path to the full path
	return S_Path
End Function

Static Function PathExists(mPath)
	String mPath
	PathInfo $mPath
	return V_FLAG == PATHINFO_EXISTS
End Function

// Adapted from  V-314
// GetFoldersAndFiles(pathName, extension, recurse, level)
// Shows how to recursively find all files in a folder and subfolders.
// pathName is the name of an Igor symbolic path that you created
// using NewPath or the Misc->New Path menu item.
// extension is a file name extension like ".txt" or "????" for all files. // recurse is 1 to recurse or 0 to list just the top-level folder.
// level is the recursion level - pass 0 when calling GetFoldersAndFiles. // Example: GetFoldersAndFiles("Igor", ".ihf", 1, 0)
Function GetFoldersAndFiles(pathName, waveToPop,[extension, recurse, level])
	String pathName
	Wave /T waveToPop
	String extension
	Variable recurse
	Variable level
	// recurse by default
	recurse = ParamIsDefault(recurse) ? ModDefine#True() : recurse
	// Extension matches all files by default
	if (ParamIsDefault(extension))
		extension =  INDEXEDDIR_ALL_FILES
	EndIf
	if (ParamIsDefault(level))
		level = INDEXDIR_DEF_LEVEL
	EndIf
	// POST: all parameters defined
	// Ensure that the path exists
	if (!pathExists(pathName))
		pathName = MakeSymbolicPath(pathName)
	EndIf
	// POST: pathname is a proper symbolic path
	// Name of symbolic path in which to look for folders and files. // File name extension (e.g., ".txt") or "????" for all files. // True to recurse (do it for subfolders too).
	// Recursion level. Pass 0 for the top level.
	Variable folderIndex, fileIndex
	String prefix// Build a prefix (a number of tabs to indicate the folder level by indentation)
	prefix = ""
	folderIndex = 0
	do
	   if (folderIndex >= level)
	       break
	   endif
	    folderIndex += 1
	while(ModDefine#True())
	 // Print folder
	 String path
	 PathInfo $pathName
	 path = S_path
	 // Print files
	 fileIndex = 0
	 do
	       String fileName
	       fileName = IndexedFile($pathName, fileIndex, extension)
	       if (strlen(fileName) == 0)
			break 
		endif
		// XXX probably inefficient to make a new wave each time...
	      	Make /O/T tmpFolderFile = {path + fileName}
		 Concatenate /NP/T {tmpFolderFile},waveToPop
	       fileIndex += 1
	 while(ModDefine#True())
	if (recurse) // Do we want to go into subfolder? folderIndex = 0
	       do
	          path = IndexedDir($pathName, folderIndex, INDEXEDDIR_FULL_PATH)
	          if (strlen(path) == 0)
				break // No more folders 
		   endif
	          String subFolderPathName = "tempPrintFoldersPath_" + num2istr(level+1)
	          // Now we get the path to the new parent folder
	          String subFolderPath
	          subFolderPath = path
	          NewPath/Q/O $subFolderPathName, subFolderPath
	          GetFoldersAndFiles(subFolderPathName, waveToPop,extension=extension, recurse=recurse, level=level+1)
	          KillPath/Z $subFolderPathName
	          folderIndex += 1
	       while(ModDefine#True())
	endif 
	// /A : Alpahanumeric sort, pp V-596
	// /R: reverse order
	Sort /A/R waveToPop,waveToPop
	KillWaves /Z tmpFolderFile
End Function

// function which gets the Last directory in a path, with a pattern like:
// <anything>:<directory>:<fileName>
Static Function /S GetLastDirectory(mDirPath)
	String mDirPath
	String pre,lastDir
	SplitString /E=(MATCH_LAST_DIR) mDirPath,lastDir
	return lastDir
End Function

Static Function /S GetUnits(mWave,dim)
	Wave mWave
	Variable dim
	// XXX check it exists?
	return WaveUnits(mWave,dim)
End function

Static Function /S GetYUnits(mWave)
	Wave mWave
	return GetUnits(mWave,1)
End Function

Static Function /S GetXUnits(mWave)
	Wave mWave
	return GetUnits(mWave,0)
End Function

Static Function GetMaxX(mWave)
	Wave mWave
	Variable n = Dimsize(mWave,0)
	return pnt2x(mWave,n)
End Function

// returns if it matches, sets if so (strToSet is pass by reference)
Static Function set_and_return_if_match(haystack,pattern,set_on_match)
	// attempts to match a string; returns the matching result and sets 
	// a pass-by-reference string if it suceeeds
	//
	// Args:
	//	haystack: the needle to search in
	// 	pattern: the regeular expression to use 
	// 	set_on_match: the string which is set on a expression match
	// Returns:
	//	True if we have a match
	String haystack,pattern,&set_on_match
	if (GrepString(haystack,pattern))
		// Our experiment exists
		SplitString /E=(pattern) haystack, set_on_match
		return ModDefine#True()
	EndIf
	return ModDefine#False()
End Function

Static Function GetUniqueStems(tmpUnique,baseDir,SuffixNeeded,[fullPathStemPattern,listSep,DirSep])
	Wave /T tmpUnique 
	String baseDir,SuffixNeeded,listSep,DirSep,fullPathStemPattern
	if (ParamIsDefault(fullPathStemPattern))
		// everything up to and including the digit identifier in the wave
		fullPathStemPattern = "(.+:[^:\d]+\d+)" 
	EndIf
	if (ParamIsDefault(ListSep))
		ListSep = ModDefine#DefListSep()
	EndIf
	if (ParamISDefault(dirSep))
		dirSep = ModDefine#DefDirSep()
	EndIf
	// Get just the last file
	String FileRegex = ModIoUtil#DefFileRegex()
	// POST: suffixNeed is not null
	String mWaves = ModIoUtil#GetWaveList(baseDir,ListSep,dirSep)
	// Convert mWaves to a text wave, which is easier to work with
	Variable NFullWaves = ItemsInList(mWaves,listSep)
	Variable toRet = 0
	// No waves found
	if (nFullWaves == 0)
		return toRet
	EndIf
	Make /O/N=(NFullWaves)/T rawWaves
	ModDataStructures#pListToTextWave(rawWaves,mWaves,Sep=ListSep)
	// get all the 'fullpath' stems
	Make /O/N=(NFullWaves)/T fullPathStemsRaw
	 ModIoUtil#GetWaveStems(rawWaves,fullPathStemsRaw,FullPathStemPattern)
	 // Use the stems to get the files with the appropriate suffixes.
	Make /T/O/N=(0) fullPathWithPrefix 
	ModIoUtil#GetWavesWithStems(fullPathStemsRaw,fullPathWithPrefix,SuffixNeeded,Sep=ListSep)
	// post: tmpAllWaves has all the waves with appropriate suffixes.
	// Get the new path stems (see below):
	Variable nWaves = DImSize(fullPathWithPrefix,0)
	// check that we found waves.
	if (nWaves == 0)
		return toRet
	EndIf
	Make /O/N=(nWaves)/T filePathStems
	 ModIoUtil#GetWaveStems(fullPathWithPrefix,filePathStems,FullPathStemPattern)
	 // Make a wave for the file *stems* (ie: "DNA_130ng_ul", not "foo:bar:X0506060:DNA_130ng_ulForce"")
	 Make /O/N=(NFullWaves)/T mFileStems
	 ModIoUtil#GetWaveStems(filePathStems,mFileStems,FileRegex)
	 // Get which file stems are unique. This is so we only have one file like (e.g. "foo0010")
	 // We know from above it will have the recquired prefixes (multiple prefixes are what
	 // can give us non-unique stems, e.g. "foo0010Sep and foo0010Force each have the file stem
	 // foo0010
	 Wave tmpUniIdx = ModIoUtil#GetUniTxtWaveIndex(mFileStems)
	 // Get just the unique waves; need a wave for the unique and the non-unique waves
	 Variable NUnique = DImSIze(tmpUniIdx,0)
	 if (NUnique == 0)
	 	return toRet
	 EndIf
	 Redimension /N=(NUnique) tmpUnique
	 // The next line slices tmpUnique from 0--> N-1 on both sides
	 // It assigns the waveNames at each sorted index in order
	 // essentially, 'p' is an igor-approved stand-in for "0,(NUnique-1)"
	 // XXX functionalize to a slice method?
	 // XXX ensure /NUnique > 1?
	tmpUnique[] = filePathStems[tmpUniIdx[p]]
	KillWaves /Z tmpAllWaves,tmpUniIdx,mFileStems,filePathStems
End Function