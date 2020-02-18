# force floating point division. Can still use integer with //
from __future__ import division
# This file is used for importing the common utilities classes.
import numpy as np
import matplotlib.pyplot as plt
import sys,ast,os

import copy
from ..UtilIgor.DataObj import DataObj
from ..UtilIgor.TimeSepForceObj import TimeSepForceObj,Bunch
from ..UtilIgor import PxpLoader,ProcessSingleWave
from ..UtilIgor.WaveDataGroup import WaveDataGroup
from ..UtilIgor import TimeSepForceObj
from ..UtilGeneral.IgorUtil import SavitskyFilter
from ..UtilGeneral import GenUtilities,CheckpointUtilities

default_filter_pct = 0.01

class DNAWlcPoints:
    class BoundingIdx:
        def __init__(self,start,end):
            self.start = start
            self.end = end
    def __init__(self,Wlc1Start,Wlc1End,Wlc2Start,Wlc2End,TimeSepForceObj):
        self.FirstWLC = DNAWlcPoints.BoundingIdx(Wlc1Start,Wlc1End)
        self.SecondWLC = DNAWlcPoints.BoundingIdx(Wlc2Start,Wlc2End)
        self.TimeSepForceObject = TimeSepForceObj

class WlcCharacerizationMask:
    def __init__(self,NoAdhesion,ForceOutliers,Gradient,
                 NumFilterPoints):
        self.NoAdhesion = NoAdhesion
        self.ForceOutliers = ForceOutliers
        self.Gradient = Gradient
        self.NumFilterPoints = NumFilterPoints
    
def default_data_root():
	"""
	Returns the default system (absolute) path to perknas, assuming mounted
	"""
	os_name = os.name
	if (os_name == "nt"):
		# windows
		to_ret = "//perknas2.colorado.edu/group/"
	elif (os_name == "mac" or os_name == "posix"):
		# macintosh
		to_ret = "/Volumes/group/"
	else:
		# throw an error... dont know what to do
		raise OSError("Didn't recognize OS name: {:s}".format(os_name))
	return to_ret
	
def _groups_to_time_sep_force(m_data,limit):
    """
    converts a list of <name:<wave type:data>> objects into TimeSepForce objects
    
    Args:
        m_data: return of (e.g.) PxpLoader.LoadPxp
        Limit: see ReadInData
    Returns: at most Limit objects
    """
    # convert the waves into TimeSepForce objects
    Objs = [TimeSepForceObj.TimeSepForceObj(WaveDataGroup(v)) 
            for _,v in m_data.items()]
    # note: limit=None gives everything on upper bound
    return Objs[:limit]
    
def read_ibw_directory(directory,grouping_function,limit=None,**kw):
    """
    Reads all ibw files in the given directory
    
    Args:
        directory: where to read from
        grouping_function: how to group the ibw files, by file name
        limit: how many to load
        kw: passed to load_ibw_from_directory
    Returns: at most Limit objects
    """
    data = PxpLoader.\
        load_ibw_from_directory(directory,limit=limit,
                                grouping_function=grouping_function,**kw)
    return _groups_to_time_sep_force(data,limit=limit)
    
def cache_ibw_directory(cache_directory,in_directory,limit=None,force=False,
                        **kwargs):
    """
    reads a directory of ibw files, caching each TimeSepForce object 
    *individually* (which is critical for huge ibw's)
    
    Args:
        cache_directory,in_directory: where to put the cache / read ibws from   
        limit: maximum number of curves
        *args,**kwargs: passed to read_ibw_directory
    Returns:
        list of TimeSepForce objects, after properly cachine
    """
    return cache_individual_waves_in_directory(pxp_dir=in_directory,
                                               cache_dir=cache_directory,
                                               limit=limit,
                                               load_func = read_ibw_directory,
                                               force=force,**kwargs) 


def ReadInData(FullName,Limit=None,**kwargs):
    """
    Reads in the PXP waves as TimeSepForce Object (must *only* wave waves with
    Cypher-like wave endins in FullName
    
    Args:
        FullName: Path to the pxp file to load in
        Limit: maximum number to read in. If none, defaults to all (!)
        **kwargs: passed to LoadPxp
    """
    MData = PxpLoader.LoadPxp(FullName,**kwargs)
    return _groups_to_time_sep_force(MData,Limit)


def read_single_directory(directory,**kwargs):
    """
    reads the pxp files and data in a single directory, returning the 
    files and the data

    Args:
        directory: to search in  
		**kwargs: pass to ReadInData
    Returns:
        tuple of <files read, TimeSepForce Objects>
    """
    pxp_files = GenUtilities.getAllFiles(path=directory,ext=".pxp")
    data = [ReadInData(f,**kwargs) for f in pxp_files]
    return pxp_files,data
	
def concatenate_fec_from_single_directory(directory,**kwargs):
	"""
	Reads in all the pxp files in a directory, concatenating their waves	
	and returning them as a list of TimeSepForce objects
	
	Args:
		directory: see  read_single_directory
		kwargs: passed to save_single_directory
	Returns:
		see  read_single_directory, except 1-D list 
	"""
	files,data = read_single_directory(directory,**kwargs)
	to_ret = []
	for d in data:
		to_ret.extend(d)
	return files,to_ret

def read_and_cache_pxp(directory,cache_name=None,force=True,**kwargs):
    """
    reads a directory of pxp files, caches to cache_name
    
    Args:
        directory: see concatenate_fec_from_single_directory
        cache_name: where to save the pkl of the read. defaults to cwd
        force: if we should force a re-read. defaults to true to prevent stale
        **kwargsL passed to concatenate_fec_from_single_directory
    Returns:
        see concatenate_fec_from_single_directory
        
    """
    if (cache_name is None):
        cache_name = "./cache.pkl"
    d =CheckpointUtilities.getCheckpoint(cache_name,
                                         concatenate_fec_from_single_directory,
                                         force,directory,**kwargs)
    return d
    
def fec_name_func(i,e,max_preamble_len=40,max_name_len=30):
    """
    Args:
        i: an arbitrary id integer  
        e: TimeSepForce or SurfaceObject
    Returns:
        a name for saving object e (TimeSepForce_ into) file <i> (arbitrary)
        See also: cache_individual_waves_in_directory and the name_func
        parameter of CheckpointUtilities.multi_load
    """
    # save like <cache_dir>/<file_name>_<WaveName><arbitrary_id>
    file_name_src =  GenUtilities.file_name_from_path(e.Meta.SourceFile)
    preamble = file_name_src
    if len(file_name_src) > max_preamble_len:
        preamble = preamble[:max_preamble_len//2] + "_" + \
                   preamble[-max_preamble_len//2:]
    name = "{:s}_{:s}".format(preamble,
                              e.Meta.Name[:max_name_len])
    return name                                  
    
def cache_individual_waves_in_directory(pxp_dir,cache_dir,limit=None,
                                        force=False,load_func=None,**kwargs):
    """
    reads in all pxp files in a directory, caching their waves 
    (as TimeSepForce objects) to cache_dir, returning a list of TimeSepForce
    objects

    Args:
        <pxp/cache>_dir: where the input pxps live, where to put the cached
        files
        
        limit: maximum number to read out of the cached dir. will cache 
        as many waves in the pxp as it can, but will only return up to limit 
        
        force: if true, force re-reading. 
        
        load_func: which function to use. if none, defaults to pxp. must accept
        the directory as its first argument, and return a list of TimeSepForce
        objects
        
        **kwargs: passed to load_func
    Returns:
        list of TimeSepForce objects; at most limit (depending on the dta)
    """
    if (load_func is None):
        # by default, we read the pxps in the directory
        # and get the last return (TimeSepForce)
        load_func = lambda *args,**kwargs: \
            concatenate_fec_from_single_directory(*args,**kwargs)[-1]     
    load_functor = lambda: load_func(pxp_dir,**kwargs)          
    return CheckpointUtilities.multi_load(cache_dir=cache_dir,
                                          load_func=load_functor,
                                          force=force,limit=limit,
                                          name_func=fec_name_func)

def _slice_by_property(obj,min_prop,max_prop,property_func):
    """
    slices an object into a nerw object by a certain propery range
    
    Args:
        see slice_by_time, except...
        property_func: takes in obj, returns the desired property
    Returns:
        new, sliced object. If it cant find the bounds, it just returns
        as much data as it can
    """
    property = property_func(obj)
    idx_greater_than_min = np.where(property >= min_prop)[0]
    idx_less_than_max = np.where(property <= max_prop)[0]
    # determine where to put the indices
    n_greater = idx_greater_than_min.size 
    n_less = idx_less_than_max.size
    if (n_greater== 0):
        idx_first = 0
    else: 
        idx_first = idx_greater_than_min[0]
    if (n_less == 0):
        idx_last = None
    else: 
        idx_last = idx_less_than_max[-1]
    assert n_greater + n_less > 0 , "couldn't find a proper slice"
    # POST: have something to slice
    return MakeTimeSepForceFromSlice(obj,slice(idx_first,idx_last,1))    
    
def slice_by_time(obj,time_min=-np.inf,time_max=np.inf):
    """
    slices the given object by a minimum and maximum time
    
    Args:
        obj: see MakeTimeSepForceFromSlice
        time_<min/max>: the maximum and minimum time to use
        By default, we just slice everything.
    """
    return _slice_by_property(obj,property_func = lambda x: x.Time,
                              min_prop=time_min,max_prop=time_max)

def slice_by_separation(obj,*args,**kwargs):
    """
    slices the given object by separation bounds.
    
    Args:
        see slice_by_time, except switch time to separation
    Returns:
        see slice_by_time
    
    """
    return _slice_by_property(obj,*args,property_func = lambda x: x.Separation,
                              **kwargs)                                            
    
def MakeTimeSepForceFromSlice(Obj,Slice):
    """
    Given a TimeSepForceObject and a slice, gets a new object using just the 
    slices given
    Args:
        Obj:
        Slice:
    """
    ToRet = copy.deepcopy(Obj)
    ToRet = ToRet._slice(Slice)
    return ToRet


def UnitConvert(TimeSepForceObj,
                ConvertX=lambda x : x,
                ConvertY=lambda y : y):
    """
    Converts the 'X' and 'Y' using the specified units and properties 
    of the object passed in 

    Args:
        TimeSepForceObj : see ApproachRetractCurve
        ConvertX: method to convert the X values into whatever units we want
        ConvertY: metohod to convery the Y values into whatever units we want
    Returns: 
        deep *copy* of original object in the specified units
    """
    ObjCopy = copy.deepcopy(TimeSepForceObj)
    ObjCopy.Force = ConvertY(TimeSepForceObj.Force)
    ObjCopy.Separation = ConvertX(TimeSepForceObj.Separation)
    try:
        ObjCopy.set_z_sensor(ConvertX(TimeSepForceObj.Zsnsr))
    except AttributeError as E:
        # OK if there isnt a Zsnsr
        pass
    return ObjCopy


def CalculateOffset(Obj,Slice):
    """
    Calculates the force Offset for the given object and slice
    """
    return np.median(Obj.Force[Slice])

def ZeroForceAndSeparation(Obj,IsApproach,FractionForOffset=0.1):
    """
    Given an object and whether it is the approach or retract, zeros it
    out 

    Args:
        Obj: TimeSepForce Object
        IsApproach: True if this represents the approach portion of the 
        Curve.
    Returns:
        Tuple of <Zeroed Separation, Zeroed Force>
    """
    Separation = Obj.Separation
    Time = Obj.Time
    SeparationZeroed = Separation - min(Separation)
    N = SeparationZeroed.size
    NOffsetPoints = int(np.ceil(N))
    # approach's zero is at the beginning (far from the surface)
    # retract is at the end (ibid)
    if (IsApproach):
        SliceV = slice(0,NOffsetPoints,1)
    else:
        SliceV = slice(-NOffsetPoints,None,1)
    # get the actual offset assocaiated with this object
    Offset = CalculateOffset(Obj,SliceV)
    return SeparationZeroed.copy(),(Obj.Force - Offset).copy()

def zero_split_fec_approach_and_retract(Split,**kwargs):
    Split.approach,Split.retract = \
        PreProcessApproachAndRetract(Split.approach,Split.retract,**kwargs)
    
def PreProcessApproachAndRetract(Approach,Retract,
                                 NFilterPoints=100,
                                 ZeroForceFraction=0.2,
                                 ZeroSep=True,FlipY=True,
                                 zero_separation_at_zero_force=False):
    """
    Given and already-split approach and retract curve, pre=processes it.
    This *modifies the original array* (ie: in-place)

    Args:
        Approach,Retract: output of GetApproachRetract 
        NFilterPoints: number of points for finding the surface
        ZeroForceFraction: if not None, fraction of points near the retract end
        to filter to
        
        ZeroSep: if true, zeros the separation to its minima
        FlipY: if true, multiplies Y (force) by -1 before plotting
        zero_separation_at_zero_force: if true, zeros the separation by the 0 force point
    Returns:
        tuple of <Appr,Retr>, both pre-processed TimeSepFOrce objects for
        the appropriate reason
    """
    if (ZeroForceFraction is not None):
        # then we need to offset the force
        # XXX assume offset is the same for both
        idx_retr,ZeroForceRetr = \
            GetSurfaceIndexAndForce(Retract,
                                    Fraction=ZeroForceFraction,
                                    FilterPoints=NFilterPoints,
                                    ZeroAtStart=False)
        idx_appr,ZeroForceAppr = \
            GetSurfaceIndexAndForce(Approach,
                                    Fraction=ZeroForceFraction,
                                    FilterPoints=NFilterPoints,
                                    ZeroAtStart=True)
        # add, because the sign diffreent presummably hasnt been fixed
        # (See below)
        Approach.Force += ZeroForceRetr
        # Do the same for retract
        Retract.Force += ZeroForceRetr
    if (ZeroSep):
        if (zero_separation_at_zero_force):
            assert ZeroForceFraction is not None , \
                "To use zero force for zero separation, much get a zero force"
            MinSep = Retract.Separation[idx_retr]
            MinZ = Retract.ZSnsr[idx_retr]
        else:
            double_min = lambda x,y:min(np.min(x),np.min(y))
            # then we just go with the minimum
            MinSep = double_min(Approach.Separation,Retract.Separation)
            MinZ = double_min(Approach.ZSnsr,Retract.ZSnsr)
        Approach.Separation -= MinSep
        Retract.Separation -= MinSep
        Approach.offset_z_sensor(MinZ)
        Retract.offset_z_sensor(MinZ)
    if (FlipY):
        Approach.Force *= -1
        Retract.Force *= -1
    return Approach,Retract
    
def PreProcessFEC(TimeSepForceObject,**kwargs):
    """
    Returns the pre-processed (zeroed, flipped, etc) approach and retract
    
    Args:
        TimeSepForceObject: the object we are dealing with. copied, not changed
        **kwargs: passed directly to PreProcessApproachAndRetract
    Returns: 
        tuple of pre-processed approach and retract, see 
        PreProcessApproachAndRetract
    """
    Appr,Retr = GetApproachRetract(TimeSepForceObject)
    # now pre-process and overwrite them
    Appr,Retr = PreProcessApproachAndRetract(Appr,Retr,**kwargs)
    return Appr,Retr

def SplitAndProcess(TimeSepForceObj,ConversionOpts=dict(),
                    NFilterPoints=None,**kwargs):
    """
    Args:
        TimeSepForceObj: see PreProcessFEC
        ConversionOpts: passed to UnitConvert
        NFilterPoints: see PreProcessFEC
        **kwargs: passed to PreProcessFEC
    """
    # convert the x and y to sensible units
    if (NFilterPoints is None):
        NFilterPoints = \
            int(np.ceil(default_filter_pct * TimeSepForceObj.Force.size))
    ObjCopy = UnitConvert(TimeSepForceObj,**ConversionOpts)
    # pre-process (to, for example, flip the axes and zero everything out
    Appr,Retr = PreProcessFEC(ObjCopy,NFilterPoints=NFilterPoints,**kwargs)
    return Appr,Retr


def GetApproachRetract(o):
    """
    Get the approach and retraction curves of a TimeSepForceObject. Does *not*
    include the dwell portion
    
    Args:
        o: the TimeSepForce Object, assumed 'raw' (ie: invols peak at top)
    Returns:
        TUple of <Appr,Retract>, which are both TimeSepForce object of the
        Approach and Retract regions
    """
    ForceArray = o.Force
    TimeEndOfApproach = o.TriggerTime
    TimeStartOfRetract = TimeEndOfApproach + o.SurfaceDwellTime
    # figure out where the indices we want are
    Time = o.Time
    IdxEndOfApproach = np.argmin(np.abs(Time-TimeEndOfApproach))
    IdxStartOfRetract = np.argmin(np.abs(Time-TimeStartOfRetract))
    # note: force is 'upside down' by default, so high force (near surface
    # is actually high) is what we are looking for
    # get the different slices
    SliceAppr = slice(0,IdxEndOfApproach)
    SliceRetr = slice(IdxStartOfRetract,None)
    # Make a new object with the given force and separation
    # at approach and retract
    Appr = MakeTimeSepForceFromSlice(o,SliceAppr)
    Retr = MakeTimeSepForceFromSlice(o,SliceRetr)
    return Appr,Retr


def BreakUpIntoApproachAndRetract(mObjs):
    """
    Takes in a list of TimeSepForceObj, returns a list of approach and retract 
    objects, where index [i] in both lists refers to original curve i.

    Args:
        mObjs: Lsit of TimeSepForce Objects
    Returns:
        Tuple of Two lists: Approach,Retract, which are the TimeSepForce
        Objects of the approach and retract, respectively
    """
    Approach = []
    Retract = []
    for o in mObjs:
        Appr,Retr = GetApproachRetract(o)
        Approach.append(Appr)
        Retract.append(Retr)
    return Approach,Retract

def GetFilteredForce(Obj,NFilterPoints=None,FilterFunc=SavitskyFilter):
    """
    Given a TimeSepForce object, return a (filtered) copy of it

    Args:
        Obj: the TimeSepForce object we care about
        NFilterPoitns: fed to savitsky golay filter
        FilterFunc: takes in an array, and a kwarg 'nsmooth', returns a 
        filtered version of the array
    Returns:
        Filtered timesepforce object 
    """
    if (NFilterPoints is None):
        NFilterPoints = int(np.ceil(default_filter_pct*Obj.Force.size))
    ToRet = Obj._slice(slice(0,None,1))
    ToRet.Force = FilterFunc(Obj.Force,nSmooth=NFilterPoints)
    ToRet.Separation = FilterFunc(Obj.LowResData.sep,\
                                  nSmooth=NFilterPoints)
    ToRet.set_z_sensor(FilterFunc(Obj.ZSnsr,nSmooth=NFilterPoints))
    return ToRet

def GetSurfaceIndexAndForce(TimeSepForceObj,Fraction,FilterPoints,
                            ZeroAtStart=True,FlipSign=True):
    """
    Given a retraction curve, a fraction of end-points to take the median of,
    and a filtering for the entire curve, determines the surface location

    Args:
        TimeSepForceObj: single TimeSepForce Object, assumes 'raw', so that
        invols region is a negative force.
        Fraction: see GetAroundTouchoff
        FilterPoints: see GetAroundTouchoff
        ZeroAtStart: if true, uses the first 'fraction' points; otherwise 
        uses the last 'fraction' points for zeroing

        FlipSign: if true (default), assumes the data is 'raw', so that
        Dwell happens at positive force. Set to false if already fixed
    Returns: 
        Tuple of (Integer surface index,Zero Force). If we cant find surface,
        throws an error.
    """
    o = TimeSepForceObj
    ForceArray = o.Force
    SepArray = o.Separation
    if (FilterPoints > 1):
        ForceFilter = SavitskyFilter(o.Force,nSmooth=FilterPoints)
    else:
        ForceFilter = o.Force
    # Flip the sign of the force
    if (FlipSign):
        ForceSign = -1 * ForceFilter
    else:
        ForceSign = ForceFilter
    N = ForceSign.size
    NumMed = int(N*Fraction)
    if (ZeroAtStart):
        SliceMed = slice(0,NumMed,1)
    else:
        SliceMed = slice(-NumMed,None,1)
    MedRetr = np.median(ForceSign[SliceMed])
    ZeroForce = ForceSign - MedRetr
    # Get the first time the Retract forces is above zero
    FilteredRetract = SavitskyFilter(ZeroForce)
    ZeroIdx = np.where(FilteredRetract >= 0)[0]
    assert ZeroIdx.size > 0 , "Couldnt find zero index."
    ZeroIdx = ZeroIdx[0]
    return ZeroIdx,MedRetr

def GetFECPullingRegion(o,fraction=0.05,FilterPoints=20,FlipSign=True,
                        MetersAfterTouchoff=None,Correct=False,**kwargs):
    """
    Args:
        o: TimeSepForce Object to get the FEC pulling region of
    
        fraction: Amount to average to determine the zero point for the force. 
        FilterPoints: how many points to filter to find the zero, from the 
        *start* of the array forward
    
        FlipSign: If true, flips the sign. This is for using 'raw' data

        MetersFromTouchoff: gets this many meters away from the surface. If
        None, just returns all the data
        Correct: if true, corrects the data by flipping it and zeroing it out. 

        **kwargs: passed on to GetSurfaceIndexAndForce
    """
    ZeroIdx,MedRetr =  GetSurfaceIndexAndForce(o,fraction,FilterPoints,
                                               ZeroAtStart=False,
                                               FlipSign=FlipSign,**kwargs)
    if (MetersAfterTouchoff is not None):
        XToUse  = o.Separation
        N = XToUse.size
        # Get just that part of the Retract
        StartRetractX = XToUse[ZeroIdx]
        EndRetractX = StartRetractX + MetersAfterTouchoff
        Index = np.arange(0,N)
        # XXX build in approach/retract
        StopIdxArr = np.where( (XToUse > EndRetractX) &
                               (Index > ZeroIdx))[0][0]
    else:
        # just get eveything
        StopIdxArr = None
    NewSlice = slice(ZeroIdx,StopIdxArr)
    MyObj = MakeTimeSepForceFromSlice(o,NewSlice)
    if (FlipSign):
        MyObj.Force *= -1
    if (Correct):
        # sign correct and offset the force
        MyObj.Force -= MedRetr
        MyObj.Separation -= np.min(MyObj.Separation)
        MyObj.offset_z_sensor(np.min(MyObj.Zsnsr))
    return MyObj


def GetAroundTouchoff(Objects,**kwargs):
    """
    Gets the data 'MetersAfterTouchoff' meters after (in ZSnsr)the surface 
    touchoff,  based on taking the median of
    'fraction' points far away from the surface

    XXX: Generalize to approach and retract

    Args:
        Objects: list of TimeSepForce Objects
        **kwargs: passed directly to GetPullingRegion
    Returns:
        List of TimeSepForce objects, each offset in force and separation to 
        zero at the perceived start
    """
    ToRet = []
    for o in Objects:
        ToRet.append(GetFECPullingRegion(o,**kwargs))
    return ToRet

def GetFECPullingRegionAlreadyFlipped(Retract,NFilterPoints):
    """
    Adapter to GetFECPullingRegion, gets the retract after, assuming things
    have already been flipped
    """
    # now, get just the 'post touchoff' region. We *dont* want to flip
    # the sign when doing this
    Retract = GetFECPullingRegion(Retract,FlipSign=False,
                                  FilterPoints=NFilterPoints)
    return Retract

def FilteredGradient(Retract,NFilterPoints):
    """
    Get the filtered gradient of an object

    The force is filtered, the gradient is taken, the gradient is filtered

    Args:
       Retract: TimeSepForce Objectr
       NFilterPoints: see GetGradientOutliersAndNormalsAfterAdhesion,
       except this is an absolute number of points

    Returns:
       Array of same size as Retract.force which is the fitlered gradient.
    """
    RetractZeroSeparation = Retract.Separation
    RetractZeroForce = Retract.Force
    FilteredForce = GetFilteredForce(Retract,NFilterPoints)
    FilteredForceGradient =  SavitskyFilter(np.gradient(FilteredForce.Force),
                                            nSmooth=NFilterPoints)
    return FilteredForceGradient

def IsNormal(X):
    """
    being less than q75 is a good sign we are normal-ish
    """
    q75 = np.percentile(X, [75])
    return (X < q75)

def IsOutlier(X):
    """
    being 1.5 * iqr + q75 is a good sign we are an outlier 
    """
    q75, q25 = np.percentile(X, [75 ,25])
    iqr = q75-q25
    return X > (q75 + 1.5 * iqr)

def GetGradientOutliersAndNormalsAfterAdhesion(Retract,NFilterPoints,
                                               NoTriggerDistance):
    """
    Returns where we are past the notrigger distance, where we are outlying
    and where we are normal, according to a filtered first derivative

    Args:
        Retract: TimeSepForce Object to use, assumed zeroed
        NFilterPoints: [0,N], how many points to use for filtering
        NoTriggerDistance: how long (in meters) not to trigger
        after reaching the surface
    Returns:
        Tuple of <Indices after adhesion, Indices outlying q75+iqr,Indices
         within q75>
    """
    RetractZeroSeparation = Retract.Separation
    FilteredForceGradient = FilteredGradient(Retract,NFilterPoints)
    NoAdhesionMask = RetractZeroSeparation > NoTriggerDistance
    # get a mask where the gradient is positive
    # where are we an outlier in the gradient *and* the force?
    ForceOutliers = IsOutlier(Retract.Force) 
    Gradient = FilteredForceGradient
    ToRet = WlcCharacerizationMask(NoAdhesionMask,
                                   ForceOutliers,Gradient,
                                   NFilterPoints)
    return ToRet

def GetWLCPoints(WlcObj,Retract):
    """
    Gets the indices associated with (near) the start and end of the WLC
    
    Args:
       see GetWlcIdxObject
    Returns:
        tuple of <start idx 1, end idx 1, start idx 2, end idx 2> where
        the numbers refer to the WLC region
    """
    SeparationZeroed = Retract.Separation - min(Retract.Separation)
    # the second WLC should end at approximately the maximum force, *within*
    # the non-adhesion are
    NoAdhesionIdx = np.where(WlcObj.NoAdhesion)[0]
    IndexOfMaxInNonAdhesionMask = np.argmax(Retract.Force[NoAdhesionIdx])
    # get the actual index of the max into the real data.
    EndOfSecondWLC = NoAdhesionIdx[IndexOfMaxInNonAdhesionMask]
    Approximately170PercentOfL0 = SeparationZeroed[EndOfSecondWLC]
    # second WLC is about 1.7 * the contour length (which is where the
    # first one is. Here, we under-estimate; should still get a decent
    # estimate of the contour length
    ApproxL0Meters = Approximately170PercentOfL0/1.5
    ApproxBetweenIdx = np.argmin(np.abs(SeparationZeroed - ApproxL0Meters))
    N  =SeparationZeroed.size
    IdxArr = np.linspace(0,N,N)
    IdxForFirstWLC = np.where( (IdxArr < ApproxBetweenIdx) & \
                               (WlcObj.NoAdhesion))[0]
    MaxGradientIdxInMask = np.argmax(WlcObj.Gradient[IdxForFirstWLC])
    EndOfFirstWLC = IdxForFirstWLC[MaxGradientIdxInMask]
    # XXX fix these
    StartOfFirstWLC = EndOfFirstWLC
    StartOfSecondWLC = EndOfSecondWLC
    return StartOfFirstWLC,EndOfFirstWLC,StartOfSecondWLC,EndOfSecondWLC

def GetWlcIdxObject(WlcObj,Retract):
    """
    Returns the DNAWlcPoints associated with the object

    Args:
        Retract: the rertract object used
        WlcObj: See output of GetGradientOutliersAndNormalsAfterAdhesion
    Returns:
        DNAWlcPoints object associated
    """
    Points = GetWLCPoints(WlcObj,Retract)
    return DNAWlcPoints(*Points,TimeSepForceObj=Retract)
    
def GetRegionForWLCFit(RetractOriginal,NFilterPoints=None,
                       NoTriggerDistance=150e-9,**kwargs):
    """
    Given a (pre-processed, so properly 'flipped' and zeroed) WLC, gets the 
    approximate region for WLC fitting (ie: roughly the first curve up to 
    but not including the overstretching transition

    Args:
        RetractOriginal: pre-processed retract
        NoTriggerDistance: how long before we allow the first WLC to happen;
        points before this distance are ignored
        NFilterPoint : how many points to use for the savitsky filter
        **kwargs: passed to GetFECPullingRegionAlreadyFlipped
    Returns:
        TimeSepForce Object of the portion of the curve to fit 
    """
    if (NFilterPoints is None):
        NFilterPoints = int(np.ceil(0.1 *RetractOriginal.Force.size))
    # get the (properly zeroed) FEC, starting from zero force 
    Retract = GetFECPullingRegionAlreadyFlipped(RetractOriginal,
                                                NFilterPoints=NFilterPoints,
                                                **kwargs)
    # next, we want to find just the *first* WLC region
    RetractZeroSeparation = Retract.Separation
    AdhesionArgs = dict(Retract=Retract,
                        NoTriggerDistance=NoTriggerDistance,
                        NFilterPoints=NFilterPoints)
    # get the wlc characterization object
    WlcObj = GetGradientOutliersAndNormalsAfterAdhesion(**AdhesionArgs)
    # get the indices associated with the WLC
    Idx = GetWlcIdxObject(WlcObj,Retract)
    # interested in where the first WLC ends
    EndOfFirstWLC = Idx.FirstWLC.end
    # make a new object based on this slice
    FirstWlcSlice = slice(0,EndOfFirstWLC,1)
    NearSurface = MakeTimeSepForceFromSlice(Retract,FirstWlcSlice)
    return NearSurface

    
def _safe_meta_key_val(s):
    return str(unicode(s).replace(",",";").replace(":","/"))

def save_time_sep_force_as_csv(output_path,data):
    """
    saves the time,sep,force and mets infromation of data to outputpath

    Args:
        output_path: where to save as a csv
        data: TimeSepForce object to use
    Returns:
        nothing ,saves it out
    """
    meta = data.Meta.__dict__
    # get the string back as a dict
    key_values = []
    for k,v in meta.items():
        try:
            key_values.append( [_safe_meta_key_val(k),_safe_meta_key_val(v)] )
        except UnicodeDecodeError:
            pass
    str_meta = ",".join(["{:}:{:}".format(*k_v) for k_v in key_values])
    Events = [e for e in data.Events]
    header = str_meta
    # add the events to the second line if we want them
    if (data.has_events):
        header += "\nEventIndices,formatted as [[start1,end1],...]:"+str(Events)
    arr_tmp = np.array((data.Time,data.Separation,data.Force))
    np.savetxt(fname=output_path,X=arr_tmp.T,
               delimiter=",",header=header,comments="#")


def read_time_sep_force_from_csv(input_path,has_events=False):
    """
    reads a TimeSepForce objct stored in the given path, looks for events 
    if has_event=Ture

    Args:
        input_path: whre to look for the file. 
        data: TimeSepForce object to use
    Returns:
        TimeSepForce object, with events if it cold find them /was told to look
    """
    skiprows = 2 if has_events else 1
    arr = np.loadtxt(input_path,skiprows=skiprows,delimiter=",")
    with open(input_path) as f:
        # ignore the first  character (a #)
        first = f.readline()[1:-1]
        second = f.readline()[1:-1]
    # for meta: split by comma, then by ":" into key,value
    key_values = [k_v.split(":") for k_v in first.split(",")]
    # convert just as we would if we were reading in for the first time
    key_values = [ [k,ProcessSingleWave.SafeConvertValue(v)]
                   for k,v in key_values]
    meta = dict(key_values)
    time,separation,force = arr[:,0],arr[:,1],arr[:,2]
    # create TimeSepForce object
    to_return = TimeSepForceObj.TimeSepForceObj()
    to_return.LowResData = TimeSepForceObj.\
        data_obj_by_columns_and_dict(time,separation,force,meta)
    if (has_events):
        # syntax is Events: [ [event 1 start,event 1 end],[...],...]
        events = ast.literal_eval(second.split(":")[1])
        # set the events of the TimeSepForce Object
        to_return.set_events(events)
    return to_return


