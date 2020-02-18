# force floating point division. Can still use integer with //
from __future__ import division
# This file is used for importing the common utilities classes.
import numpy as np
import matplotlib.pyplot as plt
# need to add the utilities class. Want 'home' to be platform independent
from os.path import expanduser
home = expanduser("~")
# get the utilties directory (assume it lives in ~/utilities/python)
# but simple to change
path= home +"/utilities/python"
import sys
sys.path.append(path)
# import the patrick-specific utilities
import CypherReader.Util.GenUtilities  as pGenUtil
import CypherReader.Util.PlotUtilities as pPlotUtil
# recquired packages for HD5
import h5py

READ_MODE ='r'
WRITE_MODE = 'w'
# default output from igor.
DEFAULT_IGOR_DATASET = u'PrhHD5GenericData'
DEFAULT_IGOR_NOTE_ATTR = u'IGORWaveNote'
# binary hdf5 extention
DEFAULT_HDF5_EXTENSION = ".hdf"
# Binary file columns
COLUMN_TIME = 0
COLUMN_SEP = 1
COLUMN_FORCE = 2
# default options for compression
DEF_COMPRESSER = "gzip"
 # experimentally, this is the best
#Based on tests using time,sep, and force 5MHZ data, 1 looks like enough
# Igor text file: 512MB
# HDF5 Without GZIP, 126MB
# With GZIP=1, 61MB (48%)
# With GZIP =8, 58MB (46%, but much much slower)
DEF_COMPRESSER_LEVEL = 1
import copy 

class Hdf5Tuple:
    """
    Convenient class to wrap the data and attributes for a dataset.
    Makes a deep copy of the data

    """
    def __init__(self,dataset):
        """
        Given a dataset from an hdf5 file, makes a deep copy of the data
        and its attributes
        
        Returns:
            None
        """
        self.dataset = dataset[:]
        self.attrs = dict(dataset.attrs.items())
        self.name = dataset.name

# given a path to a binary file, reads in the HDF5
def GetTimeSepForce(binaryFilePath):
    """
    Given a path to a binary file, reads in (the assumed generic/default)
    dataset, and gets the columns for time, separatio, and force
    
    Returns:
        tuple of (time,sep,force) arrays
    Raises:
        IoError
    """
    # make sure we have the right extensions
    # XXX throw error otherwise?
    mFile = pGenUtil.ensureEnds(binaryFilePath,DEFAULT_HDF5_EXTENSION)
    time = ReadHDF5FileDataSet(mFile)[:,COLUMN_TIME]
    sep = ReadHDF5FileDataSet(mFile)[:,COLUMN_SEP]
    force = ReadHDF5FileDataSet(mFile)[:,COLUMN_FORCE]
    return time,sep,force

def WriteHDF5Array(filePath,array,attr=None,dataset=DEFAULT_IGOR_DATASET,
                   compression=DEF_COMPRESSER,
                   compression_opts=DEF_COMPRESSER_LEVEL ):
    """
    Given an array, list of attributes, and dataset, writes the array to file

    Args:
        filePath: full path to file to save

        array: What array to write. Can be a single array or a <dataset>:<data>
        dictionary

        attr: a dictionary of name-value attributes. Can be a single dictionary 
        or a dictionary like <dataset>:<dictionary>  
        (ie: each dataset with its own)

        dataset: The name of the dataset. Ignored if attr and array are dicts

        compression: The name of compression to use (e.g. "gzip")
        compression_opts: The level of compression.
    
    Returns:
        Nothing
    Raises:
        IoError
    """
    with h5py.File(filePath, WRITE_MODE) as f:
        # we may want to save out multiple data sets, if the array is a dict
        if (isinstance(array,dict)):
            # then make sure everything is OK
            # are the attributes also a dict?
            assert (isinstance(attr,dict)) ,\
                "data to save is dict, attr are not"
            # do the dataset names match?
            assert (set(array.keys()) == set(attr.keys())) ,\
                "Dataset name (key) mismatch"
            # POST... should be ok!
            for keyDataName in array:
                WriteDataSet(f,keyDataName,array[keyDataName],
                             compression,compression_opts,
                             attr=attr[keyDataName])
        else:
            # just a simple write,
            WriteDataSet(f,dataset,array,compression,
                         compression_opts,attr=attr)
    # POST: all done!

def WriteDataSet(f,datasetName,array,compression,compression_opts,attr=None):
    """
    Given an array, list of attributes, and dataset, writes the array as a 
    datase to the already-opened HDF5 file. Doesn't do *any* maintenance on
    the file 

    Args:
        f: the already open HDF5 file to write into

        datasetName: name of the dataset

        array: What array to write. Can be a single array or a <dataset>:<data>
        dictionary

        attr: a dictionary of name-value attributes. 


        compression: See WriteHDF5Array
        compression_opts: See WriteHDF5Array
    
    Returns:
        Nothing
    Raises:
        IoError
    """
    dset = f.create_dataset(name=datasetName,data=array,
                            compression=compression,
                            compression_opts=compression_opts)
    # write the attributes, if they are there
    if (attr is not None):
        for key,val in attr.items():
            dset.attrs[key] = val

    
# reads the file; does *not* close it...
def ReadHDF5File(inFile):
    """
    Reads in an HDF5, does *not* do any maintenane on the file (cleaning,etc)

    Args:
        inFile: path to the file
    Returns:
        Nothing
    Raises:
        IoError
    """
    if (not pGenUtil.isfile(inFile)):
        mErr = ("ReadHDF5File : File {:s} not found.".format(inFile) +
                "Do you need to connect to a netwrok drive to find your data?")
        raise IOError(mErr)
    # POST: the file at least exists
    mFile = h5py.File(inFile,READ_MODE)
    return mFile

def GetHDF5NoteFromDataTuple(dataTuple):
    """
    Given a Hdf5Tuple object, gets the associated note. 

    Args:
        dataTuple: the object to get the note of
    Returns:
        note 
    Raises:
        IoError
    """
    if (DEFAULT_IGOR_NOTE_ATTR in dataTuple.attrs):
        # 'old style' (string) note
        mNote = dataTuple.attrs[DEFAULT_IGOR_NOTE_ATTR]
    else:
        # get the 'full' note.
        mNote = dataTuple.attrs
    return mNote

def GetHDF5DataAndWaveNote(inFile,dataSet=DEFAULT_IGOR_DATASET):
    """
    Reads in an HDF5 file saved with the dataset name / given the note as 
    a default attribute

    Args:
        inFile: path to the file to read in 
        dataSet: name of the dataset to read in . 
    Returns:
        tuple of <dataset,Note>
    Raises:
        IoError
    """
    mDict = ReadHdf5AllDatasets(inFile)
    Tuple = mDict[dataSet]
    DataSet = Tuple.dataset
    mNote = GetHDF5NoteFromDataTuple(Tuple)
    return DataSet,mNote

def ReadHdf5AllDatasets(inFile):
    """
    Reads in the attributes of the given file. returns a dictionary of 
    <dataset:(data,attr)> for the <key,val> pairs

    Args:
        inFile: path to the file to read in 
    Returns:
        Nothing
    Raises:
        IoError
    """
    mFile = ReadHDF5File(inFile)
    if (mFile is None):
        raise IOError("Couldn't open HDF5File {:s}".format(inFile))
    # POST: file exists
    toRet = dict()
    try:
        allDataSets = mFile.keys()
        for dataSet in allDataSets:
            dataObj = mFile[dataSet]
            toRet[str(dataSet)] = Hdf5Tuple(dataObj)
    finally:
        # always close the file
        mFile.close()
    return toRet
    
def ReadHDF5FileDataSet(inFile,dataSet=DEFAULT_IGOR_DATASET ):
    mDataSet,_ = GetHDF5DataAndWaveNote(inFile,dataSet=dataSet)
    return mDataSet

