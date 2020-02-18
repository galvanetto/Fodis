# force floating point division. Can still use integer with //
from __future__ import division
# other good compatibility recquirements for python3
from __future__ import absolute_import
from __future__ import print_function
from __future__ import unicode_literals
# This file is used for importing the common utilities classes.
import numpy as np
import matplotlib.pyplot as plt
import sys,matplotlib
from ..PlotUtilities import *

    
from matplotlib import transforms

# XXX move to utility class?
default_font_dict = dict(fontsize=g_font_label,
                         fontweight='bold',
                         family="sans",
                         color='k',
                         horizontalalignment='center',
                         verticalalignment='lower',
                         bbox=dict(color='w',alpha=0,pad=0))
    
def _annotate(ax,s,xy,**font_kwargs):
    """
    Adds a simpel text annotation. 
    
    Args:
        ax: where to add the annotation
        s: the string
        xy: the location of the string. 
        **font_kwargs: anything accepted by ax.annotate. defaults are added
        if they dnot exist.
    Returns:
        ax.annotate object 
    """
    # add in defaults if they dont exist    
    for k,v in default_font_dict.items():
        if k not in font_kwargs:
            font_kwargs[k] = v
    # POST: all default added   
    return ax.annotate(s=s, xy=xy,**font_kwargs)
    
def relative_annotate(ax,s,xy,xycoords='axes fraction',**font_kwargs):
    """
    see: _annotate, except xy are given in 0-1 from bottom left ('natural')
    """
    return _annotate(ax,s,xy,xycoords=xycoords,**font_kwargs)
    
def add_rectangle(ax,xlim,ylim,fudge_pct=0,facecolor="None",linestyle='-',
                  edgecolor='k',linewidth=0.75,zorder=10,**kw):
    """
    Ease-of-use function to add a rectangle to ax
    
    Args:
        ax: the axis to add to
        <x/y>_lim: limits of the rectangle
        fudge_pct: how much to add, as a fraction of the axis range. 
        remainder: see  matplotlib.patches.Rectangle
    Returns : 
        the rectangle added 
    """
    x_min,x_max = min(xlim),max(xlim)
    y_min,y_max = min(ylim),max(ylim)
    fudge = (x_max-x_min) * fudge_pct
    xy = [x_min,y_min]
    width = (x_max-x_min) + fudge
    height = (y_max-y_min) + fudge
    r = matplotlib.patches.Rectangle(xy=xy,width=width,height=height,
                                     facecolor=facecolor,linestyle=linestyle,
                                     edgecolor=edgecolor,zorder=zorder,
                                     linewidth=linewidth,**kw)
    ax.add_patch(r)  
    return r 
    
def _rainbow_gen(x,y,strings,colors,ax=None,kw=[dict()]):
    """
    See: rainbow_text, except kw is an array now.
    """
    if ax is None:
        ax = plt.gca()
    t = ax.transData
    canvas = ax.figure.canvas
    # horizontal version
    n_kw = len(kw)
    for i,(s, c) in enumerate(zip(strings, colors)):
        text = ax.text(x, y, s + " ", color=c, transform=t, 
                       clip_on=False,**(kw[i % n_kw]))
        text.draw(canvas.get_renderer())
        ex = text.get_window_extent()
        t = transforms.offset_copy(text._transform, x=ex.width, units='dots')  
                        

def rainbow_text(x, y, strings, colors, ax=None, **kw):
    """
    Take a list of ``strings`` and ``colors`` and place them next to each
    other, with text strings[i] being shown in colors[i].

    This example shows how to do both vertical and horizontal text, and will
    pass all keyword arguments to plt.text, so you can set the font size,
    family, etc.

    The text will get added to the ``ax`` axes, if provided, otherwise the
    currently active axes will be used.
    
    See: 
        matplotlib.org/examples/text_labels_and_annotations/rainbow_text.html
          
    """
    return _rainbow_gen(x=x,y=y,strings=strings,colors=colors,ax=ax,kw=[kw])


