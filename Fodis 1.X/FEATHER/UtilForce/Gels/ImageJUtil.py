# force floating point division. Can still use integer with //
from __future__ import division
# This file is used for importing the common utilities classes.
import numpy as np
import matplotlib.pyplot as plt
import sys
import os
import UtilGeneral.GenUtilities as pGenUtil
from collections import OrderedDict
sys.path.append("../../../../")
import re

class LaneObject(object):
    """
    Class to keep track of (generalized) lanes
    """
    def __init__(self,*lanes):
        self.Lanes = np.array(list(lanes))
        self.TotalIntensity = np.sum(self.Lanes)
    def Normalized(self,LaneIndex):
        """
        Returns the normalized pixel intensity in laneindex "LaneIndex"
        """
        assert LaneIndex < len(self.Lanes) , "Asked for a lane we dont have"
        return self.Lanes[LaneIndex]/self.TotalIntensity
    def NormalizedIntensities(self):
        """
        Returns a list of all the normalized intensities
        """
        return [self.Normalized(i) for i in range(len(self.Lanes))]
    def __str__(self):
        return "\n".join("Lane{:03d}={:.2f}".format(i,self.Normalized(i))
                         for i in range(self.Lanes.size))

class OverhangLane(LaneObject):
    """
    Class to keep track of the bands in an overhang lane
    """
    def __init__(self,Linear,Circular=0,Concat=0,*args):
        if len(args) > 0:
            Concat += sum(args)
        super(OverhangLane,self).__init__(Linear,Circular,Concat,*args)
        self.LinearBand=Linear
        self.CircularBand = Circular
        self.Concatemers = Concat
    def _Norm(self,x):
        return x/self.TotalIntensity
    @property
    def LinearRelative(self):
        """
        Gets the relative linear intensity
        """
        return self._Norm(self.LinearBand)
    @property
    def CircularRelative(self):
        """
        Gets the relative circular intensity
        """
        return self._Norm(self.CircularBand)
    @property
    def ConcatemerRelative(self):
        """
        Gets the relative concatemer intensity
        """
        return self._Norm(self.Concatemers)
    def __str__(self):
        return "Lin:{:3.2f},Circ:{:3.2f},Concat:{:3.2f}".\
            format(self.LinearRelative,
                   self.CircularRelative,
                   self.ConcatemerRelative)
    def __repr__(self):
        return str(self)

class LaneTrialObject(object):
    """
    Idea of this class is to represent multiple lanes, each of which 
    have the same contents loaded
    """
    def __init__(self,lanes):
        self.lanes = lanes
    def MeanLane(self,idx):
        """
        Get the mean value of all the lane 'copies', for a given lane
        """
        return np.mean([l.Normalized(idx) for l in self.lanes])
    def StdevLane(self,idx):
        """
        Get standard deviation of all the lane 'copies', for a given lane
        """
        return np.std([l.Normalized(idx) for l in self.lanes])
    def MeanStdev(self,idx):
        return self.MeanLane(idx),self.StdevLane(idx)
    def __str__(self):
        return "\n".join("{:s}".format(l) for l in self.lanes)

class OverhangTrialObject(LaneTrialObject):
    def __init__(self,lanes):
        super(OverhangTrialObject,self).__init__(lanes)
    @property
    def LinearMeanStdev(self):
        """
        Returns a tuple of the mean and standard deviation for the linear lane
        """
        return self.MeanStdev(0)
    @property
    def CircularMeanStdev(self):
        """
        Returns a tuple of the mean and standard deviation for the circular lane
        """
        return self.MeanStdev(1)
    @property
    def ConcatemerMeanStdev(self):
        """
        Returns a tuple of mean and standard deviation for concatemer lane(s)
        """
        return self.MeanStdev(2)
    @property
    def LinearRelative(self):
        """
        Returns the mean for the linear lane
        """
        return self.LinearMeanStdev[0]
    @property
    def CircularRelative(self):
        """
        Returns the mean for the circular lane
        """
        return self.CircularMeanStdev[0]
    @property
    def ConcatemerRelative(self):
        """
        Returns the mean for the concatemer lane
        """
        return self.ConcatemerMeanStdev[0]
    def GetErrors(self):
        """
        Returns a list of the stdevs for linear, circular, and concatemer
        """
        props = [self.LinearMeanStdev,self.CircularMeanStdev,
                 self.ConcatemerMeanStdev]
        return [p[1] for p in props]
    
def GetImageJData(DataDirBase,ext=".xls"):
    """
    Given a base data directory, finds all files with ext in each subdirectory

    Args:
        DataDirBase: base data directory. Each subdirectory has files with 
        extension 'ext'
       
        ext: file extension
    Returns:
        ordered dictionary of <subdir:fullpaths>
    """
    Voltages = OrderedDict()
    for f in sorted(os.listdir(DataDirBase)):
        PossibleSubDir = DataDirBase + f +"/"
        if (os.path.isdir(PossibleSubDir)):
            Files = pGenUtil.getAllFiles(PossibleSubDir,".xls")
            Voltages[f] =Files
    return Voltages

def ReadFileToLaneObj(File):
    """
    Given a file, get it as a lane object.

    Args:
        File: see ReadFileToOverhangObj
    Returns:
        LaneObject
    """
    return LaneObject(*list(GetImageJMeasurements(File)))

def ReadFileToOverhangObj(File):
    """
    get the file's data, as an OverhangLane object

    Args:
       File: full path to the file to read. Must be formatted with the second
       column being the intensitieis, and the rows being <concat if any,
       circular if any, linear>
    Returns:
       OverhangLane object
    """
    Measurements = GetImageJMeasurements(File).tolist()
    if type(Measurements) is float:
        Measurements = [Measurements]
    # reverse so it goes linear,circular,conat
    return OverhangLane(*(Measurements[::-1]))
    
def GetImageJMeasurements(File):
    """
    Returns the in-order values of the intensity column in the ImageJ xls file

    Args:
        File: to read from
    Returns:
        intensity column
    """
    return np.loadtxt(File,skiprows=1,usecols=(1,))

def GetLaneTrialsMatchingName(DataDirBase,FilePattern,ext=".xls"):
    FileNames = pGenUtil.getAllFiles(DataDirBase,ext)
    Copies = []
    for f in FileNames:
        if (re.match(FilePattern, f) is not None):
            print("si")
            Copies.append(f)
    assert len(Copies) > 0 , "Couldn't find any files to load"
    # now get the lanes from the files
    Lanes = [ReadFileToOverhangObj(f) for f in Copies]
    # now convert the lanes to a single object, with the means and standard
    # deviations
    return OverhangTrialObject(Lanes)
