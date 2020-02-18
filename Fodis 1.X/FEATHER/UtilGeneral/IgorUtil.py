# force floating point division. Can still use integer with //
from __future__ import division
# This file is used for importing the common utilities classes.
import numpy as np
import matplotlib.pyplot as plt
# import the patrick-specific utilities
from . import GenUtilities  as pGenUtil
from . import PlotUtilities as pPlotUtil
from . import CheckpointUtilities as pCheckUtil
from scipy.signal import savgol_filter
DEF_FILTER_CONST = 0.005 # 0.5%

BASE_GROUP = "/Volumes/group/4Patrick/"
SUBDIR_BINARIES = "PRH_AFM_Databases/BinaryFilesTimeSeparationForce/"

def getDatabaseFolder():
    """
    Returns the location of the database binary folder location
    
    Args:
        None
    Returns:
        Where the database is, as a string. 
    """
    # XXX TODO: right now assumes mac-style mounting...
    return BASE_GROUP + SUBDIR_BINARIES

def getDatabaseFile(fileName,extension=".hdf"):
    """
    Returns the absolute path to a previously-saved file with the given filename
    Path is *not* guaranteed to exist, if the file hasn't been saved already.
    
    Args:
        fileName: the name of the file (usually according to the "TraceData" 
        table, field "FileTimSepFor")

        extension: the recquired extension
    Returns:
        Where the file is located, an absolute path. Doesn't guarantee the file
        *does* exist, just that *if* it does, it would be there.
    """
    fileWithExt = pGenUtil.ensureEnds(fileName,extension)
    return  getDatabaseFolder() + fileWithExt

def DemoDir():
    '''
    :return: the absolute path to the demo directory
    ''' 
    return BASE_GROUP + "DemoData/IgorDemos/"

# all demo directories should have an input and output directory
def GetDemoInOut(demoName,baseDir=DemoDir(),raiseOnError=True):
    """
    Returns the demo input and output directories, given a path baseDir and
    name demoName. Recquires files to exist at "<baseDir><demoName>". If
    encountering an error (e.g. permissions, something isn't mounted), raises
    an error. 
    
    Args:
        demoName: The name of the demo. Assumed to be the subdir under "basedir"
        we want to use 

        baseDir: the base directory. Input and output directories are
        "<baseDir><demoName>Input/" and "<baseDir><demoName>Output/", resp.

        raiseOnError : if true, raises an error on an OS. otherwise, just
        prints a warning that something went wrong. 
    Returns:
        tuple of <inputDir>,<outputDir> 
    """
    fullBase =  baseDir + demoName
    inputV = pGenUtil.getSanitaryPath(fullBase + "/Input/")
    outputV = pGenUtil.getSanitaryPath(fullBase + "/Output/")
    try:
        pGenUtil.ensureDirExists(inputV)
        pGenUtil.ensureDirExists(outputV)
    except OSError as e:
        if (raiseOnError):
            raise(e)
        print("Warning, couldn't open demo directories based in " + fullBase +
              ". Most likely, not connected to JILA network")
    return inputV,outputV

def DemoJilaOrLocal(demoName,localPath):
    """
    Looks for the demo dir in the default (jila-hosted) space. If nothing is
    found, looks in the paths specified by localpath (where it puts input 
    and output directories according to its name) 
    
    Args:
        demoName: see GetDemoInOut

        localPath: equivalent of baseDir in GetDemoInOut. Where we put the input        and Output directories for the unit test if JILA can't be found.

    Returns:
        tuple of <inputDir>,<outputDir> 
    """
    inDir,outDir = GetDemoInOut(demoName,raiseOnError=False)
    if (not pGenUtil.dirExists(inDir)):
        print("Warning: Couldn't connect to JILA's Network. Using local data.")
        # get "sanitary paths" which as OS-indepdent (in theory..)
        localPath = pGenUtil.ensureEnds(localPath,"/")
        inDir = pGenUtil.getSanitaryPath(localPath)
        outDir = pGenUtil.getSanitaryPath(localPath + "Output" + demoName +"/")
        pGenUtil.ensureDirExists(outDir)
        if (not pGenUtil.dirExists(inDir)):
            # whoops...
            raise IOError("Demo Directory {:s} not found anywhere.".\
                          format(inDir))
    return inDir,outDir

# read a txt or similarly formatted file
def readIgorWave(mFile,skip_header=3,skip_footer=1,comments="X "):
    data = np.genfromtxt(mFile,comments=comments,skip_header=skip_header,
                         skip_footer=skip_footer)
    return data


def SavitskyFilter(inData,nSmooth = None,degree=2):
    """
    Filters the data using a savistky-golar filter

    Args:
        inData: the data to filter
        nSmooth: number to smooth
        degree: degree of the polynomial
    """
    if (nSmooth is None):
        nSmooth = int(len(inData)/200)
    # POST: have an nSmooth
    if (nSmooth % 2 == 0):
        # must be odd
        nSmooth += 1
    # make sure we have enough data...
    if (inData.size <= nSmooth):
        return inData
    # get the filtered version of the data
    return savgol_filter(inData,nSmooth,degree)    

def SplitIntoApproachAndRetract(sep,force,sepToSplit=None):
    '''
    Given a full force/sep curve, returns the approach/retract
    according to before/after sepToSplit, cutting out the surface (assumed
    at minimm separation )
    :param sep: the separation, units not important. minimum is surface
    :param force: the force, units not important
    :param sepToSplot: the separation where we think the surface is. same units
    as sep
    '''
    # find where sep is closest to sepToSplit before/after minIdx (surface)
    if (sepToSplit is None):
        sepToSplit = np.min(sep)
    surfIdx = np.argmin(sep)
    sepAppr = sep[:surfIdx]
    sepRetr = sep[surfIdx:]
    apprIdx = np.argmin(np.abs(sepAppr-sepToSplit))
    retrIdx = surfIdx + np.argmin(np.abs(sepRetr-sepToSplit))
    forceAppr = force[:apprIdx]
    forceRetr = force[retrIdx:]
    sepAppr = sep[:apprIdx]
    sepRetr = sep[retrIdx:]
    return sepAppr,sepRetr,forceAppr,forceRetr

def NormalizeSepForce(sep,force,surfIdx=None,normalizeSep=True,
                      normalizeFor=True,sensibleUnits=True):
    if (sensibleUnits):
        sepUnits = sep * 1e9
        forceUnits = force * 1e12
    else:
        sepUnits = sep
        forceUnits= force
    if (surfIdx is None):
        surfIdx = np.argmin(sep)
    if (normalizeSep):
        sepUnits -= sepUnits[surfIdx]
    if (normalizeFor):
        # reverse: sort low to high
        sortIdx = np.argsort(sep)[::-1]
        # get the percentage of points we want
        percent = 0.05
        nPoints = int(percent*sortIdx.size)
        idxForMedian = sortIdx[:nPoints]
        # get the median force at these indices
        forceMedUnits = np.median(forceUnits[idxForMedian])
        # correct the force
        forceUnits -= forceMedUnits
        # multiply it by -1 (flip)
        forceUnits *= -1
    return sepUnits,forceUnits

        
# plot a force extension curve with approach and retract
def PlotFec(sep,force,surfIdx = None,normalizeSep=True,normalizeFor=True,
            filterN=None,sensibleUnits=True):
    """
    Plot a force extension curve

    :param sep: The separation in meters
    :param force: The force in meters
    :param surfIdx: The index between approach and retract. if not present, 
    intuits approximate index from minmmum Sep
    :param normalizeSep: If true, then zeros sep to its minimum 
    :paran normalizeFor: If true, then zeros force to the median-filtered last
    5% of data, by separation (presummably, already detached) 
    :param filterT: Plots the raw data in grey, and filters 
    the force to the Number of points given. If none, assumes default % of curve
    :param sensibleUnits: Plots in nm and pN, defaults to true
    """
    if (surfIdx is None):
        surfIdx = np.argmin(sep)
    sepUnits,forceUnits = NormalizeSepForce(sep,force,surfIdx,normalizeSep,
                                            normalizeFor,sensibleUnits)
    if (filterN is None):
        filterN = int(np.ceil(DEF_FILTER_CONST*sepUnits.size))
    # POST: go ahead and normalize/color
    sepAppr = sepUnits[:surfIdx]
    sepRetr = sepUnits[surfIdx:]
    forceAppr = forceUnits[:surfIdx]
    forceRetr = forceUnits[surfIdx:]
    PlotFilteredSepForce(sepAppr,forceAppr,filterN=filterN,color='r',
                         label="Approach")
    PlotFilteredSepForce(sepRetr,forceRetr,filterN=filterN,color='b',
                         label="Retract")
    plt.xlim([min(sepUnits),max(sepUnits)])
    pPlotUtil.lazyLabel("Separation [nm]","Force [pN]","Force Extension Curve")
    return sepUnits,forceUnits

def filterForce(force,filterN=None):
    if (filterN is None):
        filterN = int(np.ceil(DEF_FILTER_CONST*force.size))
    return savitskyFilter(force,filterN)

def PlotFilteredSepForce(sep,force,filterN=None,labelRaw=None,
                         linewidthFilt=2.0,color='r',**kwargs):
    forceFilt =filterForce(force,filterN)
    plt.plot(sep,forceFilt,color=color,lw=linewidthFilt,**kwargs)
    # plot the raw data as grey
    plt.plot(sep,force,color='k',label=labelRaw,alpha=0.3)
    return forceFilt
    


