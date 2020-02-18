# force floating point division. Can still use integer with //
from __future__ import division
# This file is used for importing the common utilities classes.
import numpy as np

import HDF5Util
from WaveDataGroup import WaveDataGroup
from TimeSepForceObj import TimeSepForceObj
import ProcessSingleWave
from multiprocessing import Pool
import os

DEFAULT_HIGH_BANDWIDTH = "HighResolution" + HDF5Util.DEFAULT_IGOR_DATASET 
DEF_NTHREADS  = 5

def GetFileSaveName(WaveMetaData):
    """
    Returns the file name to save this file, given its FileName and Meta Data
    
    Args:
        WaveMetaData : The "Note" property from a WaveObject 
        (see ProcessSingleWave)
    Returns:
        The filename for saving this data. Essentially "X<File><Time><Wave>.hdf
    """
    FileName = WaveMetaData.SourceFilename()
    sanitizeFile = FileName.replace(" ","_")
    ext = HDF5Util.DEFAULT_HDF5_EXTENSION
    return "X{:s}_{:d}_{:s}{:s}".format(sanitizeFile,
                                        int(WaveMetaData.TimeCreated()),
                                        WaveMetaData.name,ext)

def LoadHdfFileIntoWaveObj(FilePath):
    """
    Non-parallel, loads a single file into a WaveObject

    Args:
        FilePath: Which file to load
    Returns:
        Nothing
    Raises:
        IoError
    """
    Data,Note = HDF5Util.GetHDF5DataAndWaveNote(FilePath)
    return ProcessSingleWave.WaveObj(Note=Note,DataY=Data)

def SaveObjectAsHDF5(FolderPath,WaveObject):
    """
    Non-parallel, saves a single wave object to folderpath as an hdf5 file
    
    Unit tested by "UnitTests/PythonReader/CypherConverter"

    Args:
        WaveObject: The Wave Object to save out. Save 'DataY' in the object
        FolderPath: Where to save the hdf5 file (full *folder* path)
    Returns:
        Nothing
    Raises:
        IoError
    """
    WaveData = WaveObject.DataY
    FilePath = FolderPath + GetFileSaveName(WaveObject)
    HDF5Util.WriteHDF5Array(FilePath,WaveData,attr=WaveObject.Note)

def SaveWaveGroupAsTimeSepForceHDF5(FolderPath,WaveGroup,
                                    ErrorIfNoHighBWX=True):
    """
    Non-parallel, saves a single wave object to folderpath as an hdf5 file.
    Save it as <time,sep,force> with aa low and high bandwidth version 
    if the high-bandwidth version is present. 

    Unit tested by "UnitTests/PythonReader/CypherConverter"

    Args:
        WaveGroup: The Model.WaveDataGroup to save out. 
        FolderPath: Where to save the hdf5 file (full *folder* path)

        ErrorIfNoHighBWX: If true, and if the wavedata has high bandwidth 
        data, throws an error if we cant make time,sep,force. Otherwise,
        *only* makes force (useful, e.g., for caching, when we dont have
        high resolution x)
    Returns:
        FilePath: Where the file was saved
    Raises:
        IoError
    """
    # get the full path
    dataSets = dict()
    attrs = dict()
    # First, get the time, sep, force object from this
    FilePath = FolderPath + GetFileSaveName(WaveGroup.GetNoteElement())
    concatWave = WaveGroup.CreateTimeSepForceWaveObject()
    dataSets[HDF5Util.DEFAULT_IGOR_DATASET] = concatWave.DataY
    attrs[HDF5Util.DEFAULT_IGOR_DATASET] = concatWave.Note
    # do we have a high bandwidth wave?
    if (WaveGroup.HasHighBandwidth()):
        try:
            concatWaveHighBW = \
                WaveGroup.HighBandwidthCreateTimeSepForceWaveObject()
        except KeyError as e:
            if (ErrorIfNoHighBWX):
                raise(e)
            else:
                # just get the force
                concatWaveHighBW = WaveGroup.HighBandwidthGetForceWaveObject()
        dataSets[DEFAULT_HIGH_BANDWIDTH] = concatWaveHighBW.DataY
        attrs[DEFAULT_HIGH_BANDWIDTH] = concatWaveHighBW.Note
    # POST: datasets has all the datasets we want to save.
    # save the datasets
    HDF5Util.WriteHDF5Array(FilePath,array=dataSets,attr=attrs)
    return FilePath

def GetAssocDataFromDataset(ReaderAllReturn,datasetname,ErrorOnNoSep=True):
    """
    Given return from HDF5Util.ReadHdf5AllDatasets and a dataset name, returns
    the sep and force as a grouped object. 

    Unit tested by "UnitTests/PythonReader/CypherConverter"

    Args:
        ReaderAllReturn : output from HDF5Util.ReadHdf5AllDatasets
        datasetname: name of the dataset. should be in ReaderAllReturn.keys()
        ErrorOnNoSep: If true, returns an error if we cant find a sep
    Returns:
        a dictionary of <ending>:<WaveObj>
    Raises:
        IoError
    """
    default = ReaderAllReturn[datasetname]
    defaultData = default.dataset
    defaultNote = HDF5Util.GetHDF5NoteFromDataTuple(default)
    # XXX get rid of hard-coding
    sepExt = "sep"
    forceExt = "force"
    makeObj = lambda data,note :  ProcessSingleWave.WaveObj(DataY=data,
                                                            Note=note)
    # try to get the force and separation
    try:
        AssocData = {
            sepExt:makeObj(defaultData[:,HDF5Util.COLUMN_SEP],defaultNote),
            forceExt:makeObj(defaultData[:,HDF5Util.COLUMN_FORCE],defaultNote)
        }
    except IndexError as e:
        if (ErrorOnNoSep):
            # throw an error if we were asked to
            raise e
        else:
            # assume *only* column is first
            assert len(defaultData.shape) is 1
            AssocData = {
                forceExt:makeObj(defaultData[:],
                                 defaultNote)
            }
    return AssocData
    
def ReadWaveIntoWaveGroup(FilePath,ErrorOnNoSep=True):
    """
    Non-parallel, Reads a given File into an associated wave group (sep/force)

    Unit tested by "UnitTests/PythonReader/CypherConverter"

    Args:
        FilePath: The path to the file
        ErrorOnNoSep : If True, throws an error if we cant find a separation
        (for the *high res* only)
    Returns:
        a Model.WaveDataGroup object 
    Raises:
        IoError
    """
    mDataSets = HDF5Util.ReadHdf5AllDatasets(FilePath)
    # create the associated wave data for the sep and Force for the default
    # (should definitiely exist)
    LowResData = GetAssocDataFromDataset(mDataSets,
                                         HDF5Util.DEFAULT_IGOR_DATASET)
    ToRet = WaveDataGroup(LowResData)
    # POST: low res is created. how about higher res?
    keys = mDataSets.keys()
    if (DEFAULT_HIGH_BANDWIDTH in keys):
        # get the high resolution associated data...
        HighResData = GetAssocDataFromDataset(mDataSets,
                                              DEFAULT_HIGH_BANDWIDTH,\
                                              ErrorOnNoSep)
        ToRet.HighBandwidthSetAssociatedWaves(HighResData)
    return ToRet

def SaveObjectWrapper(args):
    """
    parallel Wrapper for SaveObjectAsHDF5

    Args:
    Returns:
        Nothing
    Raises:
        IoError
    """
    SaveObjectAsHDF5(*args)

def MultiThreadedSave(WaveObjects,FolderPath,NThreads=DEF_NTHREADS):
    """
    Given a list of WaveObj (See ProcessSingleWave), and a folder to save them
    in, save them all out as compressed binary .hdf5 files, using their creation
    date concatenated with wave name as the identifier

    Args:
        WaveObjects: The list of Wave Objects to save out
        FolderPath: Where to save the hdf5 files
        NThreads: How many threads to use (optional)
    
    Returns:
        Nothing
    Raises:
        IoError
    """
    p = Pool(NThreads)
    # concatenate the save directory with the Object
    Args = [ (FolderPath,o) for o in WaveObjects]
    p.map(SaveObjectWrapper, Args)

def ConcatenateWaves(*args,**kwargs):
    """
    Wrapper for ProcessSingle.ConcatenateWaves
    Args:
        *args: See ProcessSingle.ConcatenateWaves
        **kwargs: See ProcessSingle.ConcatenateWaves
    Returns
        See ProcessSingle.ConcatenateWaves
    """
    return ProcessSingleWave.ConcatenateWaves(*args,**kwargs)

def GetDataAsTimeSepForceObject(filePath):
    """
    Given a file path, reads the data into a TimeSepForceObj, for easy reading.

    Args:
        filePath: where to get the data from 
    
    Returns:
        A timeSepForceObj, presummabyly with high resolution data
    """
    dataGroup = ReadWaveIntoWaveGroup(filePath)
    return TimeSepForceObj(dataGroup)
