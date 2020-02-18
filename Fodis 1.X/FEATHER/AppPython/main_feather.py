# force floating point division. Can still use integer with //
from __future__ import division
# This file is used for importing the common utilities classes.
import numpy as np
import sys
import matplotlib.pyplot as plt
import os, sys,traceback
# change to this scripts path
path = os.path.abspath(os.path.dirname(__file__))
os.chdir(path)
sys.path.append('../')
from Code import _command_line_config

import argparse

def parse_and_run():
    """
    uses argparse to get the arguments _command_line_config.run_feather needs

    Args:
        none, but assumes called from command line properly
    Returns:
        event_indices, as predicted by FEATHER
    """
    description = 'Predict event locations in a data file'
    parser = argparse.ArgumentParser(description=description)
    common = dict(required=True)
    # # feathers options
    parser.add_argument('-tau', metavar='tau', 
                        type=float,help='tau fraction of curve (0,1)',
                        required=False,default=1e-2)
    parser.add_argument('-threshold', metavar='threshold', 
                        type=float,help='probability threshold (0,1)',
                        **common)
    # # 'meta' variables
    parser.add_argument('-spring_constant', metavar='spring_constant', 
                        type=float,help='spring constant of the probe',
                        **common)
    parser.add_argument('-trigger_time', metavar='trigger_time', 
                        type=float,help='time at which approach ends',
                        **common)
    parser.add_argument('-dwell_time', metavar='dwell_time', 
                        type=float,
                        help='time between end of approach and retract start',
                        **common)
    # path to the file
    parser.add_argument('-file_input',metavar="file_input",type=str,
                        help="path to the force-extension curve file",
                        **common)
    parser.add_argument('-file_output',metavar="file_output",type=str,
                        help="path to output the associated data",**common)
    # parse all the inputs
    args = parser.parse_args()
    out_file = os.path.normpath(args.file_output)
    in_file = os.path.normpath(args.file_input)
    # get the indices
    feather_dict = dict(in_file=in_file,
                        threshold=args.threshold,
                        tau=args.tau,
                        spring_constant=args.spring_constant,
                        dwell_time=args.dwell_time,
                        trigger_time=args.trigger_time)
    # call feather
    event_indices = _command_line_config.run_feather(**feather_dict)
    # done with the log file...
    np.savetxt(fname=out_file,delimiter=",",newline="\n",fmt="%d",
               header="(C) PRH 2017\nEvent Indices",
               X=event_indices)
    return event_indices

def run():
    try:
        parse_and_run()
    except:
        exc_type, exc_value, exc_traceback = sys.exc_info()
        lines = traceback.format_exception(exc_type, exc_value, 
                                           exc_traceback)
        # Log it or whatever here
        str_out =''.join('!! ' + line for line in lines)
        print(str_out)
        exit(-1)
        
if __name__ == "__main__":
    run()
