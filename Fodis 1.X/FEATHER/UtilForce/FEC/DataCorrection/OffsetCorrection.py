# force floating point division. Can still use integer with //
from __future__ import division
# This file is used for importing the common utilities classes.
import numpy as np
from scipy.interpolate import interp1d

def CorrectAndInteprolateZsnsr(zsnsr,zsnsrTime,timeOffset,newTime):
    """
    Corrects zsnsr and interpolates such that the new Zsnsr is at 'zsnsrTime'
    (relative to the old Zsnsr) and is interpolated along the 'newTime' values

    Args:
        zsnsr:  zsnsr data to correct and interpolate
        zsnsrTime: time array of zsnsr. assumed monotonically increasing 
        and uniformly increasing

        timeOffset: offset, new Zsnsr zero point will be this time offset. 
        assumed non negative (abs is taken)

      
        newTime: time base to offset from (should start from 0)
    Returns:
        interpolated, offset Zsnsr
    """
    # have corrected Zsnsr, now interpolate
    zsnsrInterp = LinearInterpolate(zsnsrTime-zsnsrTime[0] + timeOffset,
                                    zsnsr,
                                    newTime - newTime[0])
    return zsnsrInterp

def OffsetCorrect(Data,sliceV):
    """
    Returns a 1-D dataset (e.g. Zsnsr) offset such that it starts at index 
    given by idx

    Args:
        Data:  data to offset
        sliceV: slice of data we want
    
    Returns:
        New copy of data, offset to desired idx
    """
    return Data[:][sliceV]

def LinearInterpolate(xTrue,yTrue,xDesired):
    """
    Linearly interpolates yTrue, gridded on xTrue, to xDesired. If xDesired
    goes outside of the range, defaults to extrapolation

    Args:
        xTrue: x values to intepolate. Assumed sorted
        yTrue: y values to inteporlate
        xDesired: desired x values to interpolate along
    
    Returns:
        This is a description of what is returned.
    """
    return interp1d(xTrue,yTrue,assume_sorted=True,copy=False,
                    bounds_error=False,fill_value="extrapolate")(xDesired)

if __name__ == "__main__":
    run()
