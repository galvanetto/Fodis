# force floating point division. Can still use integer with //
from __future__ import division
# other good compatibility recquirements for python3
from __future__ import absolute_import
from __future__ import print_function
# This file is used for importing the common utilities classes.
import numpy as np
from .UtilGeneral import GenUtilities  as pGenUtil
import os

# given a waverecord, how to access the actual wave sruct
WAVE_STRUCT_STR = 'wave'
# given an actual wave struct, how to access the note within it
WAVE_NOTE_STR = 'note'
# the delimiter for the notes
NOTE_DELIM = ":"
# extensons for datawaves
DATA_EXT = ["defl","deflv","force","sep","zsnsr","time"]
TEXT_ENCODING = "utf-8"
import re
import copy
# ending for concatenated waves
ENDING_CONCAT = "Concat"

# make a verbose pattern for getting names
IgorNamePattern = re.compile(r"""
                         ^ # start of the string
                         (?:b')?   # possible, non-capturing bytes start
                         (.*?)     # anything, non-greedy
                         (\d{4,})      # followed by only digits (id)
                         .*?        # optional, non greedy anything (underscores, etc)
                         ([a-zA-Z]*) # followed by possible letters (this is like "Force","Zsnsr", etc)
                         [a-zA-Z_\d]*? # Non greedy, things after (e.g. "_Ret2")
                         (?:')?   # possible, non-capturing bytes end
                         $ # end of the string""",
                             re.X)
def IgorNameRegex(Name,name_pattern=IgorNamePattern):
    """
    Given a wave name, gets the preamble (eg X060715Image) digit (eg: 0001) 
    and ending (eg: Defl). If it cant match, throws an error.

    Args:
        Name: name of the wave
        name_pattern: re.compile mattern with .match, taking in a string
    
    Returns:
        tuple of digit(ending) 
    """
    match = name_pattern.match(str(Name))
    if match:
        preamble = match.group(1)
        digit = match.group(2)
        ending = match.group(3)
        return preamble,digit,ending
    else:
        raise ValueError("Couldn't match {:s}".format(str(Name)))


def GetWaveStruct(waverecord):
    """
    Gets the wave struct associated with a single 'igor' waverecord object

    Args:
        waverecord: which waverecord to get. Should follow python igor api

    Returns:
        The wave structure
    """
    return waverecord[WAVE_STRUCT_STR]

def SafeConvertValue(NoteStr):
    """
    Converts an value from a note string to its appropriate type

    Args:
        NoteStr: note value (e.g. '1.2176' or some such)

    Returns:
        the safely converted values
    """
    try:
        return float(NoteStr)
    except ValueError:
        # not a float! Return a string, if we can. 'null' strings
        # are problematic downstream, so we just return an empty string
        if len(NoteStr) > 0:
            return str(NoteStr)
        else:
            return ""

def GetNote(wavestruct):
    """
    Gets the note associated with a single 'igor' wavesturct object

    Args:
        wavestruct: which wavestruct (see "GetWaveStruct") to get the note of

    Returns:
        A dictionary of (name,value) tuples of the single wave.
    """
    # split the note by newlines
    # we turn any \r or ; into a newline, any = into a colon.
    # we then split on newlines, then parse <key><literal :><value>
    mNote =  wavestruct[WAVE_NOTE_STR]
    mNote = str(mNote).replace(";","\r\n")
    # get note:value pairs
    lines = str(mNote).strip().split("\r")
    pattern = re.compile(r"""
                         (?:b')?      # possible non-capture byte start
                         [\s\r]?        # possible whitespace
                         ([^:]+)      # any non-colon (captured)
                         [:=]            # a literal colon or equals
                         \s*          # possible whitespace (ignored)
                         ([^\s;]+)     # any non whitespace or semicolon(captured)
                         [\s;]*      # possible whitespace or semicolon
                         (?:')?      # possible non-capture byte end
                         """,re.VERBOSE)
    tuples = []                         
    for line in lines:
        matched = pattern.match(line)
        if not matched:
            continue
        # POST: we matched the pattern
        groups = matched.groups()
        # convert the value into a float, if possible. 
        value = SafeConvertValue(groups[1])
        key = groups[0].replace(r"\r","")
        tuples.append([key,value])
    # make sure all the values have length at least one
    # XXX may want to check for NOTE_DELIM on each string
    if (len(tuples) == 0):
        return dict()
    # POST: actually have some tuples
    ToRet =  dict(tuples)
    return ToRet


def GetHeader(WaveStruct):
    """
    Gets the wave header associated with a wave structure

    Args:
        wavestruct: which wavestruct (see "GetWaveStruct") to get the header

    Returns:
        the wave header struct
    """
    return WaveStruct['wave_header']

def GetWaveNameFromHeader(header):
    """
    Given a header, gets the name associated with the wave.

    Args:
        Header: the wave header

    Returns:
        the wave name
    """
    return header['bname']

class WaveObj:
    def __init__(self,record=None,SourceFile = None, Note=None,DataY=None):
        """
        Creates a new wave object from the given wave structure
        
        Args:
            SourceFile: where this file is coming from
            record: which waverecord use; e.g. 'record.wave' in igor API
            Note: If loading from a binary file, the full note
            DataY: If loading from a binary file, the y data

        Returns:
            A new WaveObj structure
        """
        if (record is not None):
            # then we are loading from a pxp file; get all the information
            # we need.
            WaveStruct =  GetWaveStruct(record)
            # get the note
            self.Note = GetNote(WaveStruct)
            # get some of the header information, keeping in mind
            # we assume a 1-D wave (first dimension)
            dim = 0
            header = GetHeader(WaveStruct)
            unitsY = header['dataUnits'][dim]
            unitsX = header['dimUnits'][dim]
            # get the associated data, reshape it to numRows x 1
            dat = WaveStruct['wData']
            numPoints = dat.size
            if (len(dat.shape) == 1):
                # for 1-D waves, reshape so Nx1
                self.DataY = dat.reshape(numPoints)
            else:
                # for higher-D waves, just copy it
                self.DataY = dat.copy()
            self.name = GetWaveNameFromHeader(header)
            # save all the other informaton...
            self.Note["UnitsY"] = unitsY
            self.Note["UnitsX"] = unitsX
            self.Note["Name"] = self.name
            # try to get the units...
            try:
                self.Note["DeltaDim"] = header['sfA']
            except KeyError:
                pass
            self.Note["Description"] = ""
            assert SourceFile is not None ,\
                "Must give source file upon creation"
            self.Note["SourceFile"] = SourceFile
        elif ( (Note is not None) and (DataY is not None)):
            self.Note = copy.deepcopy(Note)
            self.DataY = DataY
        else:
            raise ValueError("Must be passed either raw .pxp xor Note and Data")
        # determine if we were concatenated
        self.isConcat = str(self.Name()).endswith(ENDING_CONCAT)
                
    def SourceFilename(self):
        """
        Returns the source file for this wave
        
        Returns:
            Source filename, without extension or path
        """           

        SrcPath = self.Note["SourceFile"]
        # convert the path to just a simple file (without extension)
        # remove everything except the file name (including the extension)
        fileWithExt = pGenUtil.getFileFromPath(SrcPath)
        # return everything before the extension
        return os.path.splitext(fileWithExt)[0]
    def TimeCreated(self):
        """
        Returns the time this wave was created (unique ID, if only 1 Cypher)
        in seconds since midnight, January 1, 1904 GMT
        
        Returns:
            Time Created
        """           
        return self.Note["Seconds"]
    def SetName(self,NewName):
        self.Note["Name"]= NewName
        self.name = NewName
    def ImagePixelSize(self):
        """
        Returns the pixel size (in meters; side of a pixel) for this,
        *assuming* the wave is an image. XXX assume square images
        """
        ScanString = self.Note["SlowScanSize"]
        try:
            size_in_meters = float(ScanString)
        except ValueError:
            # can have prolblems parsing string...
            size_in_meters = float(ScanString.split("@")[0])
        num_scan_points = self.Note["ScanPoints"]
        return float(size_in_meters)/float(num_scan_points)
    def Name(self):
        return self.Note["Name"]
    def SpringConstant(self):
        try:
            return self.Note["SpringConstant"]
        except KeyError:
            return self.Note["K"]
    def Invols(self):
        try:
            return self.Note["InvOLS"]
        except KeyError:
            # Rob
            return self.Note["Invols"]
    def DeltaX(self):
        try:
            # get the first dimensional delta
            to_ret = self.Note["DeltaDim"][0]
        except KeyError:
            try:
                to_ret =  1./self.Note["NumPtsPerSec"]
            except KeyError:
                # Rob
                return 1 / self.Note["SamplingRate"]

        return to_ret
    def GetXArray(self):
        """
        Returns the x array, based on deltaX and the length
        Returns:
            an array of the same length of y
        """     
        dx = self.DeltaX()
        # XXX assume the number of rows is the number of data points.
        n = self.DataY.shape[0]
        # XXX TODO: add in (initial) offsets?
        xInit = 0
        xFinal = xInit+n*dx
        mXArr,step = np.linspace(start=xInit,
                                 stop=xFinal,
                                 num=n,
                                 endpoint=False,
                                 retstep=True)
        # sanity check: does the actual step match the desired dx?
        # make sure they match to within a (relative) error of 1ppm.
        minDenom = min(dx,step)
        assert (abs((step - dx)/(minDenom)) < 1e-6) ,\
            "When constructing wave x array,Bad sample spacing."
        # POST: everything is great!
        return mXArr
    def __eq__(self, other):
        """
        Checks that the data and note for this are equivalent to the other
        
        Args:
            other: another instance of waveobject
        Returns:
            True/False if the data and note are equivalent.
        """  
        # do min and max by columns
        # XXX generalize this?
        NotesMatch = NotesEqual(self.Note,other.Note)
        return (DataEqual(self,other) and NotesMatch)
    def SetAsConcatenated(self):
        # Mark this wave as a concatenated wave
        # Change the name to reflect it is concatenated
        oldName = self.Name()
        newName = str(oldName) + str(ENDING_CONCAT)
        self.isConcat = True
        self.SetName(newName)
    def GetTimeSepForceAsCols(self):
        """
        Assuming this  wave is concatenced, gets time sep force. Throws error
        if we aren't a three-column conatenated array.
        
        Args:
            other: another instance of waveobject
        Returns:
            True/False if the data and note are equivalent.
        """
        assert self.isConcat
        # need exactly three columns
        assert (self.DataY.shape[1]  == 3 )
        # go ahead and get all the columns
        time = self.DataY[:,0]
        sep = self.DataY[:,1]
        force = self.DataY[:,2]
        return time,sep,force

def DataEqual(one,two,tol=1e-6):
    """
    checks if the data of two are approximately the same
    Args:
        one: WaveObj instance
        two: WaveObj instance
        tol: relative tolerance to not exceed
    """
    return np.allclose(one.DataY,two.DataY,rtol=tol)

def NotesValsTheSame(n1,n2,tol=1e-6,equal_nan=True):
    """
    Checks if two note values are the same. Casts as floats first, if that
    doesnt work (and it allows two NaNs), checks for string equality
    
    Args:
        n1: the value of the first note
        n2: the value of the second node
        tol: the relative tolerance, assuming we can cast
        equal_nan: true if we should treat NaN as the same for both. A very 
        good idea to set this to true...
    Returns:
        True/false if the notes match within the specified parameters
    """
    try:
        return np.allclose(float(n1),float(n2),rtol=tol,equal_nan=equal_nan)
    except (ValueError,TypeError) as e:
        return str(n1) == str(n2)

def GetNoteMismatch(note1,note2):
    """
    Given two notes, gets the mismatches between them. Uses 'NotesValsTheSame'
    as a subroutine, so check that for details
    
    Args:
        note1: the first note
        note2: the second
    Returns:
        a dictionary, each <key:val> is a noteName:noteValue that was in one
        but not the other, or with mismathed values
    """
    keysAsStr = lambda note : [str(s) for s in note.keys()]
    firstKeys = set(keysAsStr(note1))
    secondKeys = set(keysAsStr(note2))
    intersect = set(firstKeys & secondKeys)
    valsAreTheSame = lambda key: NotesValsTheSame(note1[key],note2[key])
    # build up the dictionary if they aren't equal
    mDict= dict( (k,(note1[k],note2[k]))
                 for k in intersect if not valsAreTheSame(k) )
    # add in (the possible empty) mismatches from the other
    keys2 = secondKeys - firstKeys
    for k in keys2:
        mDict[k] = (None,note2[k])
    # same for 1 to two
    keys1 = firstKeys - secondKeys 
    for k in keys1:
        mDict[k] = (note1[k],None)
    return mDict


def NotesEqual(note1,note2):
    """
    Returns true/false if the two notes (dictionaries) are string-identical
        
    Args:
        note1: note to check
        note2: (second) note to check

    Returns:
        if the wave has a 'correct' name
    """
    # look at the values as strings, avoid funny unicode buisiness, floats,
    # etc.
    mDict = GetNoteMismatch(note1,note2)
    return len(mDict.values()) == 0

def GetWaveName(mWave):
    """
    Given a WaveRecord, returns the wave name

    Args:
        MWave: See ValidName
    Returns:
        String of wave name
    """
    WaveStruct =  GetWaveStruct(mWave)
    header = GetHeader(WaveStruct)
    name = GetWaveNameFromHeader(header)
    return name

def HasValidExt(mWave):
    name = GetWaveName(mWave.wave).lower()
    for ext in DATA_EXT:
        if ext in name:
            return True
    return False
    
def ValidName(mWave):
    """  
    Returns true/false if the wave has the correct formatting for a data wave
        
    Args:
        mWave: wave part of the record (ie: record.wave in igor stuff)

    Returns:
        if the wave has a 'correct' name
    """
    name = GetWaveName(mWave)
    # loop through each extension, return true on a match
    name = str(name.lower())
    match = IgorNamePattern.match(str(name))
    # do we have a valid name?
    if (match is None):
        return False
    # do we have a known extension?
    for ext in DATA_EXT:
        if name.endswith(ext):
            return True
    # valid name, but invalid extension
    return False

def pprint(data):
    lines = pformat(data).splitlines()
    print('\n'.join([line.rstrip() for line in lines]))

def ConcatenateWaves(WaveObjects,AddTime=True):
    """
    Given a list of N WaveObjects  (See ProcessSingleWave) with data size Mx1
    into a single WaveObject, with the same note as the first, with MxN data
    pnts. Note that the colunmns are in the same order as given in WaveObjects

    Args:
        WaveObjects: The list of Wave Objects to concatenate.
        AddTime: if true, adds a time column first, based on the first x scale
    Returns:
        The concatenated Wave Object
    Raises:
        ValueError, if the WaveObject sizes dont match
    """
    # if we werent given anything, just return the single array
    if (len(WaveObjects) == 0):
        return WaveObjects
    # POST: at least ont element
    allData = [w.DataY for w in WaveObjects]
    # check that the lengths are all the same
    lengths = map(len,allData)
    numLengths = len(set(lengths))
    if (numLengths != 1):
        raise ValueError("Cannot concatenate arrays with different lengths")
    # POST: all the same lengths, at least one element
    # add the time axis, assuming we start at zero...
    refObj = WaveObjects[0]
    if (AddTime):
        allData.insert(0,refObj.GetXArray())
    # get the note from the first wave
    Note = refObj.Note
    # concatenate along the column axis. See:
    #http://docs.scipy.org/doc/numpy/reference/generated/numpy.column_stack.html
    mDat = np.column_stack(allData)
    # Create concatenated object.
    concat = WaveObj(Note=Note,DataY=mDat)
    concat.SetAsConcatenated()
    return concat
