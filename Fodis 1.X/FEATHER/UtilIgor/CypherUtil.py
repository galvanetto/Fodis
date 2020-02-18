# force floating point division. Can still use integer with //
from __future__ import division
# This file is used for importing the common utilities classes.
import numpy as np
import matplotlib.pyplot as plt
# need to add the utilities class. Want 'home' to be platform independent
from os.path import expanduser

# How to get the Asylum notes values
## Constants related to approach and positioning
NOTE_APPROACH_VEL = "Velocity"
NOTE_RETRACT_VEL = "RetractVelocity"
NOTE_X_LVDT = "XLVDTSens"
NOTE_Y_LVDT = "YLVDTSens"
NOTE_Z_LVDT = "ZLVDTSens"
NOTE_SPOT_POS = "ForceSpotNumber"
# Dwell setting: 0 if we aren't using either dwells, 
NOTE_DWELL_SETTING = "DwellSetting"
NOTE_DWELL_SURFACE = "DwellTime"
NOTE_DWELL_ABOVE = "DwellTime1"
NOTE_FORCE_DIST = "ForceDist"
NOTE_START_DIST  = "StartDist"
## Constants related to calibration
NOTE_INVOLS = "InvOLS"
NOTE_SPRING_CONSTANT = "SpringConstant"
NOTE_THERMAL_Q  = "ThermalQ"
NOTE_THERMAL_FREQUENCE = "ThermalFrequency"
##Constants of timestamps
NOTE_TIMESTAMP_START = "StartTempSeconds"
NOTE_TIMESTAMP_END = "Seconds"
##/Constantes related to triggering
NOTE_TRIGGER_CHANNEL = "TriggerChannel"
NOTE_TRIGGER_POINT = "TriggerPoint"
## Constants related to sampling
NOTE_SAMPLE_HERTZ = "NumPtsPerSec"
NOTE_SAMPLE_BW = "ForceFilterBW"
# Other constants
NOTE_XOFFSET = "XLVDTOffset"
NOTE_YOFFSET = "YLVDTOffset"
NOTE_TEMPERATURE = "ThermalTemperature"
# Functions related to  the <name>:<value> part
NOTE_KEY_SEP_STR = ":"
NOTE_LIST_SEP_STR = "\r"

# Asylum Experiment Regex
# Matches ForceCurves:Subfolders:X<6 digits>, with *either* a colon or end of string after
DEFAULT_REGEX_ASYLUM_EXP = ":(X\d{6})[$:]"
# Any file scheme, followed by a non-digit (guarenteed by Asylum, followed by at least 1 digit
DEFAULT_STEM_REGEX = ".+:.+\d+"
# Path from root to start of force cyrves
DEFAULT_ASYLUM_PATH = "ForceCurves:SubFolders:"
# When operating on a file name, used to get the (final) file ID
# get all of the last digits
DEFAULT_ASYLUM_FILENUM_REGEX = "(\d+)$"
 
 # Function to convert between X and Y types
# Types available for conversion for Y (E.g. photodiode voltage, force)
MOD_Y_TYPE_FORCE_NEWTONS = 1
MOD_Y_TYPE_DEFL_METERS = 2
MOD_Y_TYPE_DEFL_VOLTS = 3
# The corresponding units
MOD_Y_TYPE_FORCE_NEWTONS_UNITS = "N"
MOD_Y_TYPE_DEFL_METERS_UNITS = "m"
MOD_Y_TYPE_DEFL_VOLTS_UNITS = "V"
# Types available for convertsion for X  (E.G Zsnr, Separation)
MOD_X_TYPE_SEP = -1
MOD_X_TYPE_Z_SENSOR  = -2
# The corresponding units
MOD_X_TYPE_SEP_UNITS = "m"
MOD_X_TYPE_Z_SENSOR_UNITS = "m"
# Endings for types for Y file types (e.g. force, deflections)
FILE_END_Y_DEFL_VOLTS = "DeflV"
FILE_END_Y_DEFL_METERS = "Defl"
FILE_END_Y_FORCE = "Force"
# Endings for types for X file types (e.g. separation, z sensor)
FILE_END_X_SEP = "Sep"
FILE_END_X_ZSENSOR = "Zsnsr"


# Get the constant to change inwave to deflMeters
def ConstToDeflMeters(InType,SpringConstant,Invols):
    mDict = {
        # To convert from Volts to meters, multiply by invols
        MOD_Y_TYPE_DEFL_VOLTS :Invols,
        # To convert from meters to meters, multiply by 1
        MOD_Y_TYPE_DEFL_METERS : 1,
        # To convert from newtons to meters, multiply by 1/k 
        MOD_Y_TYPE_FORCE_NEWTONS : 1/SpringConstant,
        }
    if InType not in mDict:
        ValueError("Bad Type {:s}".format(InType))
        # POST: have the conversion
    return mDict[InType]

# A function to convert a Y data type to another Y data type
# Note: If Present, DeflMeters is set with the deflection in meters
# This is useful, since any X conversion needs the deflection in meters
def ConvertY(WaveObj,InType,OutType):
        # Switched based on the input type,  to get the conversion
        # We will always convert to DeflMeters, then back to Volts
        # Note: invols and springconstant are in V/nm and N/m respectively
        InWave = WaveObj.DataY
        SpringConstant= WaveObj.SpringConstant()
        Invols = WaveObj.Invols()
        # POST: we have a real conversion to make
        ToDeflMeters = ConstToDeflMeters(InType,
                                         SpringConstant=SpringConstant,
                                         Invols=Invols)
        # POST: we know how to convert the y type into deflection meters
        # Detrermine how to convert the y type into the desired output type.
        outDict = {\
            # To convert from meters to volts, multiply by 1/invols
            MOD_Y_TYPE_DEFL_VOLTS: 1/Invols,
            # To convert from meters to meters, multiply by 1
            MOD_Y_TYPE_DEFL_METERS:1,
            # To convert from meters to newtons, multiply by k
            MOD_Y_TYPE_FORCE_NEWTONS:SpringConstant
            }
        if (OutType not in outDict):
            KeyError("Couldn't find out type {:s}".format(OutType))
        fromDeflMeters = outDict[OutType]
        DeflMeters = ToDeflMeters * InWave[:]
        if (InType == OutType):
            Converted = InWave[:]
        else:
            Converted = (ToDeflMeters * fromDeflMeters) * InWave 
        return Converted,DeflMeters


# Function to convert between X values. Note that it *requires* 
# having "DeflMeters", which is the cantilever deflection (this can be obtained 
# From the ConverY function, above). This could probably be easily accomplished
# with a much smaller function, but the machinery is here for more complicated 
# conversions, if they become necessary.
def ConvertX(WaveObj,InType,OutType,DeflMeters):
        # Determine how to convert to ZSnsr; a factor infront of Deflection
        # In other words, we will calculate: Out = In + (toZSnr+ fromZSnr)*Defl
        # Zsnsr = Defl-Sep by Cypher Convention
        # XXX check output type  parity...
        inWave = WaveObj.DataY # note: "DataY" is actually the zsnsr/DeflM
        # first, do we actually need to do anything?
        if (InType == OutType):
            Converted = inWave[:]
        elif (InType == MOD_X_TYPE_SEP):
            # Converting to Zsnsr
            Converted = DeflMeters[:]-inWave[:]
        elif (InType == MOD_X_TYPE_Z_SENSOR):
            # Converting to Sep
            Converted = DeflMeters[:]-inWave[:]
        else:
            raise IOError("Don't recognize X Input Type")
        return Converted

def ConvertGenY(InY,InTypeY,outTypeY):
    outY,DeflM = ConvertY(InY,InTypeY,outTypeY)
    return outY,DeflM
    
def ConvertGen(InX,InY,InTypeX,InTypeY,outTypeX,outTypeY):
    outY,DeflM = ConvertGenY(InY,InTypeY,outTypeY) 
    # Convert to OutX
    outX = ConvertX(InX,InTypeX,outTypeX,DeflM)
    return outX,outY

def ConvertSepForceToZsnsrDeflV(Sep,RawForce):
    """
    Given a separation and raw force, converts to Zsnsr and DeflV

    Unit tested in CypherConverter
        
    Args:
         Sep: Waveobject with separation data
         RawForce: WaveObject Force to conver
    Returns:
         tuple of <Zsnsr, DeflV> WaveObjects
    """
    return ConvertGen(Sep,RawForce,MOD_X_TYPE_SEP,MOD_Y_TYPE_FORCE_NEWTONS,
                      MOD_X_TYPE_Z_SENSOR,MOD_Y_TYPE_DEFL_VOLTS)


def ConvertZsnsrDeflVToSepForce(Zsnsr,DeflV):
    """
    Given Zsnsr and DeflV, converts to separation and raw force

    Unit tested in CypherConverter
        
    Args:
         Zsnsr: Waveobject with Zsnsr data
         DeflV: WaveObject Deflection Volts to convert
    Returns:
         tuple of <Sep, Force> WaveObjects
    """
    return ConvertGen(Zsnsr,DeflV,MOD_X_TYPE_Z_SENSOR,MOD_Y_TYPE_DEFL_VOLTS,
                      MOD_X_TYPE_SEP,MOD_Y_TYPE_FORCE_NEWTONS)

def GetYNameAndType(names):
    """
    Given a list of names, tries to find a y name amoung them.
    If it cant find a y name, then it raises an error
        
    Args:
         names list of wave names
    Returns:
         tuple of yType,yName. yname is sanitized by 'sanit'
    """
    names = Sanit(names)
    if (SanitSingle(FILE_END_Y_FORCE) in names):
        yType = MOD_Y_TYPE_FORCE_NEWTONS
        yName = FILE_END_Y_FORCE
    elif (SanitSingle(FILE_END_Y_DEFL_VOLTS) in names):
        yType = MOD_Y_TYPE_DEFL_VOLTS
        yName = FILE_END_Y_DEFL_VOLTS
    elif (SanitSingle(FILE_END_Y_DEFL_METERS) in names):
        yType = MOD_Y_TYPE_DEFL_METERS
        yName = FILE_END_Y_DEFL_METERS
    else:
        raise KeyError("Don't recognize a y value amoung {}".\
                       format(names))
    return yType,SanitSingle(yName)

def GetXNameAndType(names):
    """
    Given a list of names, tries to find a x name amoung them.
    If it cant find a x name, then it raises an error
        
    Args:
         names list of wave names, assumed lowercase
    Returns:
         tuple of xType,xName. xname is sanitized by 'sanit'
    """
    lowerNames = Sanit(names)
    if (SanitSingle(FILE_END_X_SEP) in lowerNames):
        xType = MOD_X_TYPE_SEP
        xName = FILE_END_X_SEP
    elif (SanitSingle(FILE_END_X_ZSENSOR) in lowerNames):
        xType = MOD_X_TYPE_Z_SENSOR
        # no need to convert
        xName = FILE_END_X_ZSENSOR
    else:
        raise KeyError("Don't recognize an x value amoung {:s}".\
                       format(lowerNames))
    return xType,SanitSingle(xName)

def GenGetForce(WaveDict):
    """
    Given a set of associated waves, Force to Plot
        
    Args:
         dictionary of <key>:WaveObj pairs associated with a set of data
    Returns:
         force to plot
    """
    lowerNames = map(sanit,WaveDict.keys())
    yType,yName = GetYNameAndType(WaveDict.keys())

def SanitSingle(x):
    """
    Given a single name, sanititzes it
    Args:
        x: name to sanitiz
    Returns
        sanitized name
    """
    return str(x.lower())
    
def Sanit(x):
    """
    Given a list, sanitizes the names
        
    Args:
         list to sanitize
    Returns:
         sanitized list
    """
    FirstPass =  map(SanitSingle,x)
    # eliminate anything after the first underscore...
    # if there is no underscore, this doesnt do anything.
    # useful if someone has like "Image0001force_towd" to get just "force"
    return [n.split("_")[0] for n in FirstPass]
    
def GetForce(WaveDict):
    """
    Given a set of associated waves, gets just the force. 

    Unit tested in CypherConverter
        
    Args:
         dictionary of <key>:WaveObj pairs associated with a set of data
    Returns:
         Y: force
    """
    mNames = WaveDict.keys()
    mSanitKeys = Sanit(mNames)
    # get the input type
    yType,yName = GetYNameAndType(mSanitKeys)
    mVals = [WaveDict[k] for k in mNames]
    InY = mVals[mSanitKeys.index(yName)]
    # get the force
    force,_ = ConvertGenY(InY,yType,MOD_Y_TYPE_FORCE_NEWTONS)
    return force

def GetSepForce(WaveDict):
    """
    Given a set of associated waves, get the Sep and Force to Plot

    Unit tested in CypherConverter (implicitly, since 
    CreateTimeSepForceWaveObject is unit tested)
        
    Args:
         dictionary of <key>:WaveObj pairs associated with a set of data
    Returns:
         X,Y: Data to plot on x and y axis
    """
    names = WaveDict.keys()
    lowerNames = Sanit(names)
    # get the y name, if need be...
    yType,yName = GetYNameAndType(lowerNames)
    # POST: have y, need x
    xType,xName = GetXNameAndType(lowerNames)
    # get the X and y data to use
    mWaves = [WaveDict[k] for k in names]
    InX = mWaves[lowerNames.index(xName)]
    InY = mWaves[lowerNames.index(yName)]
    X,Y = ConvertGen(InX,InY,xType,yType,MOD_X_TYPE_SEP,
                     MOD_Y_TYPE_FORCE_NEWTONS)
    return X,Y
    
