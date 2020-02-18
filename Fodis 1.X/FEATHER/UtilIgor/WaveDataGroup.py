# force floating point division. Can still use integer with //
from __future__ import division
# other good compatibility recquirements for python3
from __future__ import absolute_import
from __future__ import print_function
from __future__ import unicode_literals

from . import CypherUtil
import numpy as np
from . import ProcessSingleWave


# Class for storing associated waves from a known data file
class WaveDataGroup():
    def __init__(self,AssociatedWaves):
        """
        Groups a single set of waves with a known file
        Args: 
             AssociatedWaves : The waves associated together (eg: Zsnsr, DeflV)
             as a dictionary. <Ending>:<WaveObj> as <Key>:<Pairs>

        Returns:
             None
        """
        self.AssociatedWaves =AssociatedWaves
        self.SqlIds = None
        self.HighBandwidthWaves = None
    def CreateTimeSepForceWaveObjectFromData(self,data):
        """
        Creates Separation and Force Wave Object from whatever input we are 
        given. Uses cypher naming conventions to determine what the waves are.

        Unit tested by "UnitTests/PythonReader/CypherConverter"

        Args: 
             Data: a dictionary of <ending>:<ProcessSingleWave.WaveObj> 
             key-value pairs
        Returns:
             A WaveObject, with three columns, for time, separation, and force
             corresponding
        """
        Sep,Force = CypherUtil.GetSepForce(data)
        Note = self.DataNote(data)
        # implicitly use the first wave as the 'meta' wave, to get the timing,
        # etc.
        Waves= [ProcessSingleWave.WaveObj(DataY=Sep,Note=Note),
                ProcessSingleWave.WaveObj(DataY=Force,Note=Note)]
        return ProcessSingleWave.ConcatenateWaves(Waves)
    def GetNoteElement(self,data=None):
        """
        Given a dataset, gets the note element (assumed first)
        """
        if (data is None):
            data = self.AssociatedWaves
        eleKey = sorted(data.keys())[0]
        return data[eleKey]
    def DataNote(self,data):
        """
        Gets the data note for a specific data set (dictionary of waves)

        Unit tested by "UnitTests/PythonReader/CypherConverter"

        Args: 
             Data: a dictionary of <ending>:<ProcessSingleWave.WaveObj> 
             key-value pairs
        Returns:
             Note corresponding to that element
        """
        mEle = self.GetNoteElement(data)
        return mEle.Note
    def Note(self):
        """
        Returns the note object for this data, assumed to be any of the 
        low-res associated waves 
        """
        return self.DataNote(self.AssociatedWaves)
    @property
    def Note(self):
        return self.DataNote(self.AssociatedWaves)
    def CreateTimeSepForceWaveObject(self):
        """
        Creates Separation and Force Wave Object from whatever (low BW) 
        input we are given. Uses cypher naming conventions to determine what
        the waves are.

        Unit tested by "UnitTests/PythonReader/CypherConverter"

        Args: 
             None
        Returns:
             A WaveObject, with three columns, for time, separation, and force
        """
        # get the concatenated, low-bandwidth data.
        return self.CreateTimeSepForceWaveObjectFromData(self.AssociatedWaves)
    def SetSqlIds(self,idV):
        """
        Sets the Sql Ids for this object

        Args: 
             idV: return from PushToDatabase
        Returns:
             None
        """
        self.SqlIds = idV
    def __getitem__(self,index):
        """
        Gets the wave name with (String) ending index

        Args: 
             index: string ending
        Returns:
             WaveObj corresponding to the index
        """
        return self.AssociatedWaves[index]
    # below, we re-implement common methods so they act on the actual data.
    def keys(self):
        return self.AssociatedWaves.keys()
    def values(self):
        return self.AssociatedWaves.values()
    def __len__(self):
        return len(self.keys())
    """
    High-resolution functions below
    """
    def AssertHighBW(self):
        """
        Asserts that the wave has high-bandwidth data
        """
        assert self.HasHighBandwidth() , "No High Bandwidth data created"
    def HighBandwidthGetForce(self):
        """
        Given our high input waves, converts whatever Y we have into a 
        force and returns the associated WaveObject. Useful (for example)
        if we want to plot the high res force versus time (we don't yet have
        a high-resolution force

        Unit tested by "UnitTests/PythonReader/CypherConverter"

        Args: 
             None
        Returns:
             force *array* ( for WaveObj see HighBandwidthGetForceWaveObject)
        """
        self.AssertHighBW()
        # get the force for the wave
        force = CypherUtil.GetForce(self.HighBandwidthWaves)
        return force
    def HighBandwidthGetForceWaveObject(self):
        """
        See HighBandwidthGetForce, except this returns a wave object
        (insteaf of just an array)
        Args:
            None
        Returns:
             force *WaveObj* ( for array see HighBandwidthGetForce)
        """
        ForceNote = self.DataNote(self.HighBandwidthWaves)
        ForceData = self.HighBandwidthGetForce()
        return ProcessSingleWave.WaveObj(DataY=ForceData,Note=ForceNote)
    def HighBandwidthCreateTimeSepForceWaveObject(self):
        """
        Returns the high-bandwidth force and separation objects, assuming
        "HighBandwidthSetAssociatedWaves" has already been called

        Args: 
             None
        Returns:
             WaveObj corresponding to the index
        """
        self.AssertHighBW()
        # POST: have (something) to return.
        waves = self.HighBandwidthWaves
        return self.CreateTimeSepForceWaveObjectFromData(waves)
    def HasHighBandwidth(self):
        """
        Returns true if there is valid high-bandwidth data associated with the 
        model

        Unit tested by "UnitTests/PythonReader/CypherConverter"

        Args: 
             None
        Returns:
             WaveObj corresponding to the index
        """
        return self.HighBandwidthWaves is not None
    def HighBandwidthSetAssociatedWaves(self,AssocWaves):
        """
        Sets the (instance) high bandwidth data to "AssocWaves"

        Unit tested by "UnitTests/PythonReader/CypherConverter"

        Args: 
             AssocWaves: See init, AssociatedWaves argument.
        Returns:
             WaveObj corresponding to the index
        """
        self.HighBandwidthWaves = AssocWaves
    def EqualityTimeSepForce(self,other):
        """
        Tests if this wave group is equal to another, according to if the
        time,sep,force are the same (ie: 'data' equivalence).

        Only checks the force for the high bandwidth

        Unit tested by TestLargerDataManager/
        """
        # if make sure high/low bandwidth flags match
        if ((self.HasHighBandwidth() and not other.HasHighBandwidth()) or
            (not self.HasHighBandwidth() and other.HasHighBandwidth())):
            return False
        # check the low res is OK
        if (not self.CreateTimeSepForceWaveObject() == \
            other.CreateTimeSepForceWaveObject()):
            return False
        # check the high res is OK, if we have it
        if (self.HasHighBandwidth() and
            (not np.allclose(self.HighBandwidthGetForce(),
                             other.HighBandwidthGetForce()))):
            return False
