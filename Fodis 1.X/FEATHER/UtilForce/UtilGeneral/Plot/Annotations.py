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

from matplotlib.path import Path
from matplotlib.patches import PathPatch
    
def round_to_n_sigfigs(to_round,n=1):
    """
    :param to_round: number to round (Can be array, too)
    :param n: how many sig figs
    :return: rounded number
    """
    # exponent = floor of log10(x)
    # so 1 sig fig is rounding to -(exponent)
    # so 2 sig figs is rounding to -(exponent) + 1
    # so n sig figs is rounding to -(exponent) + (n-1)
    f = lambda x : np.round(x, -int(np.floor(np.log10(x))) + (n - 1))
    if (hasattr(to_round,'size')):
        to_ret = [f(tmp) for tmp in to_round]
    else:
        to_ret = f(to_round)
    return to_ret

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
    should_be_zero = y_zero * data_range + min_y
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

def _triangle_patch(x,y,width,height,fig,transform=None,color='g',alpha=0.5):
    """
    :param x: offset for the triangle 'bottom left'
    :param y: offset for the triangle 'bottom left'
    :param width: of the triangle
    :param height: of the triangle
    :param fig:  to use
    :param transform: to use; defaults to figure units
    :return: patch; can use (e.g.) fig.patches.extend([patch]) to add
    """
    if (transform is None):
        transform = fig.transFigure
    triangle_x,triangle_y = [x,y]
    triangle_width = width
    triangle_height = height
    triangle_path_array = \
        [[triangle_x, triangle_y],
         [triangle_x+triangle_width, triangle_y],
         [triangle_x+triangle_width, triangle_y+triangle_height],
         [triangle_x, triangle_y]]
    path = Path(triangle_path_array)
    patch = PathPatch(path, fill=True, color=color, alpha=alpha,
                      zorder=0,transform=transform, figure=fig,
                      linewidth=0,linestyle='None',clip_on=True)
    return patch
    
def _rainbow_gen(x,y,strings,colors,ax=None,kw=[dict()],add_space=True):
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
        if (add_space):
            s_text = s + " "
        else:
            s_text = s
        text = ax.text(x, y, s_text, color=c, transform=t,
                       clip_on=False,**(kw[i % n_kw]))
        text.draw(canvas.get_renderer())
        ex = text.get_window_extent()
        t = transforms.offset_copy(text._transform, x=ex.width, units='dots')  
                        

def rainbow_text(x, y, strings, colors, ax=None,add_space=False, **kw):
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
    return _rainbow_gen(x=x,y=y,strings=strings,colors=colors,ax=ax,
                        add_space=add_space,kw=[kw])


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
    to_ret = r"$\mathbf{" + \
             sig_fig + r"\cdot 10^{" + sign_str + exponent + r"}}$"
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

def smart_fmt_str(n,err=None,min_digits=1,def_fmt_type="g"):
    """
    :param n: number to format
    :param err: error, if any.
    :param min_digits: minimum number of significant figures to show. defaults
    to 1, but adds extra (see notes below)
    :param def_fmt_type: the default way to format (e.g. 'g' or 'f'). Should
    be able to use like 'X' in {:.2X}
    :return: correct formatting string, where correct means:

    (1) in the presence of error:
        -- we add an extra digit for each factor of 10 difference
        -- suppose n = 10.2, err = 0.1, then default total of 3 digits
    (2) assuming we are a one (and didn't add digits because of a small error)
        -- add another digits (so that we dont just display an OOM)
        -- e.g. suppose n=11.2, then we displace as 11 instead of 10
    """
    sigfig, _, exp = sigfig_sign_and_exp(n,format_str="{:.0e}")
    if (err is not None):
        # determine the error exponent
        _, _, exp_err = sigfig_sign_and_exp(err, format_str="{:.0e}")
        # if the error is less, add that many sig figs.
        # e.g., suppose n = 10.2, error = 0.1, then we add 1 - (-1) = 2
        # so that we display as something like:
        # {:.2g}
        # meaning for the example (instead of just 10, we get
        # 10.2
        to_add = max(0,int(exp_err)-int(exp))
        min_digits += to_add
    # if the errror didnt add anything, and we are a 1, add a second digit.
    # this is more or less so we get more than an order of magnitude. i.e.,
    # 11 will be displayed as 11, not as 10.
    if ( (min_digits == 1) and np.round(float(sigfig), 0) == 1):
        min_digits += 1
    assert abs(int(min_digits) - min_digits) < 1e-6
    fmt = r"{:." + str(min_digits) + def_fmt_type + "}"
    return fmt

def _smart_str_with_err(h,errs=None,fmt=None):
    """
    :param h:  value
    :param errs: optional associated error.
    :param fmt: formatting string. if none, does its best to format the error
    accoreding to smart_fmt_str
    """
    fmt_was_none = fmt is None
    if (fmt is None):
        # if we have error, use it to get the formatting
        if (errs is None):
            fmt = smart_fmt_str(h)
        else:
            fmt = smart_fmt_str(h,errs)
    # POST: have the formatting string
    if (errs is None):
        # just format as formatl
        to_ret = fmt.format(h)
    else:
        e = errs
        # use smart fotmatting on the errror if we used it on the format.
        fmt_err = smart_fmt_str(e) if fmt_was_none else fmt
        to_ret = (fmt + r" $\pm$ " + fmt_err).format(h,e)
    return to_ret

def _autolabel_f_str(i,r,errs=None,*args,**kwargs):
    """
    :param i: index of the rectangle (should also index into errrs, if present
    :param r: something with a .getheight() method
    :param errs: list of errors; index i shold be assoctaed with the height
    :param args,**kwargs: see _smart_str_with_err
    :return: formatting string
    """
    h = r.get_height()
    _smart_str_with_err(h,*args,errs=errs[i],**kwargs)


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


def broken_axis(f_plot,range1,range2,ax1,ax2,axis_ratio,linewidth=1):
    """
    :param f_plot: takes in an axis and a number, plots the data
    :param range1: range for ax1
    :param range2: range for ax2
    :param ax1: first axis to use
    :param ax2: second axis to use
    :param axis_ratio: if not the same width, ratio of widths
    :param linewidth: for the plot
    :return: Nothing, consider using with fmt_broken
    """
    # If we were to simply plot pts, we'd lose most of the interesting
    # details due to the outliers. So let's 'break' or 'cut-out' the y-axis
    # into two portions - use the top (ax) for the outliers, and the bottom
    # (ax2) for the details of the majority of our data

    # plot the same data on both axes
    f_plot(ax1,1)
    f_plot(ax2,2)

    ax1.set_xlim(range1)
    ax2.set_xlim(range2)

    # This looks pretty good, and was fairly painless, but you can get that
    # cut-out diagonal lines look with just a bit more work. The important
    # thing to know here is that in axes coordinates, which are always
    # between 0-1, spine endpoints are at these locations (0,0), (0,1),
    # (1,0), and (1,1).  Thus, we just need to put the diagonals in the
    # appropriate corners of each of our axes, and so long as we use the
    # right transform and disable clipping.

    d = .015 # how big to make the diagonal lines in axes coordinates
    # arguments to pass plot, just so we don't keep repeating them
    d1 = d * axis_ratio
    d2 = d
    kwargs = dict(transform=ax1.transAxes, color='k', clip_on=False,
                  linewidth=linewidth)
    ax1.plot((1-d1,1+d1), (-d,+d), **kwargs)
    ax1.plot((1-d1,1+d1),(1-d,1+d), **kwargs)

    kwargs.update(transform=ax2.transAxes)  # switch to the bottom axes
    ax2.plot((-d2,+d2), (1-d2,1+d2), **kwargs)
    ax2.plot((-d2,+d2), (-d2,+d2), **kwargs)

    return ax1,ax2


def fmt_broken(ax1,ax2):
    """
    Formats a broken (x) axis

    :param ax1: the first axis to format
    :param ax2: the second axis to format
    :return:
    """
    # hide the spines between ax and ax2
    ax1.spines['right'].set_visible(False)
    ax2.spines['left'].set_visible(False)
    ax1.yaxis.tick_left()
    ax1.tick_params(labelright='off')
    ax2.yaxis.tick_right()
    tickAxisFont(ax=ax1)
    # get rid of annoying ticks
    ax1.spines['right'].set_visible(False)
    ax2.spines['left'].set_visible(False)
    ax1.tick_params(right=False)
    ax2.tick_params(left=False, labelright='off')
    ylabel("",ax=ax2)


def connect_bbox(bbox1, bbox2,
                 loc1a, loc2a, loc1b, loc2b,
                 prop_lines, prop_patches=None):
    """
    connect the two bboxes see zoom_effect01(ax1, ax2, xmin, xmax)
    """
    if prop_patches is None:
        prop_patches = prop_lines.copy()
    c1 = BboxConnector(bbox1, bbox2, loc1=loc1a, loc2=loc2a, **prop_lines)
    c1.set_clip_on(False)
    c2 = BboxConnector(bbox1, bbox2, loc1=loc1b, loc2=loc2b, **prop_lines)
    c2.set_clip_on(False)
    bbox_patch1 = BboxPatch(bbox1, color='k',**prop_patches)
    bbox_patch2 = BboxPatch(bbox2, color='w',**prop_patches)
    p = BboxConnectorPatch(bbox1, bbox2,
                           # loc1a=3, loc2a=2, loc1b=4, loc2b=1,
                           loc1a=loc1a, loc2a=loc2a, loc1b=loc1b, loc2b=loc2b,
                           **prop_patches)
    p.set_clip_on(False)

    return c1, c2, bbox_patch1, bbox_patch2, p


def zoom_left_to_right_kw():
    return dict(loc1a=1,loc2a=2,loc1b=4,loc2b=3)


def zoom_effect01(ax1, ax2, xmin, xmax, color='m', alpha_line=0.5,
                  alpha_patch=0.15, loc1a=3, loc2a=2, loc1b=4, loc2b=1,
                  linestyle='--', linewidth=1.5, xmin2=None, xmax2=None,
                  alpha_patch2=None,**kwargs):
    """
    connect ax1 & ax2. The x-range of (xmin, xmax) in both axes will
    be marked.  The keywords parameters will be used to create
    patches.

    Args:
        ax1 : the main axes
        ax2 : the zoomed axes
        alpha_<line/patch>: the transparency of the line or patch
        (xmin,xmax) : the limits of the colored area in both plot axes.
        **kwargs: passed to prop_lines
        xmin2/xmax2: for the second axis, if we want a different limits
        (e.g. axes with different units), can specify separate limit for each

    Note:

        'loc' proceeds counter-clockwise from upper right (which is 1)
        'upper right'  : 1,
        'upper left'   : 2,
        'lower left'   : 3,
        'lower right'  : 4
    """

    trans1 = blended_transform_factory(ax1.transData, ax1.transAxes)
    trans2 = blended_transform_factory(ax2.transData, ax2.transAxes)

    xmin2 = xmin2 if xmin2 is not None else xmin
    xmax2 = xmax2 if xmax2 is not None else xmax

    alpha_patch2 = alpha_patch2 if alpha_patch2 is not None else alpha_patch

    bbox1 = Bbox.from_extents(xmin, 0, xmax, 1)
    bbox2 = Bbox.from_extents(xmin2, 0, xmax2, 1)

    mybbox1 = TransformedBbox(bbox1, trans1)
    mybbox2 = TransformedBbox(bbox2, trans2)

    prop_patches = kwargs.copy()
    prop_patches["ec"] = "none"
    prop_patches["alpha"] = alpha_patch
    prop_lines = dict(color=color, alpha=alpha_line, linewidth=linewidth,
                      linestyle=linestyle, **kwargs)
    c1, c2, bbox_patch1, bbox_patch2, p = \
        connect_bbox(mybbox1, mybbox2,
                     loc1a=loc1a, loc2a=loc2a, loc1b=loc1b, loc2b=loc2b,
                     prop_lines=prop_lines, prop_patches=prop_patches)
    bbox_patch2.alpha = alpha_patch2
    ax1.add_patch(bbox_patch1)
    ax2.add_patch(bbox_patch2)
    ax2.add_patch(c1)
    ax2.add_patch(c2)
    ax2.add_patch(p)

    return c1, c2, bbox_patch1, bbox_patch2, p

