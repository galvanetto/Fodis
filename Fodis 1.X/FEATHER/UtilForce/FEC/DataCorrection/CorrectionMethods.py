# force floating point division. Can still use integer with //
from __future__ import division
# This file is used for importing the common utilities classes.
import numpy as np
import matplotlib.pyplot as plt
from InterferenceCorrection import GetCorrectedHiRes,CorrectionInfo
from OffsetCorrection import CorrectAndInteprolateZsnsr
import copy

class TouchoffInfo:
    def __init__(self,LoadingRate,LoadTime,TriggerIdx,SurfaceIdx,SurfaceTime,
                 FitInfo):
        """
        Class to record information about a touchoff
        
        Args:
            LoadingRate: rate at which force is applied (time deriv)
            LoadTime: approximate time between start of invols and dwell, > 0
            TriggerIdx: index in the time basis where either stopped (approach)
            or started (retract) moving
            SurfaceIdx: approximate location of the surface
            FitInfo: the fitting information for these coefficients
        """
        self.LoadingRate = LoadingRate
        self.LoadTime = LoadTime
        self.TriggerIdx = TriggerIdx
        self.SurfaceIdx = SurfaceIdx
        self.FitInfo = FitInfo
        self.SurfaceTime = SurfaceTime  

        
def GetCorrectedAndOffsetHighRes(WaveDataGroup,SliceCorrectLow,SliceCorrectHi,
                                 TimeOffset):
    """
    Given a WaveDataGroup with low res an hi res data, returns the
    corrected, high resolution x and y

    Args:
        WaveDataGroup: Model.WaveDataGroup object
        SliceCorrectLow : The slice of the low resolution data to take the 
        correction from
    
        SliceCorrectHi: The slice of the high-resolution data to correct

        TimeOffset: The offset (in seconds) from low to high resolution
        (i.e. zsnsr). We always assume the high resolution data lags, so >0.
    
    Returns:
        A tuple of <Sep,Force> in the offset, corrected limit, just the data
    """
    # get the low res time,force and sep
    time,sep,force = WaveDataGroup.CreateTimeSepForceWaveObject().\
                     GetTimeSepForceAsCols()
    # get the high-res force and time 
    forceHi = WaveDataGroup.HighBandwidthGetForce()
    timeHi = WaveDataGroup.HighBandwidthWaves.values()[0].GetXArray()
    # ignore the low resolution corrected force and information object
    sep,force,_,_ = GetCorrectedFromArrays(time,sep,force,timeHi,forceHi,
                                           SliceCorrectLow,
                                           SliceCorrectHi,TimeOffset)
    return sep,force

def GetCorrectedFromArrays(timeLo,sepLo,forceLo,timeHi,forceHi,SliceCorrectLow,
                           SliceCorrectHi,TimeOffset,lowSliceRetr=None,
                           hiSliceAppr=None):
    """
    Given the arrays, gets the corrected versions, including offsetting the 
    zsnsr so that force versus zsnsr is correct

    Args:
        timeLo: the low resolution time
        sepLo: the low resolution separation
        forceLo: the low resolution force
        timeHi: ibid, hi res
        forceHi: ibid, hi res
        SliceCorrectLow: The slice of the low resolution data to fit the 
        wiggles. Typically, this is the approach
       
        SliceCorrectHi: the slice of the high resolution dta to correct. 
        typically retract
    
        TimeOffset: the time offset (hi-low) between the hi and low resolution 
        curves
        
        lowSliceRetr : see GetCorrectedHiRes

        hiSliceAppr : see GetCorrectedHiRes
    """
    # correct the force
    correctLowResForce,correctedHiResForce,info = \
            GetCorrectedHiRes(timeLo,forceLo,SliceCorrectLow,
                              timeHi,forceHi,SliceCorrectHi,
                              lowSliceRetr=lowSliceRetr,
                              hiSliceAppr=hiSliceAppr)
    # set the time offset we used
    info.SetTimeOffset(TimeOffset)
    # offset and interpolate the sep (zsnsr method works fine here) 
    interpHiResSep = CorrectAndInteprolateZsnsr(sepLo,timeLo,TimeOffset,timeHi)
    return interpHiResSep,correctedHiResForce,correctLowResForce,info

def GetApproachCorrectionAndInfo(time,force,triggerTime):
    """
    Given the approach time and force, gets the wiggle-corrected version, as
    well as the information from the fit

    Args:
        time: the time basis to use
        force: the force to use
        triggerTime: where the approach ends (ie: surface touchoff time)
    Returns:
        tuple of <corrected force approach,correction info>
    """
    triggerIdx = np.argmin(np.abs(time-triggerTime))
    # determine corrections on the approach
    sliceFitAndCorrect = slice(triggerIdx,0,-1)
    # correct the low resolution data; correct and fit using the same data
    # with no time offset
    offset = 0.
    _,_,corr,info = \
     GetCorrectedFromArrays(time,time,force,time,force,sliceFitAndCorrect,
                            sliceFitAndCorrect,offset)
    return corr,info

def GetApproachInfo(time,force,triggerTime,deg=3):
    """
    Returns a TouchoffInfo information object for this approach

    Args:
        time: see GetApproachCorrectionAndInfo
        force: see GetApproachCorrectionAndInfo
        triggerTime: see GetApproachCorrectionAndInfo
        deg: how high of a polynomial fit to use to calculate the surface 
    
    Returns:
        TouchoffInfo 
    """
    # get the correction information
    corr,info = GetApproachCorrectionAndInfo(time,force,triggerTime)
    sliceFitAndCorrect = info.sliceLoAppr
    triggerIdx = sliceFitAndCorrect.start
    # coefficients from polyfit are ordered from high to low
# http://docs.scipy.org/doc/numpy-1.10.0/reference/generated/numpy.polyfit.html
    # it follows the loading rate is next to last, offset is last
    yOffset = info.coeffs[-1]
    loadingRate = info.coeffs[-2]
    timeToFit = copy.copy(time[sliceFitAndCorrect])
    fitTimeOffset = timeToFit[0]
    timeToFit -= fitTimeOffset
    corrected = corr[sliceFitAndCorrect]
    loading = yOffset + loadingRate * (timeToFit)
    # look at the slide we actually corrected
    sliceCorrected = slice(sliceFitAndCorrect.start-1,0,-1)
    forceCorrected = corr[sliceCorrected]
    timeCorrected = time[sliceCorrected]
    # get the median (this is more or less the 'true zero')
    medForce = np.median(forceCorrected)
    # get the time it takes to get to that median; this is a good
    # approximation to the invols time
    diff = np.abs(medForce-loading)
    idxToSurfaceRel = np.argmin(diff)
    timeToSurfaceRel = timeToFit[idxToSurfaceRel]
    # convert the indices to absolute, along the data
    idxToSurface = sliceCorrected.start - idxToSurfaceRel
    timeToSurface = time[idxToSurface]
    loadTime = triggerTime - timeToSurface
    return TouchoffInfo(loadingRate,loadTime,triggerIdx,
                        idxToSurface,timeToSurface,info)
    

def GetTimeOffset(delta1,idx1,delta2,idx2):
    """
    Given two delta and indices in them, gets the average time difference
    between the indices. For example, {xArr1,xArr2} could be low/hi res time,
    and we want an absolute time offset. Assumes that xArr1 and xArr2 have
    the same units.

    Unit Tested by HighbandwidthCorectionGroundTruth

    Args:
       delta1: deltas in the first array
       idx1: indices into the first array, corresponding to specific x values
       delta2: the second array
       idx2: indices into the second array, corresponding to specific x values

    Returns:
        average difference from the indices in units of x values. Meaning,
        sum(xArr[i]-xArr[i])/len(idx1)
    """
    timeDiff = (np.array(idx2) * delta2) - \
               (np.array(idx1) * delta1)
    timeOffset = sum(timeDiff)/len(idx1)
    return timeOffset

def GetCorrectionSlices(idxLowStart,idxHighStart):
    """
    Given low resolution approach touchoff index and high resolution 
    retract touchoff index, gets the appropriate slices for correction

    Unit Tested by HighbandwidthCorectionGroundTruth

    Args:
       idxLowStart: where the low resolution data touches the surface first
       idxHighStart: where the high-resolution data touches the surface last

    Returns:
        tuple of <slicelo,sliceHi>, used by correction methods
    """
    sliceLow = slice(idxLowStart,0,-1)
    sliceHigh = slice(idxHighStart,None,1)
    return sliceLow,sliceHigh


def CorrectForcePullByMetaInformation(Object,deg=50):
    """
    Corrects a TimeSepForce-like object using its meta data (ie: trigger time
    and dwell time -- really only useful for low resolution data)

    Args:
        Object: TimeSepForce Object
        deg: the polynomial degree to use 
    Returns:
        tuple: <corrected *copy* of Object,CorrectionInfo>
    """
    Force = Object.Force
    Time = Object.Time
    Separation = Object.Separation
    Force = Object.Force
    Meta = Object.Meta
    TriggerTime = Meta.TriggerTime
    DwellTime = Object.SurfaceDwellTime
    TriggerIndex = np.argmin(np.abs(Time-TriggerTime))
    # we will make a deep copy to work with, the 'corrected' version
    Corrected = copy.deepcopy(Object)
    # fit a polynomial to the approach portion ('reversed')
    ApproachSlice = slice(TriggerIndex,0,-1)
    FittingX = Separation[ApproachSlice].copy()
    FittingY = Force[ApproachSlice].copy()
    MinY = min(FittingY)
    FittingX -= min(FittingX)
    FittingY -= MinY
    Bad = True
    while Bad:
        try:
            coeffs = np.polyfit(x=FittingX,
                                y=FittingY,deg=deg)
            Bad = False
        except ValueError:
            # badly conditioned matrix; too high of a degree
            deg -= 1
    # add back in the DC offset
    coeffs[-1] += MinY
    # get the index where we leave the surface
    LeaveTime = TriggerTime+DwellTime
    LeaveIndex = np.argmin(np.abs(Time-LeaveTime))
    RetractMax = min(LeaveIndex+TriggerIndex,Corrected.Force.size)
    RetractSlice = slice(LeaveIndex,RetractMax,1)
    # the retract might be a different size than the approach. We *really*
    # have to be careful to stay in region where the polynomial fit is valid
    RetractForce = Corrected.Force[RetractSlice]
    RetractForceSize = RetractForce.size
    # get the fitted values to the *approach*.
    ApprSep = Separation[ApproachSlice]
    RetrSep = Separation[RetractSlice]
    FitToApproach = np.polyval(coeffs,x=ApprSep-min(ApprSep))
    FitToRetract = np.polyval(coeffs,x=RetrSep-min(RetrSep))
    # correct the approach and retract; approach is easy, just lop off the
    # thing we just fit
    Corrected.Force[ApproachSlice] -= FitToApproach
    # further, we only want to correct up to an including however
    # long the actual retract is
    RetractForce -= FitToRetract
    CorrectionInf = CorrectionInfo(coeffs,"PolynomialFit",
                                   ApproachSlice,
                                   RetractSlice,ApproachSlice,RetractSlice)
    return Corrected,CorrectionInf
