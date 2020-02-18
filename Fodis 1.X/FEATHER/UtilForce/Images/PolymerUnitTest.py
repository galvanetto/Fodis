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

import PolymerTracing

def unit_test_difference():
    """
    See: _difference_matrix, except makes sure it does its job
    """
    _single_difference_test()

def _single_difference_test(v1=np.random.rand(500),v2=np.random.rand(500)):
    """
    Single iteration of unit_test_difference
    """
    n = v1.size
    m = v2.size
    expected = np.zeros((n,m))
    for i in range(n):
        for j in range(m):
            expected[i,j] = v2[j]-v1[i]
    diff = PolymerTracing._difference_matrix(v1,v2)
    np.testing.assert_allclose(diff,expected)

def _single_dot_test(v1=np.random.rand(500,2),v2=np.random.rand(500,2)):
    """
    Tests that the dot product function works properly.
    """
    n,m = v1.shape[0],v2.shape[0]
    expected = np.zeros((n,m))
    for i in range(n):
        for j in range(m):
            # cos(theta_[a,b]) = (a . b)/(|a|*|b|) = (a . b)
            # (for |a|=|b|=1)
            expected[i,j] = np.dot(v1[i],v2[j])
    dot = PolymerTracing._dot_matrix(v1,v2)
    np.testing.assert_allclose(dot,expected)

def unit_test_dot():
    _single_dot_test()

def run():
    unit_test_dot()
    unit_test_difference()

if __name__ == "__main__":
    run()