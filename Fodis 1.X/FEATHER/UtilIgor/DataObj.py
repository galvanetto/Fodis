# force floating point division. Can still use integer with //
from __future__ import division
# other good compatibility recquirements for python3
from __future__ import absolute_import
from __future__ import print_function
from __future__ import unicode_literals

import numpy as np

from .ProcessSingleWave import WaveObj
from .CypherUtil import ConvertSepForceToZsnsrDeflV

class DataObj:
    def __init__(self,time,sep,force,metaInfo,filterIdx=None):
        """
        Initializes an object with the given time,sep, and force. Data may
        be offset from an 'absolute' index. Default offset it zero
        
        Args:
            time,sep,force: the time,separation, and force in SI units
            metaInfo: the meta information as a dictionary 
            filterIdx: indices associated with a slice, if any.
        """
        self.time = time
        self.sep = sep
        self.force = force
        self.meta = metaInfo
        self.filterIdx = filterIdx
        SepObj = WaveObj(DataY=self.sep,
                         Note=self.meta)
        ForceObj = WaveObj(DataY=self.force,Note=self.meta)
        self.Zsnsr,_ =  ConvertSepForceToZsnsrDeflV(SepObj,ForceObj)
        self.Zsnsr *= -1
    def GetTimeSepForce(self):
        """
        Returns time,sep,force as a tuple
        """
        return self.time,self.sep,self.force
    def DeltaT(self):
        return self.time[1]-self.time[0]
    def HasDataWindows(self):
        return self.filterIdx is not None
    def CreateDataSliced(self,idx):
        """
        Using the data here and provided indices, 

        Args:
            idx: list of <start,end> indices for which we want to slice the 
            data, [start,end) (does *not* include end)
        """
        copyWindowData = lambda x: [x[start:end][:] for start,end in idx]
        toRet = DataObj(copyWindowData(self.time),
                        copyWindowData(self.sep),
                        copyWindowData(self.force),
                        self.meta,
                        idx)
        return toRet
    def GetWindowIdx(self):
        """
        Gets the indices of the windows as a list of arrays. For example, if
        There are two windows, one like [1,2,3], and one like [4,5,6], returns
        [[1,2,3],[4,5,6]]. Corresponds exactly to indices of data, if self
        was constructed with CreateDataSliced
        """
        assert self.filterIdx is not None
        return [np.arange(start,end) for start,end in self.filterIdx]
