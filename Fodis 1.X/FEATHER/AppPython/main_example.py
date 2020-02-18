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
sys.path.append("../")

from Code import _command_line_config,Detector


def _analyze_file(in_file):
    data = np.loadtxt(in_file,delimiter=',',skiprows=0)
    header_info = _command_line_config._parse_csv_header(in_file)
    time,sep,force = data[:,0],data[:,1],data[:,2]
    threshold = 1e-3
    tau = 2e-2
    meta_dict = dict(threshold=threshold,
                     tau=tau,
                     spring_constant=header_info.spring_constant,
                     trigger_time = header_info.trigger_time,
                     dwell_time = header_info.dwell_time)
    event_indices_1 = _command_line_config.run_feather(in_file=in_file,
                                                       **meta_dict)
    # # (2) directly, using python arrays and a constructed fec object. This is
    # #    likely to be much faster, since there is no extra file IO.
    fec = _command_line_config.make_fec(time=time,separation=sep,force=force,
                                        **meta_dict)
    event_indices_2 = _command_line_config.predict_indices(fec,
                                                           tau_fraction=tau,
                                                           threshold=threshold)
    # make sure the two methods are consistent
    assert np.allclose(event_indices_1,event_indices_2) , \
        "Programming error; FEATHER methods should be identical"
    # POST: they are consistent. go ahead and plot force vs time, add lines
    # where an event is predicted
    print("Found events at indices: {}".format(event_indices_1))
    force_pN = force*-1e12
    force_pN_zero = force_pN - force_pN[force_pN.size//10]
    plt.plot(time,force_pN_zero)
    for i in event_indices_1:
        plt.axvline(time[i],color='r',linestyle='--')
    plt.xlabel("Time (s)")
    plt.ylabel("Force (pN)")
    plt.show()

def run():
    """
    <Description>

    Args:
        param1: This is the first param.
    
    Returns:
        This is a description of what is returned.
    """
    # there are a couple of ways to call FEATHER in python. 
    # # (1) through an intermediate '.csv' file
    for i in range(19):
        in_file = '../Data/example_{:d}.csv'.format(i)
        _analyze_file(in_file)
    

if __name__ == "__main__":
    run()
