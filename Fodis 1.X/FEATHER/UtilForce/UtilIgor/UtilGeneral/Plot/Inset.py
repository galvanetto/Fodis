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

from UtilGeneral import PlotUtilities
from mpl_toolkits.axes_grid1.inset_locator import zoomed_inset_axes,mark_inset

def slice_by_x(x,y,xlim):
    """
    slices x and y by xlim:
     
    Args:
        <x/y>: arrays of the same shape:
        xlim: the limits for x-limits
        
    Returns:
        tuple of (sliced x, sliced y, y limits)
    """
    x = np.array(x)
    y = np.array(y)
    # plot the data red where we will zoom in 
    where_region = np.where( (x >= min(xlim)) & 
                             (x <= max(xlim)))
    assert x.shape == y.shape , "Arrays should be the same shape "
    zoom_x = x[where_region]
    zoom_y = y[where_region]
    ylim = [min(zoom_y),max(zoom_y)]
    return zoom_x,zoom_y,ylim
    
    
def zoomed_axis(ax=plt.gca(),xlim=[None,None],ylim=[None,None],
                remove_ticks=True,zoom=1,borderpad=1,loc=4,**kw):
    """
    Creates a (pretty) zoomed axis
    
    Args:
        ax: which axis to zoom on
        <x/y>_lim: the axes limits
        remove_ticks: if true, removes the x and y ticks, to reduce clutter
        remaining args: passed to zoomed_inset_axes
    Returns:
        the inset axis
    """    
    axins = zoomed_inset_axes(ax, zoom=zoom, loc=loc,borderpad=borderpad)
    axins.set_xlim(*xlim) # apply the x-limits
    axins.set_ylim(*ylim) # apply the y-limits
    if (remove_ticks):
        PlotUtilities.no_x_anything(axins)
        PlotUtilities.no_y_anything(axins)
    return axins
