#pragma rtGlobals=3        // Use strict wave reference mode
#pragma ModuleName=ModDataStructures
#include ":Defines"

Constant CMPSTR_EQ = 0
// V-143, You can add selector values to test more than one field at a time or pass -1 to compare all aspects.
Constant EQUALWAVES_FULL = -1
Constant EQUALWAVES_DATAONLY = 1
Constant EQUALWAVES_DEFTOL =1e-8
//Wavetype constant
CONSTANT WAVETYPE_SEL_TYPES = 1
Constant WAVETYPE_IS_STR = 2

// case insenitive match
Constant CMPSTR_CASE_IN = 0 
Constant CMPSTR_MATCH = 0 

Static Function EndsWith(Needle,Haystack,[CaseSensitive])
	String Needle,Haystack
	Variable CaseSensitive
	CaseSensitive = ParamIsDefault(CaseSensitive) ? CMPSTR_CASE_IN : CaseSensitive
	Variable lenNeedle = strlen(Needle)
	Variable lenHaystack = strlen(HayStack)
	// If the Needle *can* be found, then perform the cmpstr
	if (lenHayStack >= lenNeedle && lenNeedle > 0)
		String mSearch = Haystack[lenHaystack-lenNeedle,lenHayStack-1]
		return cmpstr(mSearch,Needle,CaseSensitive) == CMPSTR_MATCH
	EndIf
	// POST: bad length, doesnt work
	return ModDefine#False()
End Function

// WaveType V-751
// If selector = 1, WaveType returns 0 for a null wave, 1 if numeric, 2 if string ... 
Static Function IsTextWave(mWave)
	Wave mWave
	return WaveType(mWave,WAVETYPE_SEL_TYPES) == WAVETYPE_IS_STR
End Function

Static Function WavesAreEqual(WaveA,WaveB,[options,tolerance])
	Wave WaveA,WaveB
	Variable options,tolerance
	options = ParamIsDefault(options)? EQUALWAVES_FULL : options
	tolerance = ParamIsDefault(tolerance) ? EQUALWAVES_DEFTOL : tolerance
	// XXX add in tolerance
	return EqualWaves(WaveA,WaveB,options,tolerance)	
End Function

Static Function element_index(needle,haystack)
	// Returns: index of needle in haystack, or -1 if nothing
	// V-182: FindVaule sets V_Value to -1 if it is not found
	String Needle
	Wave /T HayStack
	FindValue /TEXT=(Needle) HayStack
	return V_Value
End Function

Static Function text_in_wave(Needle,HayStack,[index])
	// determine if needle is in haystack, setting the reference if need be
	// 
	// Args:
	//	Needle : element to search for 
	//	Haystack : where we are searching
	// Returns:
	//	True if needle is in haystack. sets index if it isn't default
	String Needle
	Wave /T HayStack
	// set the index *value* (pass by reference) if we want it)
	Variable & index
	Variable idx_tmp = element_index(needle,haystack)
	if (!ParamIsDefault(index))
		index = idx_tmp
	EndIf
	// if V_Value>=0, then the index was found
	return idx_tmp >=0
End Function

Static Function RemoveTextFromWave(Needle,Haystack)
	STring Needle
	Wave /T Haystack 
	Variable index
	// Delete the points if we find them.
	if (text_in_wave(Needle,Haystack,index=index))
		DeletePoints index,1,Haystack
	EndIF
End Function

Static Function /Wave ExtractSetTextIntersection(WaveA,WaveB)
	Wave /T WaveA
	Wave /T WaveB
	Extract WaveA, mSetIntersect, text_in_wave(WaveA,WaveB)
	return mSetIntersect
End Function

Static Function /Wave ExtractWhereFirstNotInSecond(WaveA,WaveB)
	Wave /T WaveA
	Wave /T WaveB
	// If an element of waveA is *not* in waveB
	Extract WaveA, mExtractNot, !text_in_wave(WaveA,WaveB)
	return mExtractNot
End Function

Static Function EnsureTextWaveExists(StrName,[size])
	String StrName
	Variable Size
	Size = ParamISDefault(Size) ? 0 : size
	EnsureWaveExists(StrName, ModDefine#True(),Size)
End Function

Static Function EnsureNumWaveExists(StrName,[Size])
	String StrName
	Variable Size
	Size = ParamISDefault(Size) ? 0 : size
	EnsureWaveExists(StrName, ModDefine#False(),Size)
End Function

Static Function EnsureWaveExists(StrName,isText,Size)
	String StrName
	Variable isText
	Variable Size
	if (!WaveExists($StrName))
		if (isText)
			Make /O/N=(Size)/T $StrName
		Else
			// Make a double wave by default
			Make /O/N=(Size)/D $StrName
		EndIf		
	EndIf
	// POST: wave with $strName$ exists
End Function

Static Function /S GetListFromWave(mWave,[Sep])
	Wave /T mWave 
	String Sep
	String toRet  =""
	if (ParamIsDefault(Sep))
		Sep = ModDefine#DefListSep()
	EndIf
	Variable n = DimSize(mWave,0)
	Variable i
	for (i=0; i<n; i+=1)
		toRet += mWave[i] + Sep
	EndFor
	return toRet
End Function

Static Function /Wave MakeWave(Name,N,[isText])
	Variable N,isText
	String Name
	isText = ParamIsDefault(isText) ? ModDefine#True() : ModDefine#False()
	Killwaves /Z $Name
	if (isText)
		Make /O /T /N=(N) $Name
	else
		Make /O /N=(N) $Name
	EndIf
	Wave toRet = $Name
	return toRet
End Function

Static Function /Wave TextWaveToNumeric(TextWave,NewWaveName)
	Wave /T TextWave
	String NewWaveName
	Variable NStrings = DimSize(TextWave, 0)
	Wave toRet = MakeWave(NewWaveNAme,NStrings,isText=ModDefine#False())
	Variable i
	for ( i=0; i<NStrings; i+=1)
		toRet[i] = str2num(TextWave[i])
	EndFor
End Function
	
Static Function /Wave MakeWaveForList(Name,List,Sep)
	String Name,List,Sep
	return MakeWave(Name,ItemsInList(List,Sep))
End Function

Static Function pListToTextWave(ToRet,List, [Sep])
	String List,Sep
	Wave /T ToRet
	if (ParamIsDefault(Sep))
		Sep = ModDefine#DefListSep()
	EndIf
	Variable NPoints = ItemsInList(List,Sep), i=0
	Redimension /N=(nPoints) toRet
	// Overright / Make  a text wave (/T)  with N points
	For (i=0; i< NPoints; i+=1)
		ToRet[i] = StringFromList(i,List,Sep)
	EndFor
End Function

Static Function GetTextWaveLengths(TextWave,Sep,[TextWaveName])
	Wave TextWave
	String Sep,TextWaveName
End Function

//  Below are functions for strings...

Function strEq(one,two,[caseSensitive])
	String one,two
	Variable caseSensitive
	caseSensitive = ParamIsDefault(caseSensitive) ?  CMPSTR_CASE_IN : caseSensitive
	return (cmpstr(one,two) == CMPSTR_EQ)
End Function


Static Function /S GetListString(toAdd,Sep)
	// return the appropriate string to add
	String &toAdd,Sep
	return toAdd + Sep
End 

Static Function /S GetNameRegex(RegexExpr,Full)
	// Returns everything after a specified preamble
	String RegexExpr,Full
	String NameStem
	// Get everything up to and including the preamble
	SplitString /E=(RegexExpr) Full, NameStem
	//POST: NameStem should have what we need
	return NameStem
End Function

Static Function /S GetNamePrefix(Preamble,Full)
	String Preamble,Full
	String RegExpr = "(.*" + Preamble + ")"
	return GetNameRegex(RegExpr,Full)
End Function

Static Function /S GetNamePrefixOfList(Preamble,List,Sep)
	String Preamble,List,Sep
	String toRet,tmp
	Variable nItems = ItemsInList(List)
	Variable i
	For (i=0; i< nItems; i+=1)
		// Get the raw string
		tmp = StringFromList(i,List,Sep)
		// Get the prefix of the string
		tmp = GetNamePrefix(Preamble,tmp)
		// Add the prefix
		toRet += GetListString(tmp,Sep)
	EndFor
	return toRet
End Function


Static Function ConcatLists(List1,List2,ResultList,Sep)
	String &List1,&List2,&ResultList,Sep
	// should *not* need to add the separator, assuming we are using 
	// GetListString, as above
	ResultList = List1 + List2
End

Static Function /S PrependToItems(List,toAdd,sep)
	String List,ToAdd,sep
	String toRet = ""
	Variable nItems = ItemsInList(List,sep)
	Variable i=0
	String tmp
	// loop through, add each pre-pended  item
	For (i=0; i<nItems;i+=1)
		tmp = StringFromList(i,List,sep)
		toRet = AddListItem(toAdd + tmp,toRet,sep)
	Endfor
	return toRet
End

Static Function /S GetMatchString(NeedleExpr,Haystack,sep)
	String NeedleExpr, Haystack,sep
	Variable i = GetMatchIndex(NeedleExpr,Haystack,sep)
	// XXX throw error if i == -1
	return StringFromList(i,Haystack,sep)
End

Static Function GetMatchIndex(NeedleExpr,Haystack,sep)
	String NeedleExpr,Haystack,sep
	Variable nItems = ItemsInList(HayStack,sep)
	Variable i
	String tmpStr 
	For (i=0; i<nItems; i+=1)
		 tmpStr = StringFromList(i,Haystack,sep)
		If (StringMatch(tmpStr,NeedleExpr))
			return i
		EndIf
	EndFor
	// XXX throw error? have -1 be a constant?
	return -1
End
