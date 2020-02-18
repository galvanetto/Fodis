# force floating point division. Can still use integer with //
from __future__ import division
# other good compatibility recquirements for python3
from __future__ import absolute_import
from __future__ import print_function
from __future__ import unicode_literals
# This file is used for importing the common utilities classes.
import numpy as np
import matplotlib.pyplot as plt
import sys

sys.path.append("../../../")

from UtilIgor import PxpLoader
from UtilIgor import CypherUtil

def _check(x,y,**kw):
    np.testing.assert_allclose(x,y.DataY,**kw)

def get_output(to_call,input_x,args):
    output = to_call(input_x,*args)
    return output


def check_single_y(to_call,input_x,args,expected_output,**testing_kw):
    output = get_output(to_call,input_x,args)
    # y converters return (what we are about, deflm)
    output = output[0]
    _check(output,expected_output, **testing_kw)
    output = get_output(to_call,input_x,args)


def check_single_x(to_call,input_x,args,expected_output,**testing_kw):
    output = get_output(to_call,input_x,args)
    _check(output,expected_output, **testing_kw)



def run():
    """
    Tests the following conversions  (-> Denotes single direction, <-> both)

    (1) check that and Force -> ZSnsr, DeflV
    (2) check that ZSnsr and DeflV  -> Separation and force
    (3) check that sep <-> Zsnsr works
    (4) check that defl <-> Force works
    (5) check that deflV <-> Force works
    (6) check that deflV <-> defl works
    (7) check x <-> x, where x is any of the above.
    """
    data_base = "../Data/conversion/Image0341"
    exts = ["Defl","DeflV","Force","Sep","Time","ZSnsr"]
    files = [data_base + e + ".ibw" for e in exts]
    all_types = [PxpLoader.read_ibw_as_wave(f) for f in files]
    defl, deflv, force, sep, time, zsnsr = all_types
    common_assert = dict(atol=1e-15,rtol=1e-6)
    # make sure the zsnsr and deflV can be had correctly
    zsnsr_check,deflv_check =\
        CypherUtil.ConvertSepForceToZsnsrDeflV(Sep=sep,RawForce=force)
    np.testing.assert_allclose(zsnsr_check,zsnsr.DataY,**common_assert)
    np.testing.assert_allclose(deflv_check,deflv.DataY,**common_assert)
    # POST: (1) Can convert Separation and Force for ZSnsr, DeflV
    # make sure the reverse transformation works
    sep_check,force_check =\
        CypherUtil.ConvertZsnsrDeflVToSepForce(DeflV=deflv,Zsnsr=zsnsr)
    np.testing.assert_allclose(force_check,force.DataY,**common_assert)
    np.testing.assert_allclose(sep_check,sep.DataY,**common_assert)
    # POST: (2) Can convert Separation and force to ZSnsr and DeflV 
    # make sure the individual transformations work
    x,y = CypherUtil.ConvertX,CypherUtil.ConvertY
    t_sep = CypherUtil.MOD_X_TYPE_SEP
    t_z = CypherUtil.MOD_X_TYPE_Z_SENSOR
    t_defl = CypherUtil.MOD_Y_TYPE_DEFL_METERS
    t_deflv = CypherUtil.MOD_Y_TYPE_DEFL_VOLTS
    t_force = CypherUtil.MOD_Y_TYPE_FORCE_NEWTONS
    single_conv_dict = [
        # (3) check that sep <-> Zsnsr works
        [x,[sep,t_sep,t_z,zsnsr],defl.DataY,False],
        # (4) check that defl <-> Force works
        [y,[defl,t_defl,t_force,force],None,True],
        # (5) check that deflV <-> Force works
        [y,[deflv,t_deflv,t_force,force],None,True],
        # (6) check that deflV <-> defl works
        [y,[deflv,t_deflv,t_defl,defl],None,True],
        ]
    # (7) note we also check all identities
    for i,(f,args,extra,check_y) in enumerate(single_conv_dict):
        # get the first and last thing in the array;
        # these are the input and (Expected) output. 
        fwd = args[0]
        rev = args[-1]
        fwd_args = args[1:-1]
        rev_args = fwd_args[::-1]
        if (extra is not None):
            fwd_args.append(extra)
            rev_args.append(extra)
        check_f = check_single_y if check_y else check_single_x
        # test the 'forward' direction
        check_f(f,fwd,fwd_args,rev,**common_assert)
        # test the 'reverse' direction
        check_f(f,rev,rev_args,fwd,**common_assert)
        # check both identities, forward and reverse
        args_identity_f = [fwd_args[1],fwd_args[1]]
        args_identity_r = [rev_args[1],rev_args[1]]
        if (extra is not None):
            args_identity_f.append(extra)
            args_identity_r.append(extra)
        check_f(f,fwd,args_identity_f,fwd,**common_assert)
        check_f(f,rev,args_identity_r,rev,**common_assert)
    # POST: all single conversions worked...
    

if __name__ == "__main__":
    run()
