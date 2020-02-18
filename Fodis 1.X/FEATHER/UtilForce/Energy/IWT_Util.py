# force floating point division. Can still use integer with //
from __future__ import division
# This file is used for importing the common utilities classes.
import numpy as np
import matplotlib.pyplot as plt


from UtilGeneral import CheckpointUtilities as pCheckUtil
from UtilGeneral import PlotUtilities
from UtilForce.FEC import FEC_Util,FEC_Plot
from scipy import interpolate


class BoundsObj:
    def __init__(self,bounds_folded_nm,bounds_unfolded_nm,
                 bounds_transition_nm,force_one_half_N):
        self.bounds_folded_nm =bounds_folded_nm
        self.bounds_unfolded_nm = bounds_unfolded_nm
        self.bounds_transition_nm =bounds_transition_nm
        self.force_one_half_N = force_one_half_N

class TiltedLandscape:
    def __init__(self,landscape,f_one_half_N=0,
                 extension_zero_m=0):
        """
        Creates a new tilted landscape object

        Args:
            landscape: the IWT landscape object (from InverseWeierstrass)
            bounds: the IWT_Util.BoundsObj
            kT: 1/beta, assumed constant
            extension_zero : the zero point of extension in meters, for tilting
        """

        self.kT = landscape.kT
        ext = landscape.q - extension_zero_m
        self.Landscape_kT =  landscape.G_0/self.kT
        self.Tilted_kT = self.Landscape_kT - (ext*f_one_half_N)/self.kT
        landscape_ext_nm = ext * 1e9
        self.MinG = min(self.Landscape_kT)
        self.landscape_ext_nm = landscape_ext_nm
        self.Offset = np.percentile(self.Tilted_kT,10)
        self.OffsetTilted_kT = self.Tilted_kT-self.Offset

        
def FitToRegion(x,y,bounds_x):
    """
    Fits to a bounded region

    Args:
        x,y: values to fit
        bounds_x: only fit within these bounds
    Returns:
        tuple of <predicted x, predicted y, coefficients>
    """
    GoodIdx = np.where( ( x >= min(bounds_x)) &
                        ( x <= max(bounds_x)) )
    pred_x = x[GoodIdx]
    pred_y = y[GoodIdx]
    coeffs = np.polyfit(x=pred_x,y=pred_y,deg=2)
    return pred_x,pred_y,coeffs

def ReadInAllFiles(FileNames,Limit,**kwargs):
    """
    Given a list of pxp files, reads them all into a list as 
    TimeSepForce Objcts

    Args:
        FileNames: List of .pxp full paths to data
        Limit: maximum number of curves to return
        kwargs: passed directly to ReadInData
    """
    toRet = []
    for f in FileNames:
        toRet.extend(FEC_Util.ReadInData(f,Limit=Limit,**kwargs))
        # see if we are done
    # only return the limited number we want
    return toRet[:Limit]


def GetIWTObj(Base,FullNames,Force,Limit=150,
              PastZeroExt=60e-9,FilterToMeters=0.25e-9):
    """
    Given files, returns a list of IWT Objects for landscape reconstruction

    Args:
       Base: where to save the cache
       FullNames: ReadInAllFiles 
       Force: if true, force re-creation of the cache
       Limit: maximum number of curves to use 
       PastZeroExt: How much past the surface touchoff to analyze
       FilterToMeters: for determining the surface location, position resolution
       for a savitsky golay filter.
    Returns:
       list of IWT objects, list of TimeSepForce for the retraction, list of 
       TimeSepForce for just the desired amount past touchoff.
    """ 
    mObjs = pCheckUtil.getCheckpoint(Base + "cache.pkl",ReadInAllFiles,
                                     Force,FullNames,Limit)
    ApproachList,RetractList = FEC_Util.BreakUpIntoApproachAndRetract(mObjs)
    # filter all the retractions to the resolution specified,
    # based on the average velocity and the data sampling frequency.
    GetFilter = lambda x: max(3,
                              int((FilterToMeters/x.Velocity)*x.Frequency))
    Touchoff = [FEC_Util.GetFECPullingRegion(r,FilterPoints=GetFilter(r),
                                             MetersAfterTouchoff=PastZeroExt,
                                             Correct=True)
                for r in RetractList]
    # get the IWT transform objects
    IwtObjects = ToIWTObjects(Touchoff)
    return IwtObjects,RetractList,Touchoff


        
def ExtensionOffsetFromCoeffs(coeffs):
    """
    Gets the location of the center of the 'well' from the polynomial coeffs

    Args:
        coeffs: the polynomial coefficients, higherst first, from np.polyfit
    Returns:
        x0, from k/2 * (x-x0)**2, fit 
    """
    return -coeffs[1]/(2*coeffs[0])


    
def split_by_max_sep(obj,fraction_smooth=0.02):
    """
    gets the end of the Unfolding and end of the folding index for object
    
    Args;
        obj: TimeSepForce object
        fraction_smooth: how much to smooth the results by
    Returns:
        tuple of (unfolding index end, folding index end)
    """
    raw_sep = obj.Separation
    n_smooth = int(np.ceil(fraction_smooth*raw_sep.size))
    sep = spline_interpolated_by_index(raw_sep,n_smooth)
    unfold_stop_idx = np.argmax(sep)
    sep_start = sep[0]
    sep_unfold = sep[unfold_stop_idx]
    possible_refold = np.where( raw_sep[unfold_stop_idx:] <= sep_start)[0]
    if (possible_refold.size == 0):
        refold_stop_idx = obj.Separation.size-1
    else:
        refold_stop_idx = unfold_stop_idx + possible_refold[0]
    # determine the actual unfolding index we should use... may have
    # split it improperly
    possible_unfolding_idx = \
        np.where(sep[:unfold_stop_idx] <= sep[refold_stop_idx])[0]
    if (possible_unfolding_idx.size == 0):
        unfold_start_idx = 0 
    else:
        unfold_start_idx = possible_unfolding_idx[-1]
    return unfold_start_idx,unfold_stop_idx,refold_stop_idx
    
    
def kT_to_kcal_per_mol(x=1):
    """
    Returns: <x> times the conversion from kcal/mol to kT
    """
    return x * 0.593
    
def get_unfold_and_refold_objects_by_sep(data,f_split=None,**kwargs):   
    """
    Gets the unfolding and refolding segemnds of a single TimeSepForce object,
    using the separation values to intelligently split
    """
    if (f_split is None):
        f_split = split_by_max_sep
    return get_unfold_and_refold_objects(data,f_split=f_split,**kwargs)
        

    
def spline_interpolated_by_index(f,nSmooth,**kwargs):
    """
    returnsa spline interpolator of f versus 0,1,2,...,(N-1)
    
    Args:
        f: function to interpolate
        nSmooth: distance between knots (smoothing number)
        **kwargs: passed to spline_interpolator
    Returns: 
        spline interpolated value of f on the indices (*not* an interpolator
        object, just an array) 
    """
    x,interp = spline_interpolator_by_index(f,nSmooth,**kwargs)
    return interp(x)
    
def spline_interpolator_by_index(f,n_smooth,**kwargs):
    """
    see spline_interpolated_by_index. except returns tuple of <x,interpolator
    object>
    
    Args:
        see spline_interpolated_by_index
    Returns: 
        see spline_interpolated_by_index 
    """
    x = np.arange(start=0,stop=f.size,step=1)
    return x,spline_interpolator(n_smooth,x,f,**kwargs)

def spline_interpolator(tau_x,x,f,knots=None,deg=2):
    """
    returns a spline interpolator with knots uniformly spaced at tau_x over x
    
    Args:
        tau_x: the step size in whatever units of c
        x: the unit of 'time'
        f: the function we want the autocorrelation of
        knots: the locations of the knots (default to uniform in x)
        deg: the degree of the spline interpolator to use. continuous to 
        deg-1 derivative
    Returns:
        scipy.interpolate.LSQUnivariateSpline object, interpolating f on x
    """
    # note: stop is *not* included in the iterval, so we add an extra step 
    # to make it included
    if (knots is None):
        step_knots = tau_x/2
        knots = np.arange(start=min(x),stop=max(x)+step_knots,
                          step=step_knots)
    # get the spline of the data
    spline_args = \
        dict(
            # degree is k, (k-1)th derivative is continuous
            k=deg,
            # specify the spline knots (t) uniformly in time at the 
            # autocorrelation time. dont want the endpoints
            t=knots[1:-1]
            )
    return interpolate.LSQUnivariateSpline(x=x,y=f,**spline_args)
