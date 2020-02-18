# force floating point division. Can still use integer with //
from __future__ import division
# This file is used for importing the common utilities classes.
import numpy as np
import matplotlib.pyplot as plt
import copy
from .WaveDataGroup import WaveDataGroup
from .DataObj import DataObj as DataObj

class Event():
    def __init__(self,start,end):
        self.start = start
        self.end = end
    def __str__(self):
        return "[{:d},{:d}]".format(self.start,self.end)
    def __repr__(self):
        return self.__str__()

class Bunch:
    """
    see 
http://stackoverflow.com/questions/2597278/python-load-variables-in-a-dict-into-namespace

    Used to keep track of the meta information
    """
    def __init__(self, adict):
        self.__dict__.update(adict)
    def __getitem__(self,key):
        return self.__dict__[key]

def DataObjByConcat(ConcatData,*args,**kwargs):
    """
    Initializes an data object from a concatenated wave object (e.g.,
    high resolution time,sep, and force)
    
    Args:
        ConcatData: concatenated WaveObj
    """
    Meta = Bunch(ConcatData.Note)
    time,sep,force = ConcatData.GetTimeSepForceAsCols()
    return DataObj(time,sep,force,Meta,*args,**kwargs)
    
def data_obj_by_columns_and_dict(time,sep,force,meta_dict,*args,**kwargs):
    """
    Initializes an data object from a concatenated wave object (e.g., 
    high resolution time,sep, and force)
    
    Args:
        time,sep,force: arrays of size N corresponding to FEC measurements
        meta_dict: the meta information as a dictionary
        *args,**kwargs: passed to DataObjByConcat
    Returns:
        DataObj instance
    """
    Meta = Bunch(meta_dict)
    return DataObj(time,sep,force,Meta,*args,**kwargs)

def _meta_dict(SpringConstant,Velocity,Invols=1,DwellSetting=0,DwellTime=0,
               Name=""):
    """
    :param SpringConstant: of a trace
    :param Velocity: ...
    :param Invols: ...
    :param DwellSetting: ...
    :param DwellTime: ...
    :return: meta dictionary, for input to  data_obj_by_columns_and_dict
    """
    return dict(SpringConstant=SpringConstant,
                Velocity=Velocity,
                Invols=Invols,
                DwellSetting=DwellSetting,
                DwellTime=DwellTime,
                Name=Name)

def _cols_to_TimeSepForceObj(**kw):
    """
    :param kw: keywords to use for  data_obj_by_columns_and_dict
    :return:
    """
    data_obj = data_obj_by_columns_and_dict(**kw)
    to_ret = TimeSepForceObj()
    to_ret.LowResData = data_obj
    return to_ret

class TimeSepForceObj(object):
    def __init__(self,mWaves=None):
        """
        Given a WaveDataGrop, gets an easier-to-use object, with low and 
        (possible) high resolution time sep and force
        
        Args:
            mWaves: WaveDataGroup. Should be able to get time,sep,and force 
            from it
        """
        self.has_events = False
        self.Events = []
        if (mWaves is not None):
            ConcatWave = mWaves.CreateTimeSepForceWaveObject()
            self.LowResData = DataObjByConcat(ConcatWave)
            # by default, assume we *dont* have high res data
            self.HiResData = None
            if (mWaves.HasHighBandwidth()):
                hiResConcat = mWaves.HighBandwidthCreateTimeSepForceWaveObject()
                self.HiResData = DataObjByConcat(hiResConcat)
    def _slice(self,s):
        to_ret = copy.deepcopy(self)
        sanit = lambda x: x[s].copy()
        force = sanit(self.LowResData.force)        
        time = sanit(self.LowResData.time)
        sep = sanit(self.LowResData.sep)
        meta = self.LowResData.meta.__dict__
        # we have to manually add everything, otherwise the properties are 
        # messed up...
        to_ret.LowResData = \
            data_obj_by_columns_and_dict(time,sep,force,meta)
        assert to_ret.Force.size == force.size , "Slice didn't work."
        # manually fix the Zsnsr
        to_ret.LowResData.Zsnsr = sanit(self.LowResData.Zsnsr)
        to_ret.Events = self.Events
        return to_ret
    def HasSurfaceDwell(self):
        """
        Returns true if there is a surface dwell
        """
        # by default, stored as a float; 0 means no dwell, 1 means surface,
        # three means both, etc.
        DwellInt = int(self.Meta.DwellSetting) 
        return (DwellInt != 0) and (DwellInt % 2 == 1)
    def set_events(self,list_of_events):
        """
        sets the events of this object
    
        Args:
            list_of_events: list of Event objects.
        Returns: nothing
        """
        self.has_events = True
        self.Events = list_of_events
    def get_meta_as_string(self,):
        return str(self.Meta.__dict__)
    @property
    def TriggerTime(self):
        return self.Meta.TriggerTime
    @property
    def SurfaceDwellTime(self):
        """
        Returns the dwell time (0 if none) as a float
        """
        if (self.HasSurfaceDwell()):
            return self.Meta.DwellTime
        else:
            return 0
    def set_dwell_time(self,t):
        self.Meta.DwellTime = t
    def offset_z_sensor(self,offset=None):
        if (offset is None):
            offset = np.min(self.Zsnsr)
        self.set_z_sensor(self.Zsnsr-offset)
    def set_z_sensor(self,set_to):
        self.LowResData.Zsnsr = set_to
    def offset(self,separation,zsnsr,force):
        self.LowResData.force -= force
        self.LowResData.sep-= separation
        self.offset_z_sensor(zsnsr)
    @property
    def Zsnsr(self):
        return self.LowResData.Zsnsr
    @property
    def ThermalFrequency(self):
        return float(self.Meta.ThermalCenter)
    @property
    def Frequency(self):
        ToRet = float(self.Meta.NumPtsPerSec)
        return ToRet
    @property
    def Meta(self):
        """
        Returns the low-resolution meta
        """
        return self.LowResData.meta
    @property
    def Time(self):
        """
        return the low-resolution time
        """
        return self.LowResData.time
    @property
    def Separation(self):
        """
        Returns the (low resolution) separation
        """
        return self.LowResData.sep
    @property
    def Force(self):
        """
        Returns the (low resolution) force
        """
        return self.LowResData.force
    @property
    def ZSnsr(self):
        """
        Returns the (low resolution) zsnsr
        """
        return self.LowResData.Zsnsr
    @Force.setter 
    def Force(self,f):
        self.LowResData.force = f
    @Separation.setter 
    def Separation(self,s):
        self.LowResData.sep = s
    @ZSnsr.setter 
    def ZSnsr(self,z):
        self.LowResData.Zsnsr = z
    @Time.setter 
    def Time(self,t):
        self.LowResData.time = t
    @property 
    def K(self):
        return self.Meta.__dict__['K']
    @property
    def SpringConstant(self):
        return self.LowResData.meta.SpringConstant
    @property
    def Velocity(self):
        return self.LowResData.meta.Velocity
    @Velocity.setter
    def Velocity(self,v):
        self.Meta.Velocity = v
    @property
    def ApproachVelocity(self):
        return self.Meta.ApproachVelocity
    def CreatedFiltered(self,idxLowRes,idxHighRes):
        """
        Given indices for low and high resolution data, creates a new,
        Filtered data object (of type TimeSepForceObj)
        
        Args:
            idxLowRes: low resolution indices of interest. Should be a list;
            each element is a distinct 'window' we wan to look at

            idxHighRes: high resolution indices of interest. see idxLowRes
        """
        assert self.HiResData is not None
        # create an (empty) data object
        toRet = TimeSepForceObj()
        toRet.LowResData= self.LowResData.CreateDataSliced(idxLowRes)
        toRet.HiResData = self.HiResData.CreateDataSliced(idxHighRes)
        return toRet
    
