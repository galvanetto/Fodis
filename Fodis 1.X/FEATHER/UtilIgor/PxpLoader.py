# force floating point division. Can still use integer with //
from __future__ import division
# other good compatibility recquirements for python3
from __future__ import absolute_import
from __future__ import print_function
from __future__ import unicode_literals
# This file is used for importing the common utilities classes.
import numpy as np
import matplotlib.pyplot as plt
import sys
from . import ProcessSingleWave,TimeSepForceObj
from .UtilGeneral import GenUtilities as pGenUtil

from pprint import pformat
from .igor.binarywave import load as loadibw
from .igor.packed import load as loadpxp
from .igor.record.wave import WaveRecord

import re
import collections
# for rotating surface image 
from scipy import ndimage

class SurfaceImage(ProcessSingleWave.WaveObj):
    """
    Class for encapsulating (XXX just the height) of an image
    """
    def __init__(self,Example):
        """
        Args:

            Example: a single ProcessSingleWave.XX object
            height: the heights extracted from example (Example is pretty much 
            exclusively used for meta information)
        """
        height = Example.DataY[:,:,0]
        self.height = height
        self.pixel_size_meters = Example.ImagePixelSize()
        self.NumRows = height.shape[0]
        self.range_meters = self.pixel_size_meters * self.NumRows
        self.Note = Example.Note
        self.Meta = TimeSepForceObj.Bunch(self.Note)
    def rotate(self,angle_degrees,**kwargs):
        self.height = ndimage.interpolation.rotate(self.height,
                                                   angle=angle_degrees,**kwargs)
    def height_nm(self):
        """
        Returns the height as a 2-D array in nm
        """
        return self.height * 1e9
    def height_nm_rel(self,surface_pct=0):
        """
        returns the height, relative to the 'surface' (see args) in nm

        Args:
             surface_pct: the lowest pct heights are consiered to be
             the absolute surface. between 0 and 100
        Returns:
             height_nm_rel, offset to the pct
        """
        height_nm = self.height_nm()
        MinV = np.percentile(height_nm,surface_pct)
        height_nm_rel = height_nm - MinV
        return height_nm_rel
    def range_microns(self):
        height_nm_relative = self.height_nm_rel()
        range_microns = self.range_meters * 1e6
        return range_microns

def LoadPxpFilesFromDirectory(directory):
    """
    Given a directory, load all the pxp files into a wave

    Args:
        directory: loads all directories 
    Returns:
        see LoadAllWavesFromPxp
    """
    allFiles = pGenUtil.getAllFiles(directory,ext=".pxp")
    d = []
    for f in allFiles:
        d.extend(LoadAllWavesFromPxp(f))
    return d

def IsValidFec(Record):
    """
    Args:
        Wave: igor WaveRecord type
    Returns:
        True if the waves is consistent with a FEC
    """
    return ProcessSingleWave.ValidName(Record.wave)

def valid_fec_allow_endings(Record):
    name = ProcessSingleWave.GetWaveName(Record.wave).lower()
    for ext in ProcessSingleWave.DATA_EXT:
        if (str(ext.lower()) in str(name)):
            return True
    return False

def IsValidImage(Record):
    """
    Returns true if this wave appears to be a valid image

    Args:
        See IsValidFEC
    """
    Wave = Record.wave
    # check if the name matches
    Name = ProcessSingleWave.GetWaveName(Wave)
    # last four characters should be numbers (eg Image0007)
    Numbers = 4
    pattern = re.compile("^[0-9]{4}$")
    if (not pattern.match(Name[-Numbers:])):
        return False
    # now we need to check the dimensionality of the wave
    WaveStruct =  ProcessSingleWave.GetWaveStruct(Wave)
    header = ProcessSingleWave.GetHeader(WaveStruct)
    dat = WaveStruct['wData']
    if len(dat.shape) != 3:
        return False
    # POST: wave has three dimensions.
    # check that the scan size and such are in there 
    note = ProcessSingleWave.GetNote(WaveStruct)
    if ("SlowScanSize" not in note or "ScanPoints" not in note):
        return False
    return True

def LoadAllWavesFromPxp(filepath,load_func=loadpxp,ValidFunc=IsValidFec):
    """
    Given a file path to an igor pxp file, loads all waves associated with it

    Args:
        filepath: path to igor pxp file
        ValidFunc: takes in a record, returns true if we wants it. defaults to
        all FEC-valid ones
    Returns:
        list of WaveObj (see ParseSingleWave), containing data and metadata
    """
    # XXX use file system to filter?
    records,_ = load_func(filepath)
    mWaves = []
    for i,record in enumerate(records):
        # if this is a wave with a proper name, go for it
        if isinstance(record, WaveRecord):
            # determine if the wave is something we care about
            if (not ValidFunc(record)):
                continue
            # POST: have a valid name
            WaveObj = ProcessSingleWave.WaveObj(record=record.wave,
                                                SourceFile=filepath)
            mWaves.append(WaveObj)
    return mWaves


def GroupWavesByEnding(WaveObjs,grouping_function,**kw):
    """
    Given a list of waves and (optional) list of endings, groups the waves

    Args:
        WaveObjs: List of wave objects, from LoadAllWavesFromPxp
        grouping_function: function that takes in a wave name and returns   
        a tuple of <preamble,ids,endings>. wave with the same id but different
        endings are grouped
    Returns:
        dictionary of lists; each sublist is a 'grouping' of waves by extension
    """
    # get all the names of the wave objects
    rawNames = [str(o.Name()) for o in WaveObjs]
    # assumed waves end with a number, followed by an ending
    # we need to figure out what the endings and numbers are
    digitEndingList = []
    # filter out to objects we are about
    goodNames = []
    goodObj = []
    for n,obj in zip(rawNames,WaveObjs):
        try:
            digitEndingList.append(grouping_function(n,**kw))
            goodNames.append(n)
            goodObj.append(obj)
        except ValueError as e:
            # not a good wave, go ahead and remove it
            continue
    # first element gives the (assumed unique) ids
    preamble = [ele[0] for ele in digitEndingList]
    ids = [ele[1] for ele in digitEndingList]
    endings = [ele[2] for ele in digitEndingList]
    # following (but we want all, not just duplicates):
#stackoverflow.com/questions/5419204/index-of-duplicates-items-in-a-python-list
    counter=collections.Counter(ids) 
    idSet=[i for i in counter]
    # each key of 'result' will give a list of indies associated with that ID
    result={}
    for item in idSet:
        result[item]=[i for i,j in enumerate(ids) if j==item]
    # (1) each key in the result corresponds to a specific ID (with extensions)
    # (2) each value associated with a key is a list of indices
    # Go ahead and group the waves (remember the waves? that's what we care
    # about) into a 'master' dictionary, indexed by their names
    finalList ={}
    for key,val in result.items():
        tmp = {}
        # append each index to this list
        for idxWithSameId in val:
            objToAdd = goodObj[idxWithSameId]
            tmp[endings[idxWithSameId].lower()] = objToAdd
        if (key is None):
            # no id given; assume it is just zero
            assert len(result.items()) == 1 ,"No ids given, but multiple waves."
            key = "0"
        finalList[preamble[idxWithSameId] + key] = tmp
    return finalList
    
def LoadPxp(inFile,grouping_function=ProcessSingleWave.IgorNameRegex,
            name_pattern=ProcessSingleWave.IgorNamePattern,**kwargs):
    """
    Convenience Wrapper. Given a pxp file, reads in all data waves and
    groups by common ID

    Args:
        Infile: file to input
        **kwargs: passed to LoadAllWavesFromPxp
    Returns:
        dictionary: see GroupWavesByEnding, same output
    """
    mWaves = LoadAllWavesFromPxp(inFile,**kwargs)
    return GroupWavesByEnding(mWaves,grouping_function=grouping_function,
                              name_pattern=name_pattern)

def load_ibw_from_directory(in_dir,grouping_function,limit=None,
                            f_file_name_valid=lambda f: True):
    """
    Convenience Wrapper. Given a directory, reads in all ibw and groups 

    Args:
        in_dir: where we are grouping 
        grouping_function: takes in a file name, see GroupWavesByEnding
        limit: maximum number to load
        f_file_name_valid: return true if a given file name is valid
    Returns:
        dictionary: see GroupWavesByEnding, same output
    """
    assert in_dir is not None , "input directory was None; can't load there."
    files = pGenUtil.getAllFiles(in_dir,ext=".ibw")
    files = [f for f in files if f_file_name_valid(f)]
    ibw_waves = [read_ibw_as_wave(f) for f in files]
    dict_raw = GroupWavesByEnding(ibw_waves,grouping_function=grouping_function)
    dict_ret = dict([ [k,v] for k,v in dict_raw.items()][:limit])
    return dict_ret

def read_ibw_as_wave(in_file):
    """
    Reads a *single* image from the given ibw file

    Args:
         in_file: path to the file
    Returns:
         WaveObj object
    """
    raw = loadibw(in_file)
    ex = ProcessSingleWave.WaveObj(record=raw,SourceFile=in_file) 
    return ex
    
def read_ibw_as_image(in_file):
    """
    Reads a *single* image from the given ibw file as a SurfaceImage

    Args:
         in_file: path to the file
    Returns:
        SurfaceImage object
    """
    ex = read_ibw_as_wave(in_file)
    return SurfaceImage(ex)
    
def ReadImages(InFile,ValidFunc=IsValidImage):
    """
    Reads images from the given pxp file

    Args:
         InFile: path
    Returns:
         List of tuple of <Full Wave Object, height array>
    """
    Waves = LoadAllWavesFromPxp(InFile,ValidFunc=IsValidImage)
    # get all the images
    return [ SurfaceImage(Example) for Example in Waves]
