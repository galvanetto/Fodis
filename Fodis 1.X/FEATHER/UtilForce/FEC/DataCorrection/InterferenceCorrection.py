# force floating point division. Can still use integer with //
from __future__ import division
# This file is used for importing the common utilities classes.
import numpy as np
import matplotlib.pyplot as plt
import sys
import warnings
DEF_POLYFIT = 30

class CorrectionInfo:
    def SetTimeOffset(self,time):
        """
        Sets the time offset betwen the low and high resolution times
        Args:
            time: the time offset
        """
        self.TimeOffset = time
    def __init__(self,coefficients,description,sliceLowAppr,sliceLowRetr,
                 sliceHiAppr,sliceHiRetr):
        """
        Record the parameters used in the correction Note:
        may *not* match the input by the user, if safecorrection is on
        (this is to prevent crazy polynomial thins happening). We always fit 
        at most what the user tells us (e.g. if the approach was 10ms, but
        the retract was 5ms, unwise to fit pass 5)
    
        Args:
            Coefficients: the coefficients used
            description: the description of the correction
            sliceLowAppr: approach of the low resolution curve 
            sliceLowRetr: retract of the low resolution curve 
            sliceHiAppr: approach of the high resolution curve
            sliceHiRetr: retract of the high resolution curve 
        """
        self.coeffs = coefficients
        self.description = description
        # low resolution slices
        self.sliceLoAppr = sliceLowAppr
        self.sliceLoRetr = sliceLowRetr
        # hi resolution slices
        self.sliceHiAppr = sliceHiAppr
        self.sliceHiRetr = sliceHiRetr
        # time offset (set later) between low and hi res
        self.TimeOffset = None
        

def GetCorrectedY(X,Y,PolynomalDegree=DEF_POLYFIT):
    """
    Given an uncorrect X and Y (e.g. time and DeflV), fits a polynomial 
    to them both and returns the corrected result and fitting coeffs.
    Fits the *entirety* of X and Y in that order. Eventually support other
    fits...

    Args:
        X: in-order x values (e.g. time) to fit
        Y: in-order (e.g. DeflV) to fit. 
        PolynomalDegree : The degree of the polynomial to fit
    Returns:
        polynomial fit of x and Y to degree PolynomalDegree
    """
    polyFit = np.polyfit(X,Y,PolynomalDegree)
    return polyFit

def GetCorrectedHiRes(XLow,YLow,LowSlice,XHigh,YHigh,hiSliceRetr,
                      correction=None,strict=False,SafeCorrection=True,
                      lowSliceRetr=None,hiSliceAppr=None):
    """
    Given an uncorrect X and Y (e.g. time and DeflV) in X and Y,
    and an uncorrect high-resolution wave, corrects the high resolution
    based on given indices (slices) to fit

    Args:
        XLow: in order low resolution x values (e.g. time)
        YLow: in order low resolution y values (e.g. force)
        LowSlice : slice for xlow/ylow to fit. Note that this will probably be 
        the approach curve for low res (ie: you will want to reverse it)

        XHigh: in order high resolution x values
        YHigh: in order high resolution y values

        hiSliceRetr: slice for xhigh/yhigh to fit to 

        correction : type of correction to use.

        strict : If true, explodes if there is a rank-fitting problem.
        These are usually red herrings, but may indicate over-fitting...

        SafeCorrection : If true, if the LowSlice has range (in X units) of x',
        only fits the same range on your slice (this is safer, avoids 
        polynomials doing something crazy)

        lowSliceRetr: if present, also corrects this slice on the low res.
        Useful if we want to correct both the approach and retract

        hiSliceAppr: if present, also corrects this slice on the high res.
        Useful if we want to corect both the approach and retract
    Returns:
        tuple of <correctedDeflV,DeflV,CorrectionInfo>
    """
    if (correction is not None):
        assert False , "No other corrections supported except default"
    with warnings.catch_warnings():
        # determine how to deal with the rank errors...
        if (not strict):
            warnings.simplefilter("ignore")
        else:
            warnings.filterwarnings('error')
        # get the low resolution fit, need to make all the x values relative.
        deg = DEF_POLYFIT
        xLowSliceRel = XLow[LowSlice]
        xLowStart = xLowSliceRel[0]
        coeffsLow = GetCorrectedY(xLowSliceRel-xLowStart,YLow[LowSlice],
                                  PolynomalDegree=deg)
        # correct the low res
        YLowCorrect = np.copy(YLow)
        lowSliceAppr = PolyCorrectSlice(coeffsLow,LowSlice,XLow,LowSlice,XLow,
                                        YLowCorrect,SafeCorrection)
        # Check is we have the other slice (retract) to correct
        if (lowSliceRetr is not None):
            lowSliceRetr = PolyCorrectSlice(coeffsLow,LowSlice,XLow,
                                            lowSliceRetr,XLow,
                                            YLowCorrect,SafeCorrection)
        YHiResCorrect = np.copy(YHigh)
        hiSliceRetr = PolyCorrectSlice(coeffsLow,LowSlice,XLow,hiSliceRetr,
                                       XHigh,YHiResCorrect,SafeCorrection)
        # POST: YHiRes is correced (pass by ref).
        # check if we also should correct the approach.
        if (hiSliceAppr is not None):
            # correct the high res
            hiSliceAppr = PolyCorrectSlice(coeffsLow,LowSlice,XLow,hiSliceAppr,
                                           XHigh,YHiResCorrect,SafeCorrection)
        mInfo = CorrectionInfo(coeffsLow,"Polynomial,d={:d}".format(deg),
                               lowSliceAppr,lowSliceRetr,hiSliceAppr,
                               hiSliceRetr)
        return YLowCorrect,YHiResCorrect,mInfo
    
    
def PolyCorrectSlice(Coefficients,SliceGivingCoefficients,XForCoeffs,
                     SliceToCorrect,XToCorrect,
                     YToCorrect,SafeCorrection=True):
    """
    Given coefficients, and the relevant slices, corrects the *reference* of 
    YToCorrect using a polynomial fit

    Args:
        Coefficients: the (polyfit) coefficients to use 
        SliceGivingCoefficients: slice where the coefficients came from. 
        We assume we are in the same units as this slice, but could be reversed
        (prolly low res)

        XForCoeffs: The x values from which the coeff came (prolly low res)
    
        SliceToCorrect: which part of XToCorrect and YToCorrect to use
        XToCorrect: corresponds to x values of YToCorrect; is *just* used for
        evaluation, not changed
     
        YToCorrect: This array is corrected *by reference* at SliceToCorrect
    Returns:
        The *actual* slice used for correction, if any
    """
    # determine if we need to correct the slice
    if (SafeCorrection):
        # mStep is which direction we are going in
        mStep = SliceToCorrect.step
        # what is the timestep in the correction?
        delta = XToCorrect[1]-XToCorrect[0]
        # what is the full time we can correct oer?
        xLowSliceRel = XForCoeffs[SliceGivingCoefficients]
        deltaSlice = max(xLowSliceRel)-min(xLowSliceRel)
        # cant correct more than deltaSlice/delta=(T/deltaT) points
        maxPoints = int(np.floor(deltaSlice/delta))
        idxStart = SliceToCorrect.start
        idxEnd = SliceToCorrect.stop
        if (mStep > 0):
            # start < end. cant end further than start + max num,
            # or the end of the array, whichever is smaller.
            idxEnd = min(XToCorrect.size,idxStart+maxPoints)
        else:
            # start > end, so pick the minmum of the difference and maxPoints
            idxStart = min(idxStart-idxEnd,maxPoints)
        # XXX assumes indices are forward
        SliceToCorrect = slice(idxStart,idxEnd,mStep)
    xHighSliceRel = XToCorrect[SliceToCorrect]
    # if the slices are reversed in direction,
    # need to multiply by -1; otherwise the poylnomial evaluation goes
    # the wrong direction and is very screwed up.
    factor = 1 if SliceGivingCoefficients.step*mStep > 0 else -1
    YToCorrect[SliceToCorrect] -= \
        np.polyval(Coefficients,factor* (xHighSliceRel-xHighSliceRel[0]))
    return SliceToCorrect

