# force floating point division. Can still use integer with //
from __future__ import division
# other good compatibility recquirements for python3
from __future__ import absolute_import
from __future__ import print_function
from __future__ import unicode_literals
# This file is used for importing the common utilities classes.
import numpy as np
import matplotlib.pyplot as plt
import sys,copy,matplotlib

from ..PlotUtilities import *
from . import Annotations

default_font_dict = dict(fontsize=g_font_label,
                         fontweight='bold',
                         family="sans",
                         color='k',
                         horizontalalignment='center',
                         verticalalignment='lower',
                         bbox=dict(color='w',alpha=0,pad=10))
                         
def_font_kwargs_y = copy.deepcopy(default_font_dict)
def_font_kwargs_y['horizontalalignment'] = 'right'
def_font_kwargs_y['verticalalignment'] = 'center'   

def_line_kwargs = dict(linewidth=1.5,color='k')      

def font_kwargs_modified(x_kwargs=dict(),y_kwargs=dict()):
    """
    Returns the font kwargs 
    
    Args:
        <x/y>_kwargs: applied to the x and y font; overwrites them
    Returns:
        default_font_dict and def_font_kwargs, except overwritten by 
        <x/y>_kwargs. So, tuple of x and y 
    """
    to_ret_x = copy.deepcopy(default_font_dict)
    to_ret_y = copy.deepcopy(def_font_kwargs_y)
    for k,v in x_kwargs.items():
        to_ret_x[k] = v
    for k,v in y_kwargs.items():
        to_ret_y[k] = v
    return to_ret_x,to_ret_y

def round_to_n_sig_figs(x,n=1):
    """
    Rounds 'x' to n significant figures

    Args:
         x: what to round
         n: how many sig figs (e.g. n=1 means 51 --> 50, etc)
    Returns: rounded number 
    """
    return round(x, (n-1)-int(np.floor(np.log10(abs(x)))))


def _get_tick_locator_fixed(offset,width,lim=plt.xlim()):
    """
    given a (data-units) offset and width, returns tick so that
    (1) offset is a tick
    (2) each offset +/- (n * width) for n an integer within lim is a tick.

    Useful for matching ticks to a scale bar 

    Args:
         offset: point which should have a tick on it
         width: data units, length between ticks
         lim: to determine where the ticks should be 
    Returns:
         FixedLocator parameter
    """
    xmin,xmax = lim
    # determine how many widths to go before and after
    n_widths_before = int(np.ceil(abs((offset-xmin)/width)))
    width_before = n_widths_before * width
    n_widths_after = int(np.ceil(abs((xmax-offset)/width)))
    width_after = n_widths_after * width
    ticks_after = np.arange(start=offset,stop=offset+(width_after+width),
                            step=width)
    ticks_before = np.arange(start=offset,stop=offset-(width_before+width),
                             step=-width)
    ticks = list(ticks_before) + list(ticks_after)
    locator = FixedLocator(locs=ticks, nbins=None)
    return locator

def ticks(ax,axis,lim,x,y,is_x,add_minor):
    """
    :param ax: axis to put the ticks on
    :param axis: e.g. ax.xaxis
    :param lim: limits to use (xaxis.get_xlim)
    :param x: x[1]-x[0] gives the tick spacing if is_x=True
    :param y: y[1]-y[0] gives the tick spacing if is_x=False
    :param is_x: if we are changing the x ticks
    :param add_minor: if we should add the minor ticks 
    :return:
    """
    if (is_x):
        tick_spacing = abs(np.diff(x))
        offset = min(x)
    else:
        tick_spacing = abs(np.diff(y))
        offset = min(y)
    locator_x = _get_tick_locator_fixed(offset=offset, width=tick_spacing,
                                        lim=lim)
    locator_minor_x = _get_tick_locator_fixed(offset=offset + tick_spacing / 2,
                                              width=tick_spacing, lim=lim)
    axis.set_major_locator(locator_x)
    if (add_minor):
        axis.set_minor_locator(locator_minor_x)
    """
    make sure the ticks are ontop of the data 
    See (e.g.):
stackoverflow.com/questions/19677963/matplotlib-keep-grid-lines-behind-the-graph-but-the-y-and-x-axis-above
    """
    ax.set_axisbelow(False)

def _scale_bar_and_ticks(ax,axis,lim,is_x=True,add_minor=False,**kwargs):
    """
    convenience wrapper for create a scale bar with convenient ticks 
    
    Args:
        ax: like plt.gca()
        axis: something we can use 'set_major.minor_locator' on
        lim: the limits of the axis
    Returns:
        nothing
    """
    box,x,y = _scale_bar(ax=ax,**kwargs)
    return ticks(ax,axis,lim,x,y,is_x,add_minor)
    
def _y_scale_bar_and_ticks(ax=plt.gca(),**kwargs):
    """
    Convenience wrapper to make a scale bar and ticks
    
    Args:
        kwargs: passed to _scale_bar_and_ticks
    Returns:
        nothing
    """    
    _scale_bar_and_ticks(ax,ax.yaxis,ax.get_ylim(),is_x=False,**kwargs)   

def _x_scale_bar_and_ticks(ax=plt.gca(),**kwargs):
    """
    Convenience wrapper to make a scale bar and ticks
    
    Args:
        kwargs: passed to _scale_bar_and_ticks
    Returns:
        nothing
    """
    _scale_bar_and_ticks(ax,ax.xaxis,ax.get_xlim(),**kwargs)   
    
def abs_to_rel(ax,x,is_x):
    """
    returns: x (in relative, data coordinates of ax) or y, if is_x=False
    """
    lim = ax.get_xlim() if is_x else ax.get_ylim()
    return (x-lim[0])/(lim[1]-lim[0])

def rel_to_abs(ax,x,is_x):
    """
    Returns: x (in data coords) transformed to the relative [0,1] coordinates
             of the x/y axis of ax 
    """
    if (is_x):
        lim = ax.get_xlim()
    else:
        lim = ax.get_ylim()
    absolute = lim[0] + (lim[1] - lim[0]) * x
    return absolute
    
    
def offsets_and_ranges(width,height,offset_x,offset_y):
    """
    Returns the coordinates for the text and scale bar, given the parameters
    
    Args;
        width/height: of the bar
        offset_x,offset_y: of the text
    Returns: 
        tuple of <xy for text, xy endpoints for line>
    """
    bar_offset_x = width/2
    bar_offset_y = height/2 
    text_offset_x = offset_x  
    text_offset_y = offset_y
    xy_text = [text_offset_x,text_offset_y]   
    xy_line =  [ [text_offset_x - bar_offset_x,text_offset_y - bar_offset_y],
                [text_offset_x + bar_offset_x,text_offset_y + bar_offset_y]]
    return xy_text,xy_line                
    
def unit_format(val,unit,fmt="{:.0f}",value_function=lambda x:x):
    """
    Returns: the way we want to format the scale bar text; <val><space><unit>
    """
    val = value_function(val)
    # make sure the formatted string matches the actual length
    formatted = float(fmt.format(val))
    err_msg = "Formatted scalebar ({:.2g}) not close to true length ({:.2f})".\
          format(formatted,val)
    np.testing.assert_allclose(formatted,val,atol=0,err_msg=err_msg)
    # POST: the formatted value is accurate.
    return (fmt + " {:s}").format(val,unit) 

def x_scale_bar_and_ticks(unit,width,offset_x,offset_y,ax=plt.gca(),
                          unit_kwargs=dict(fmt="{:.0f}"),smart_nudge=True,
                          nudge_kwargs=dict(factor_x=0,factor_y=1),**kwargs):
    """
    See: y_scale_bar_and_ticks, except makes an x scale bar with a specified
    width
    """                                       
    xy_text,xy_line = offsets_and_ranges(width=width,height=0,
                                         offset_x=offset_x,offset_y=offset_y)
    text = unit_format(width,unit,**unit_kwargs)   
    if (smart_nudge):
        kwargs = _nudge_linewidth(ax=ax,kw=kwargs,**nudge_kwargs)
    return _x_scale_bar_and_ticks(ax=ax,xy_text=xy_text,xy_line=xy_line,
                                  text=text,**kwargs)
                                  
def _offset(x,y,ax,f):
    """
    applies f to x and y 
    """
    offset_x = f(ax=ax,x=x,is_x=True)
    offset_y = f(ax=ax,x=y,is_x=False)
    return offset_x,offset_y

def x_and_y_to_rel(x_abs,y_abs,ax):
    """
    See: x_and_y_to_abs, except abs <--> rel 
    """
    return _offset(x=x_abs,y=y_abs,ax=ax,f=abs_to_rel)

def x_and_y_to_abs(x_rel,y_rel,ax):
    """
    converts x and y to absolute units (asusming they are in [0,1] axes units)
    
    Args:
        <x/y>_rel: see rel_to_abs
        ax: which axis they are relative on
    Returns;
        the asbolute values of the x and y units...
    """
    return _offset(x=x_rel,y=y_rel,ax=ax,f=rel_to_abs)
                                  
def x_scale_bar_and_ticks_relative(unit,width,offset_x,offset_y,
                                   ax=plt.gca(),**kw):
    """
    See: x_scale_bar_and_ticks, except offset_x and offset_y are in [0,1] 
    relative graph units 
    """
    offset_x,offset_y = x_and_y_to_abs(offset_x,offset_y,ax)
    return x_scale_bar_and_ticks(unit,width,offset_x,offset_y,ax=ax,**kw)  

def y_scale_bar_and_ticks_relative(unit,height,offset_x,offset_y,
                                   ax=plt.gca(),font_kwargs=def_font_kwargs_y,
                                   **kw):
    """
    See: y_scale_bar_and_ticks, except offset_x and offset_y are in [0,1] 
    relative graph units 
    """                                   
    offset_x,offset_y = x_and_y_to_abs(offset_x,offset_y,ax)
    return y_scale_bar_and_ticks(unit,height,offset_x,offset_y,ax=ax,
                                 font_kwargs=font_kwargs,**kw)                  
                                  
def y_scale_bar_and_ticks(unit,height,offset_x,offset_y,ax=plt.gca(),
                          unit_kwargs=dict(),smart_nudge=True,
                          nudge_kwargs=dict(factor_x=-1,factor_y=0),**kwargs):
    """
    ease-of-use function for making a y scale bar. figures out the units and 
    offsets
    
    Args;
        unit: of height
        height: of the scale bar 
        offset_<x/y>: where the text box should be, in absolute units
        **kwargs: see _y_scale_bar_and_ticks
    Returns:
        tuple of <annnotation, x coordinates of line, y coords of line>
    """                          
    xy_text,xy_line = offsets_and_ranges(width=0,height=height,
                                        offset_x=offset_x,offset_y=offset_y)
    text = unit_format(height,unit,**unit_kwargs)
    if (smart_nudge):
        kwargs = _nudge_linewidth(ax=ax,kw=kwargs,**nudge_kwargs)
    return _y_scale_bar_and_ticks(ax=ax,xy_text=xy_text,xy_line=xy_line,
                                  text=text,**kwargs)       
                                
def _nudge_linewidth(ax,kw,factor_x=0,factor_y=0):
    """
    changes 'fudge_text_pct' so the text is factor_<x/y> line widths away
    from the line.

    Args:
         ax: which axis we are using
         kw: the keyworkd dictionary; should have line_kwargs in it (or 
         we just use the default line_kwargs dict, which itself needs linewidth)
         
         factor_<x/y>: how many line widths to move in x/y 
    
    Returns:
         updated kw dictionary
    """
    # make a copy of the keywords
    kw_ret = dict(**kw)
    # determine how to fudge everything
    if ("line_kwargs" not in kw_ret):
        kw_line = def_line_kwargs
    else:
        kw_line = kw_ret["line_kwargs"]
    assert "linewidth" in kw_line , "must provide a line width for scalebar"
    linewidth = kw_line["linewidth"]
    # determine what percentage, in units of axis fraction, to move the
    # text
    nudge_y = _line_width_to_rel_units(ax=ax,width=linewidth,is_x=False)
    nudge_x = _line_width_to_rel_units(ax=ax,width=linewidth,is_x=True)
    kw_ret['fudge_text_pct'] = dict(x=nudge_x*factor_x,y=nudge_y*factor_y)
    return kw_ret

def _crossed_sanitized(ax,x_kwargs,y_kwargs,factor_x_x=0,factor_x_y=-1,
                       factor_y_x=-1,factor_y_y=0):
    """
    Utility function for making the scale bars (like "|_") pretty

    Args:
        ax: the axis this applies to
        x_kwargs: for the x part of the scalebar
        y_kwargs: for the x part of the scalebar
        factor_<x_y>: if not None, nudges the <x> text away in the <y/>
        direction by this many line widths. e.g. factor_x=-1 moves the x 
        text *down* (away from scalebar line) by 1 linewidth
    Returns:
        updated x_kwargs, y_kwargs

    """
    x_kwargs = dict(**x_kwargs)
    y_kwargs = dict(**y_kwargs)
    # x scalebar shoule aligned at the top
    if ('font_kwargs' not in x_kwargs):
        x_kwargs['font_kwargs'] = copy.deepcopy(default_font_dict)
    x_kwargs['font_kwargs']['verticalalignment']='top'
    # make the y scale bar kwargs, if needed
    if ('font_kwargs' not in y_kwargs):
        font_kw = copy.deepcopy(def_font_kwargs_y)
        y_kwargs['font_kwargs'] = font_kw   
    # make sure the y scalebar is vertical
    y_kwargs['font_kwargs']['rotation'] = 90
    # factor_x is how much to nudge the *x* scalebar in *y*
    x_kwargs = _nudge_linewidth(ax=ax,kw=x_kwargs,factor_x=factor_x_x,
                                factor_y=factor_x_y)
    # factor_y is how much to nudge the *y* scalebar in *x*
    y_kwargs = _nudge_linewidth(ax=ax,kw=y_kwargs,factor_x=factor_y_x,
                                factor_y=factor_y_y)
    return x_kwargs,y_kwargs
    

def crossed_x_and_y(offset_x,offset_y,x_kwargs,y_kwargs,ax=plt.gca(),
                    x_on_top=False,sanitize_kwargs=dict(),y_on_right=False):
    """
    ease of use for making a 'crossed' x and y scale bar. 
    
    Args;
        offset_<x/y>: see _scale_bar
        <x_/y_>kwargs: passed to <x/y>_scale_bar_and_ticks. Shouldnt 
        have nudge_kwargs

        x_on_top: if true, the x scalebar is drawn on top (ie: the crossed
        scalebars will look like "|-", instead of a "|_", where "-" is on top
        sanitize_kwargs: passed to _crossed_sanitized
    Returns:
        tuple of <annnotation, x coordinates of line, y coords of line>
    """
    assert ("height" in y_kwargs.keys()) , "Height not specified"
    assert ("width" in x_kwargs.keys()) , "Width not specified"
    width = x_kwargs['width']
    height = y_kwargs['height']
    # make the scalebars make sense.
    x_kwargs,y_kwargs = _crossed_sanitized(ax=ax,x_kwargs=x_kwargs,
                                           y_kwargs=y_kwargs,
                                           **sanitize_kwargs)
    x_scalebar_y_offset = offset_y
    y_scalebar_x_offset = offset_x-width/2
    # move the x scalebar up, if need be
    if (x_on_top):
        x_scalebar_y_offset += height
        # make the x label above, so it looks like
        #  <xlabel>
        #  _______
        # |
        x_kwargs['fudge_text_pct']['y'] = abs(x_kwargs['fudge_text_pct']['y'])
        x_kwargs['font_kwargs']['verticalalignment'] = 'bottom'
    # move the y scale bar right, if need be
    if (y_on_right):
        y_scalebar_x_offset += width
        y_kwargs['fudge_text_pct']['x'] = abs(y_kwargs['fudge_text_pct']['x'])
        y_kwargs['font_kwargs']['horizontalalignment'] = 'left'
    # since the inputs have been sanitized, the x and y scalebars
    # shouldnt so anything
    x_scale_bar_and_ticks(offset_x=offset_x,offset_y= x_scalebar_y_offset,
                          ax=ax,smart_nudge=False,**x_kwargs) 
    y_scale_bar_and_ticks(offset_x=y_scalebar_x_offset,
                          offset_y=offset_y + height / 2,
                          ax=ax,smart_nudge=False,**y_kwargs)         


def crossed_x_and_y_relative(offset_x,offset_y,ax=plt.gca(),**kwargs):
    """
    See: crossed_x_and_y, except offsets are in axis units 
    """
    offset_x,offset_y = x_and_y_to_abs(offset_x,offset_y,ax=ax)
    return crossed_x_and_y(offset_x,offset_y,ax=ax,**kwargs)                    

def _scale_bar_rectangle(ax,x,y,s,width,height,is_x,
                         font_color='w',add_minor=False,
                         box_props=dict(facecolor='black',edgecolor='black',
                                        zorder=0),center_x=False,center_y=False,
                         rotation=90,fontsize=6.5,**kw):
    """
    Makes a scalebar (usually outside of the axes)

    Args:
        ax: which axis to add to 
        <x/y> the x and y coordinates, *in units of the axis*
        s: the text to add
        <width/height>: of the box, *in data units*
    Returns:
        tuple of (rectangle, annotaton)
    """
    x_abs,y_abs = x_and_y_to_abs(x_rel=x,y_rel=y,ax=ax)
    if (center_x):
        x_abs -= width/2
    if (center_y):
        y_abs -= height/2
    xlim = [x_abs,x_abs+width]
    ylim = [y_abs,y_abs+height]
    # add an *un-clipped* scalebar, so we can draw outside the axes
    r = Annotations.add_rectangle(ax=ax,xlim=xlim,ylim=ylim,
                                  clip_on=False,
                                  **box_props)
    x_text = x_abs + width/2
    y_text = y_abs + height/2
    # make sure that text is above box (unless we explicitly set them
    # differently)
    if ('zorder' in box_props):
        min_z_text = box_props['zorder'] + 1
    else:
        min_z_text = 3
    if ('zorder' not in kw):
        kw['zorder'] = min_z_text
    annot = ax.annotate(xy=(x_text,y_text),s=s, color=font_color,
                        horizontalalignment='center',fontweight='bold',
                        verticalalignment='center',xycoords='data',
                        clip_on=False,fontsize=fontsize,annotation_clip=False,
                        rotation=rotation,**kw)
    axis = ax.xaxis if is_x else ax.yaxis
    lim = ax.get_xlim() if is_x else ax.get_ylim()
    ticks(ax, axis=axis, lim=lim, x=xlim, y=ylim, is_x=is_x,
          add_minor=add_minor)
    return r,annot

def scale_bar_rectangle_x(ax,x_rel,y_rel,unit,width,height_rel=0.3,
                          unit_kwargs=dict(),
                          **kw):
    """
    See: _scale_bar_rectangle, except height_rel is the relative height needed
    """
    ylim = ax.get_ylim()
    height_abs = height_rel * (ylim[1]-ylim[0])
    s = unit_format(val=width,unit=unit,**unit_kwargs)
    _scale_bar_rectangle(ax=ax,x=x_rel,y=y_rel,s=s,width=width,
                         height=height_abs,rotation=0,is_x=True,**kw)

def scale_bar_rectangle_y(ax,x_rel,y_rel,unit,height,unit_kwargs=dict(),
                          width_rel=0.3,**kw):
    """
    See: _scale_bar_rectangle, except height_rel is the relative height needed
    """
    xlim = ax.get_xlim()
    width_abs = width_rel * (xlim[1]-xlim[0])
    s = unit_format(val=height,unit=unit,**unit_kwargs)
    _scale_bar_rectangle(ax=ax,x=x_rel,y=y_rel,s=s,width=width_abs,
                         height=height,rotation=90,is_x=False,**kw)

def _line_width_to_data_units(width,ax,is_x):
    """
    Based on (S.O.): 
questions/19394505/matplotlib-expand-the-line-with-specified-width-in-data-unit/

    Args:
        width: line with, in points
        ax: where the line will be drawn
        is_x: if the width is in x (ie: line is from y0 to yf with width along
        x axis)
    Returns:
        line width ins *data* units
    """
    axis = ax
    fig = axis.get_figure()
    if is_x:
        length = fig.bbox_inches.width * axis.get_position().width
        value_range = np.diff(axis.get_xlim())
    else:
        length = fig.bbox_inches.height * axis.get_position().height
        value_range = np.diff(axis.get_ylim())
    # Convert length to points
    length *= 72
    # Scale linewidth to value range
    return width * (value_range/length)

def _line_width_to_rel_units(width,ax,is_x):
    """
    See: _line_width_to_data_units, except width is relative to plot width 
    (or height, as appropriate)
    """
    data_width = _line_width_to_data_units(width=width,ax=ax,is_x=is_x)
    lim = ax.get_xlim() if is_x else ax.get_ylim()
    diff = np.diff(lim)
    rel_width = data_width/diff
    return rel_width

def _scale_bar(text,xy_text,xy_line,ax=plt.gca(),
               line_kwargs=def_line_kwargs,
               font_kwargs=default_font_dict,
               fudge_text_pct=dict(x=0,y=0)):
    """
    Creates a scale bar using the specified, absolute x and y
    
    Args;
        text: to display
        xy_text: where the text should be
        xy_line: where the scalebar should be
        ax: the axis to use
        <line/font>_kwargs: passed to plot and annotate, respectively
        fudge_text_pct: as a percentage of the scale bar, how much to shift the 
        text. Useful for preventing overlap. 
    
    Returns:
        tuple of <annnotation, x coordinates of line, y coords of line>
    """
    x_draw = np.array([x[0] for x in xy_line])
    y_draw = np.array([x[1] for x in xy_line])    
    # shift the text, if need be. 
    xlim,ylim = ax.get_xlim(),ax.get_ylim()
    x_diff,y_diff = xlim[1]-xlim[0],ylim[1]-ylim[0]
    x_text = xy_text[0]
    y_text = xy_text[1]
    x_text += x_diff * fudge_text_pct['x']
    y_text += y_diff * fudge_text_pct['y']   
    # POST: shifted     
    xy_text = [x_text,y_text]
    t = Annotations._annotate(ax=ax,s=text,xy=xy_text,**font_kwargs)
    ax.plot(x_draw,y_draw,**line_kwargs)
    return t,x_draw,y_draw

def scalebar_offset_for_zero(limits,range_scalebar):
    """
    :param limits: of the relevant axis
    :param range_scalebar: of the scalebar size
    :return: tuple of <offset, delta>. Any scalebar with an offset at
    offset + N*delta, where N is a number, will have a tick at zero.
    """
    min_y, max_y = min(limits), max(limits)
    y_range = (max_y-min_y)
    rel_range = range_scalebar/y_range
    rel_zero = (0 - min_y)/y_range
    return rel_zero, rel_range

def _scale_deltas(rel_zero,rel_scale):
    """
    :param rel_zero: see max_offset
    :param rel_scale: see max_offset
    :return:
    """
    return np.floor(rel_zero/rel_scale),\
           np.floor((1-rel_zero)/rel_scale)

def max_offset(rel_zero,rel_scale,offset=1):
    """
    :param rel_zero: where the scalebar can go, modulo rel_scale
    :param rel_scale: we want to place the scalebar at rel_zero + N * rel_scale
    :param offset: number of deltas to offset by, in case of extra text
    :return: tuple of (maximum relative offset, minimum relative offset)
    for scalebar to be completely in the range [0,1]
    """
    # determine how many deltas we can go up or down. In order to always
    # keep things in bounds, we subtract one from the possible deltas..
    lower_delta,upper_delta = _scale_deltas(rel_zero,rel_scale)
    max_delta_lower = max(0,lower_delta-offset)
    max_delta_upper = max(0,upper_delta-offset)
    return rel_zero - max_delta_lower * rel_scale,\
           rel_zero + max_delta_upper * rel_scale

def offsets_zero_tick(*args,**kwargs):
    """
    Syntactic sugar for getting where to put scalebar to get a tick at zero.

    :param args: see scalebar_offset_for_zero
    :param kwargs: see scalebar_offset_for_zero
    :return: tuple of <minimum offset, maximum offset, offset spacing in axis
    units >
    """
    rel_zero, rel_delta = scalebar_offset_for_zero(*args,**kwargs)
    # figure out where to put the scalebar so that F=0 is at a tick
    min_offset, max_off = max_offset(rel_zero,rel_delta)
    return min_offset, max_off, rel_delta