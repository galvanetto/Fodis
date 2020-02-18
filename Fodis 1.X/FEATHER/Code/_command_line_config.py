# force floating point division. Can still use integer with //
from __future__ import division
# other good compatibility recquirements for python3
from __future__ import absolute_import
from __future__ import print_function
from __future__ import unicode_literals
# This file is used for importing the common utilities classes.
import numpy as np
import matplotlib.pyplot as plt
import sys, re

from UtilForce.FEC import FEC_Util
from UtilGeneral import GenUtilities
from UtilIgor import PxpLoader,TimeSepForceObj
import h5py
from Code import Detector



class HeaderInfo(object):
    def __init__(self,spring_constant,trigger_time,dwell_time):
        self.spring_constant = spring_constant
        self.trigger_time = trigger_time
        self.dwell_time = dwell_time
        

def _parse_csv_header(in_file):
    """
    :param in_file: file to read in; first line should have part like
    SpringConstant:<Number>,TriggerTime:<Number>,DwellTime:<Number>

    Where <Number> is a valid float. E.g., SpringConstant:0.001,TriggerTime:

    :return:  HeaderInfo object
    """
    values = []
    keys=["SpringConstant","TriggerTime","DwellTime"]
    with open(in_file,'r') as f:
        header_l1 = f.readline()
        assert (header_l1 is not None) and (len(header_l1) > 0)
        for k in keys:
            pattern=r"""
                     [$,\s#]          # start, space, or comma
                     {:s}             # our literal string
                     \s*:\s*          # literal colon, optional spaces
                     ([^,\s]+)        # any non-commas or spaces (a #)
                     """.format(k)
            match = re.search(pattern,header_l1,re.VERBOSE)
            assert match is not None , "Line {:s} didn't have {:s}".format(header_l1,k)
            check = match.group(1)
            try:
                value = float(check)
            except ValueError:
                assert False, "Couldn't find {:s}. Value = {:s}".format(k,check)
            # POST: correctly found the float
            values.append(value)
    assert len(values) == 3 , "Couldn't parse everything."
    to_ret =  HeaderInfo(spring_constant=values[0],
                         trigger_time=values[1],
                         dwell_time=values[2])
    return to_ret
                      
                      


def read_matlab_file_into_fec(input_file):
    """
    Reads a matlab file into a force extension curve

    Args:
        input_file: '.mat' file, formatted like -v7.3
    Returns:
        tuple of time,separation,force
    """
    f = h5py.File(input_file,'r') 
    # the 'get' function should flatten all the arrays
    get = lambda x: f[x].value.flatten()
    # get the FEC data
    time = get('time')
    separation = get('separation')
    force = get('force')
    return time,separation,force
    

def make_fec(time,separation,force,spring_constant,trigger_time,dwell_time,
             name="",DwellSetting=1,Invols=1,**kwargs):
    """
    given time,sep, and force and 'meta' keywords, returns the fec that FEATHER
    can use

    Args:
        time,separation,force: the time, separation, and force associated
        with the fec

        **kwargs, others: see run_feather
    Returns:
         force extension curve object which FEATHER can use
    """
    meta_dict = dict(K=spring_constant,
                     Name=name,
                     Invols=1,
                     TriggerTime=trigger_time,
                     DwellTime=dwell_time,
                     DwellSetting=DwellSetting,
                     **kwargs)
    data = TimeSepForceObj.data_obj_by_columns_and_dict(time=time,
                                                        sep=separation,
                                                        force=force,
                                                        meta_dict=meta_dict)
    to_ret = TimeSepForceObj.TimeSepForceObj()
    to_ret.LowResData = data
    return to_ret

def get_force_extension_curve(in_file,**kwargs):
    """
    given an input file and meta information, returns the associated force 
    extension curve

    Args:
         input_file: file name, must have time, separation, and force
         **kwargs: see run_feather
    Returns:
         force extension curve object which FEATHER can use
    """
    if (not GenUtilities.isfile(in_file)):
        assert False, "File {:s} doesn't exist".format(in_file)
    # # POST: input file exists
    # go ahead and read it
    if (in_file.endswith(".pxp")):
        RawData = PxpLoader.LoadPxp(in_file)
        names = RawData.keys()
        # POST: file read sucessfully. should just have the one
        if (len(names) != 1):
            write_and_close("Need exactly one Force/Separation in pxp".\
                            format(in_file))
        # POST: have one. Go ahead and use FEATHER to predict the locations
        name = names[0]
        data_needed = ['time','sep','force']
        for d in data_needed:
            assert d in RawData[name] , "FEATHER .pxp needs {:s} wave".format(d)
        # POST: all the data we need exist
        time,separation,force = [RawData[name][d].DataY for d in data_needed]
    elif (in_file.endswith(".mat") or in_file.endswith(".m")):
        time,separation,force = read_matlab_file_into_fec(in_file)
    elif (in_file.endswith(".csv")):
        # assume just simple columns
        data = np.loadtxt(in_file,delimiter=',',skiprows=0)
        time,separation,force = data[:,0],data[:,1],data[:,2]
    else:
        assert False , "FEATHER given file name it doesn't understand"
    # POST: have time, separation, and force
    return make_fec(time,separation,force,**kwargs)

def predict_indices(fec,add_offsets=True,**kwargs):
    return Detector.predict(fec,add_offsets=add_offsets,**kwargs)
    
def run_feather(in_file,threshold,tau,spring_constant,dwell_time,
                trigger_time):
    """
    Runs feather on the given input file
    
    Args:
        in_file:  the input file to use
        threshold: see  Detector.predict
        tau: see  Detector.predict
        spring_constant: spring constant of the probe
        dwell_time: time from the end of the approach to the start of the dwell
        trigger_time: length of the approach
    Returns:
        see Detector.predict
    """
    assert tau > 0 , "FEATHER yau must be greater than 0"
    assert threshold > 0 , "FEATHER threshold must be greater than 0"
    assert spring_constant > 0 , \
        "FEATHER spring constant must be greater than 0"
    # POST: parameters in bounds. try to get the actual data
    example = get_force_extension_curve(in_file,
                                        spring_constant=spring_constant,
                                        dwell_time=dwell_time,
                                        trigger_time=trigger_time,
                                        name=in_file)
    # have the data, predict where the events are. 
    event_indices = predict_indices(example,threshold=threshold,
                                    tau_fraction=tau)
    return event_indices

