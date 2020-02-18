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
import re
    
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

def add_zero_rel(ax,x_pos,y_zero=None,s="0",**kwargs):
    """
    :param ax: axis to put a zero tick
    :param x_pos: where to center the text, in relative axis coords
    :param y_zero: where to place the y, in relative axis coors
    :param s: string to use
    :param kwargs: passed to relative_annotate
    :return: nothing; throws an error if this isn't y_zero in the data units
    """
    min_y, max_y = ax.get_ylim()
    data_range = max_y - min_y
    if (y_zero is None):
        y_zero = (0 - min_y)/data_range
    should_be_zero = y_zero * data_range + ylim_data[0]
    assert should_be_zero < data_range * 1e-3 , "Didn't get proper zero"
    relative_annotate(ax=ax,s=s, xy=(x_pos, y_zero),
                      xycoords='axes fraction', clip_on=False,
                      verticalalignment="center",**kwargs)


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


def sigfig_sign_and_exp(number, format_str="{:3.1e}"):
    """
    gets the significant figure(s), sign, and exponent of a number

    Args:
        number: the number we want
        format_str: how it should be formatted (limiting number of sig figs)
    Returns:
        tuple of <sig figs,sign,exponent>
    """
    scientific = format_str.format(number)
    pattern = r"""
               (\d+[\.]*\d*) # number.numbers
               e          # literal e
              ([+-])0*(\d+)     # either plus or minus, then exponent
              """
    sig = re.match(pattern, scientific, re.VERBOSE)
    return sig.groups()


def pretty_error_exp(number, error, error_fmt="{:.1g}", **kwargs):
    """
    retrns the number +/- the error

    Args:
        number: the number we want
        error_str: how it should be formatted (limiting number of sig figs)
        **kwargs: passed to get_sigfig_sign_and_exponent
    Returns:
        pretty-printed (latex) of number +/- error, like: '(a +/- b) * 10^(c)'
    """
    sigfig, sign, exponent = sigfig_sign_and_exp(number, **kwargs)
    # get the error in terms of the exponent of the number
    exponent_num = float(exponent) * -1 if sign == "-" else float(exponent)
    error_rel = error / (10 ** (exponent_num))
    string_number_and_error = sigfig + r"\pm" + error_fmt.format(error_rel)
    # add parenths
    string_number_and_error = "(" + string_number_and_error + ")"
    return _pretty_format_exp(string_number_and_error, sign, exponent)


def _pretty_format_exp(sig_fig, sign, exponent):
    """
    pretty prints the number sig_fig as <number * 10^(exponent)>

    Args:
        sig_fig: number to print
        sign: literal +/-
        exponent: what to put in 10^{right here}
    Returns:
        formatted string
    """
    sign_str = "" if sign == "+" else "-"
    to_ret = r"$" + sig_fig + r"\cdot 10^{" + sign_str + exponent + r"}$"
    return to_ret


def pretty_exp(number, **kwargs):
    """
    takes a number and returns its pretty-printed exponent format

    Args:
        number: see pretty_exp_with_error
        **kwargs: passed to get_sigfig_sign_and_exponent
    Returns:
        see pretty_exp_with_error
    """
    args = sigfig_sign_and_exp(number, **kwargs)
    return _pretty_format_exp(*args)


def autolabel_points(xy,
                     x_func = lambda i,r: r[0],
                     y_func =lambda i,r: r[1] * 1.2,*args,**kwargs):
    """
    :param xy: tuple; first element is x list, second element is y list
    :param x_func: takes in xy pair, gives back x
    :param y_func: takes in xy pair, gives back y
    :param args:
    :param kwargs:
    :return:
    """
    assert len(xy) == 2 , "Need to pass x then y "
    x = xy[0]
    y = xy[1]
    assert len(x) * len(y) > 0 , "Need at least one point"
    assert len(x) == len(y) , "x doesn't match y "
    xy_pairs = [ [x[i],y[i]] for i,_ in enumerate(x) ]
    return autolabel(xy_pairs,*args,
                     x_func=x_func,y_func=y_func,
                     **kwargs)

def autolabel(rects,label_func=lambda i,r: "{:.3g}".format(r.get_height()),
              x_func=None,y_func=None,fontsize=g_font_legend,ax=None,
              color_func = lambda i,r: "k",**kwargs):
    """
    Attach a text label above each bar displaying its height

    Args:
        rects: return from ax.bar
        label_func: takes a rect and its index, returns the label
        x_func: takes in index and rectangle. returns where to put the label
        y_func: as x func, but for y
    Returns:
        nothing, but sets text labels
    """
    ax = gca(ax)
    if (x_func is None):
        x_func = lambda i,rect: rect.get_x() + rect.get_width()/2.
    if (y_func is None):
        y_func = lambda i,rect: rect.get_height() * 1.2
    for i,rect in enumerate(rects):
        text = label_func(i,rect)
        x = x_func(i,rect)
        y = y_func(i,rect)
        ax.text(x,y,text,ha='center', va='bottom',fontsize=fontsize,
                color=color_func(i,rect),**kwargs)


