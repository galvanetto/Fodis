# force floating point division. Can still use integer with //
from __future__ import division
# other good compatibility recquirements for python3
from __future__ import absolute_import
from __future__ import print_function
from __future__ import unicode_literals
 # -*- coding: utf-8 -*-
# import utilities for error repoorting etc
from . import GenUtilities as util
# use matplotlib for plotting
#http://matplotlib.org/faq/usage_faq.html#what-is-a-backend
import matplotlib.pyplot  as plt
# import numpy for array stuff
import numpy as np
# for color cycling
from itertools import cycle
import sys
import os
from matplotlib.ticker import FixedLocator,NullLocator,AutoMinorLocator
import matplotlib as mpl

from matplotlib import ticker
g_tom_text_rendering = dict(on=False)
g_font_label = 7.5
g_font_title = 9
g_font_subplot_label = 10
g_font_tick = 7.5
g_font_legend = 8
g_tick_thickness = 1
g_tick_length = 4
g_minor_tick_width = 1
g_minor_tick_length= 2
# make the hatches larges

from string import ascii_lowercase
from matplotlib.ticker import LogLocator,MaxNLocator
# for the zoom effect
from mpl_toolkits.axes_grid1.inset_locator import BboxPatch, BboxConnector,\
    BboxConnectorPatch
from matplotlib.transforms import Bbox, TransformedBbox, \
    blended_transform_factory
from matplotlib import ticker


import string
from itertools import cycle
from six.moves import zip

_uppercase = ["{:s}".format(s.upper()) for s in string.ascii_uppercase]
_lowercase = ["{:s}".format(s.lower()) for s in string.ascii_lowercase]

def right_arrow_thin():
    return u"\u279c"

def right_arrow():
    return u"\u27A1"

def down_arrow():
    return u'$\mathsf{\u2B07}$'

def math_it(s,add_dollars=False):
    to_ret =  "\mathsf{" + s + "}"
    if add_dollars:
        to_ret = "$" + to_ret + "$"
    return to_ret 

def plot_setup(mt_shrink_factor=0.7,mt_sup1=0.8):
    """
    Sets up the plotting options as we like them
    """
    mpl.rcParams['hatch.linewidth'] = 3
    mpl.rcParams['hatch.color'] = '0.5'
    # see :
    # stackoverflow.com/questions/18699027/write-an-upright-mu-in-matplotlib
    default_font = "DejaVu Sans"
    mpl.rc("font", **{"sans-serif": default_font,
                      "style": 'normal',
                      'family':'sans-serif'})
    plt.rcParams['font.family'] = 'sans-serif'
    mpl.rcParams['text.latex.unicode'] = True
    mpl.rcParams['mathtext.fontset'] = 'custom'
    mpl.rcParams['mathtext.rm'] = '{}'.format(default_font)
    # anything that is italic should *also* be bold 
    mpl.rcParams['mathtext.it'] = '{}:bold:italic'.format(default_font)
    mpl.rcParams['mathtext.bf'] = '{}:bold'.format(default_font)
    # we use sf as a hack to get the italic font, if we need it 
    mpl.rcParams['mathtext.sf'] = '{}:italic'.format(default_font)
    """
    # See :
#stackoverflow.com/questions/24684897/matplotlib-set-superscript-font-size?rq=1
    """
    # How much text shrinks when going to the next-smallest level.  GROW_FACTOR
    # must be the inverse of SHRINK_FACTOR.
    mpl.mathtext.SHRINK_FACTOR   = mt_shrink_factor
    mpl.mathtext.GROW_FACTOR     = 1.0 / mpl.mathtext.SHRINK_FACTOR
    mpl.mathtext.SUP1            = mt_sup1
    mpl.mathtext.NUM_SIZE_LEVELS      = 2
    # Percentage of x-height that sub/superscripts drop below the baseline
    base_font = mpl.mathtext.FontConstantsBase
    # Percentage of x-height that superscripts drop below the baseline
    base_font.sup1 = mt_sup1



def upright_mu(unit=u""):
    """
    Returns: an upright mu, optionally follow by <unit>. Recquires unicode. 
    """
    return u"\u03bc" + unit

def label_axes(fig, labels=None, loc=None, add_bold=False,
               axis_func= lambda x: x,**kwargs):
    """
    Walks through axes and labels each.
    kwargs are collected and passed to `annotate`
    Parameters
    credit: 

    gist.github.com/tacaswell/9643166

    and

    stackoverflow.com/questions/22508590/enumerate-plots-in-matplotlib-figure
    ----------
    fig : Figure
         Figure object to work on
    labels : iterable or None
        iterable of strings to use to label the axes.
        If None, lower case letters are used.
    loc : len=2 tuple of floats (or list of them, one per axis)
        Where to put the label in axes-fraction units
    """
    if labels is None:
        labels = _uppercase
    # re-use labels rather than stop labeling
    labels = cycle(labels)
    axes = axis_func(fig.axes)
    n_ax = len(axes)
    if loc is None:
        loc = (-0.2, 0.95)
    if (isinstance(loc,tuple)):
        loc = [loc for _ in range(n_ax)]
    for ax, lab,loc_tmp in zip(axes, labels,loc):
        ax.annotate(lab, xy=loc_tmp,
                    xycoords='axes fraction',**kwargs)

def label_tom(fig,labels=None, loc=None,fontsize=g_font_subplot_label,
              **kwargs):
    """
    labels each subplot in fig

    fig : Figure
         Figure object to work on

    loc,labels : see label_axes
    others: passedto text arguments
    """
    text_args = dict(horizontalalignment='center',
                     verticalalignment='center',
                     fontweight='bold',
                     fontsize=fontsize,**kwargs)
    label_axes(fig,labels=labels,loc=loc,**text_args)
    
def FormatImageAxis(ax=None):
    """
    Formats the given (default current) axis for displaying an image 
    (no ticks,etc)

    Args:
         ax: the axis to format
         aspect: passed to the axis
    """
    ax = gca(ax)
    # Turn off axes and set axes limits
    ax.axis('off')

def _remove_labels(ax):
    ax.set_ticklabels([])
    # if we remove the tick labels, then we bring the label (e.g. y axis name)
    # down 
    ax.labelpad=-1

def _remove_ticks(ax):
    ax.set_ticks([])

def _remove_grid(ax):
    ax.set_visible(False)

def no_y_label(ax=None):
    ax = gca(ax)
    _remove_labels(ax.get_yaxis())

def no_x_label(ax=None):
    ax = gca(ax)
    _remove_labels(ax.get_xaxis())

def no_x_grid(ax=None):
    ax = gca(ax)
    _remove_grid(ax.get_xaxis())

def no_y_grid(ax=None):
    ax = gca(ax)
    _remove_grid(ax.get_yaxis())

def no_x_axis(ax=None):
    ax = gca(ax)
    ax.xaxis.set_visible(False)
    
def no_y_axis(ax=None):
    ax.yaxis.set_visible(False)    

def no_x_ticks(ax=None):
    ax = gca(ax)
    _remove_ticks(ax.get_xaxis())

def no_y_ticks(ax=None):
    ax = gca(ax)
    _remove_ticks(ax.get_yaxis())
    
def no_x_anything(ax=None):
    ax = gca(ax)
    no_x_axis(ax)
    no_x_grid(ax)
    no_x_label(ax)

    
def no_y_anything(ax=None):
    ax = gca(ax)
    no_y_axis(ax)
    no_y_grid(ax)    
    no_y_label(ax)   
    _remove_ticks(ax.get_yaxis()) 

def x_label_on_top(ax=None,ticks_on_bottom='off'):
    ax = gca(ax)
    ax.xaxis.set_label_position('top')
    tick_dict = dict(labeltop='on',labelbottom=ticks_on_bottom)
    ax.xaxis.set_tick_params(which='major',**tick_dict)
    ax.xaxis.set_tick_params(which='minor',**tick_dict)


def AddSubplotLabels(fig=None,axs=None,skip=0,
                     xloc=-0.03,yloc=1,fontsize=30,fontweight='bold',
                     bbox=dict(facecolor='none', edgecolor='black',
                               boxstyle='round,pad=0.2')):
    """
    Adds labels to current subplot in their fig.axes order

    Args:
        fig: where to add; adds sequentially to all subplots, if no axs
        axs: if present, only add to these subplots)
        All the rest: see ax.text arguments
    """
    # get the axes we are adding...
    if (axs is None):
        if (fig is None):
            fig = plt.gcf()
        axs = fig.axes
    lim = len(axs)
    labels = [c for c in ascii_lowercase[skip:][:lim]]
    for ax,label in zip(axs,labels):
        ax.text(xloc, yloc, label, transform=ax.transAxes,
                fontsize=fontsize, fontweight=fontweight, va='top', ha='right',
                bbox=bbox)



def _LegendAndSave(Fig,SaveName,loc="upper right",frameon=True,close=False,
                  tight=True,**kwargs):
    """
    Refreshes the legend on the given figure, saves it *without* closing
    by default

    Args:
        fig: the figure hangle to use
        SaveName: what to save this as 
        ... : see legend
    Returns:
        Nothing
    """
    legend(loc=loc,frameon=frameon)
    savefig(Fig,SaveName,close=close,tight=tight,**kwargs)

def legend_and_save(Fig,Base,Number=0,ext=".png",**kwargs):
    """
    Same as legend and save, except takes a "base" 

    Args:
         Fig: See LegendAndSave
         Base:  base name to use
         Number: which figure iteration; we just count up
         ext: extension for the filename
         **kwargs: see LegendAndSave
    Returns:
        Number+1
    """
    _LegendAndSave(Fig,Base+str(Number) + ext,**kwargs)
    return Number + 1

def colorbar(label,labelpad=15,rotation=270,fontsize=g_font_legend,
             fontsize_ticks=g_font_legend,fig=None,n_ticks=4,fontweight='bold',
             bar_kwargs=dict()):
    """
    Makes a simple color bar on the current plot, assuming that something
    like hist2d has already been called:
    
    Args:
        label: what to put on the colorpad
        labelpad,rotation,fontsize: see cbar.set_label: 
 matplotlib.org/api/colorbar_api.html#matplotlib.colorbar.ColorbarBase.set_label
    """
    if (fig is None):
        color_module = plt
    else:
        color_module = fig
    cbar = color_module.colorbar(**bar_kwargs)
    cbar.set_label(label,labelpad=labelpad,rotation=rotation,fontsize=fontsize,
                   fontweight='bold')
    cbar.ax.tick_params(labelsize=fontsize_ticks)
    tick_locator = ticker.MaxNLocator(nbins=n_ticks)
    cbar.locator = tick_locator
    cbar.update_ticks()
    return cbar

def legend(loc=None,frameon=False,ncol=1,
           handlelength=1,handletextpad=1,ax=None,
           bbox_to_anchor=None,fancybox=False,markerscale=1,color='k',
           numpoints=1,scatterpoints=1,
           font_dict=dict(weight='bold',size=g_font_legend),**kwargs):
    """
    :param loc: location of the legend
    :param frameon:  see plt.legend
    :param ncol: see plt.legend
    :param handlelength: see plt.legend
    :param handletextpad: see plt.legend
    :param ax: axis to assign the legend to
    :param bbox_to_anchor: see plt.legend
    :param fancybox: see plt.legend
    :param markerscale: see plt.legend
    :param color: see plt.legend
    :param numpoints: see plt.legend
    :param scatterpoints: see plt.legend
    :param font_dict: passed to legend as 'prop', which are the font properties.
    I don't like 'prop', not descriptive enough
    :param kwargs: see plt.legend
    :return:
    """
    ax = gca(ax)
    if (loc is None):
        loc = 'best'
    prop = font_dict
    leg = ax.legend(loc=loc,frameon=frameon,prop=prop,ncol=ncol,
                    handlelength=handlelength,handletextpad=handletextpad,
                    fancybox=fancybox,bbox_to_anchor=bbox_to_anchor,
                    scatterpoints=scatterpoints,
                    markerscale=markerscale,numpoints=numpoints,**kwargs)
    if (leg is not None):
        for text in leg.get_texts():
            plt.setp(text,color=color)
    return leg

def color_legend_items(leg,colors):
    """
    :param leg: legend to color
    :param colors: for each of the labels
    :return: nothing
    """
    texts = leg.get_texts()
    assert len(colors) == len(texts) , \
        "Didn't provide the correct number of labels"
    for c,text in zip(colors,texts):
        text.set_color(c)

def genLabel(func,label,fontsize=g_font_label,fontweight='bold',
             **kwargs):
    """
    :param func: function to call (e.g. plt.xlabel)
    :param label:  to use for the label
    :param fontsize:  passed to func
    :param fontweight: passed to func
    :param kwargs:  passed to func
    :return:
    """
    to_ret = func(label,fontsize=fontsize,fontweight=fontweight,
                  family='sans-serif',**kwargs)
    return to_ret


        
def xlabel(lab,ax=None,**kwargs):
    """
    Sets the x label 
    
    Args:
         lab: the abel to use
         ax: the axis to label. defaults to current
         **kwargs:  see genLabel
    Returns:
         Label
    """
    ax = gca(ax)
    return genLabel(ax.set_xlabel,lab,**kwargs)

def ylabel(lab,ax=None,**kwargs):
    """
    Sets the y label
     
    Args: 
        See xlabel
    Returns:
        See xlabel
    """
    ax = gca(ax)
    return genLabel(ax.set_ylabel,lab,**kwargs)

def zlabel(lab,ax=None,**kwargs):
    """
    Sets the z label
     
    Args: 
        See xlabel
    Returns:
        See xlabel
    """
    ax = gca(ax)
    return genLabel(ax.set_zlabel,lab,**kwargs)
    
def title(lab,fontsize=g_font_title,fontweight='bold',ax=None,**kwargs):
    ax = gca(ax)
    ax.set_title(lab,fontsize=fontsize,fontweight=fontweight,**kwargs)

def gca(ax=None):
    return ax if ax is not None else plt.gca()

def lazyLabel(xlab,ylab,titLab,
              axis_kwargs=dict(),
              tick_kwargs=dict(add_minor=True),
              legend_kwargs=dict(frameon=False,loc='best'),
              title_kwargs=dict(),
              useLegend=True,zlab=None,ax=None):
    """
    Easy method of setting the x,y, and title, and adding a legend
    
    Args:
         xlab: the x label to use
         ylab: the y label to use
         titLab: the title to use
         yrotation: angle to rotate. Default is vertical
         titley: where to position the title 
         frameon: for the legend; if true, adds a frame (and background)
         to the legend
         
         loc: legend location
         bbox_to_anchor: where to anchor the legend
         useLegend : boolean, true: add a legend
         zlab: the z label, for the third axis
    Returns: 
         nothings
    """
    ax = gca(ax)
    # set the labels and title
    xlabel(xlab,ax=ax,**axis_kwargs)
    ylabel(ylab,ax=ax,**axis_kwargs)
    title(titLab,ax=ax,**title_kwargs)
    # set the font
    tickAxisFont(ax=ax,**tick_kwargs)
    # if we have a z or a legemd, set those too.
    if (zlab is not None):
        zlabel(zlab,ax=ax,**axis_kwargs)
    if (useLegend):
        leg = legend(ax=ax,**legend_kwargs)
    else:
        leg = None
    return leg

def setLegendBackground(legend,color):
    """
    Sets the legend background to a particular color

    Args:
        legend: legend to set
        color: color to set legend to 
    
    Returns:
        This is a description of what is returned.
    """
    legend.get_frame().set_facecolor(color)
                

def _log_decade_ticks(ax,min_log,max_log,ax_set_func,num=None,**kw_ticks):
    """
    Utility function for placing ticks exactly were we want them in logspace

    :param ax: axis to use
    :param min_log:  minimum log10 to display
    :param max_log:  maximum log10 to display
    :param ax_set_func: e.g. ax.set_xticks
    :param num: of ticks; defaults to 1 per decade
    :param kw_ticks: passed to tickAxisFont
    :return: see tickAxisFont
    """
    if (num is None):
        num = max_log - min_log + 1
    ax_set_func(np.logspace(min_log, max_log, base=10, num=num))
    return tickAxisFont(ax=ax,**kw_ticks)

def x_log_ticks(ax,*args,**kw):
    """
    :param ax: to set
    :param args: see  _log_decade_ticks
    :param kw: see _log_decade_ticks
    :return: see _log_decade_ticks
    """
    return _log_decade_ticks(ax,*args,ax_set_func=ax.set_xticks,**kw)

def log_limits(ax_lim):
    """
    :param ax_lim: limits of the axis
    :return: minimum and maximum log10 decades, rounded.
    E.g. if plot is from 5 to  105, it will return 1,2 for 10 and 100
    """
    return np.ceil(np.log10(min(ax_lim))), np.floor(np.log10(max(ax_lim)))



def axis_locator(ax,n_major,n_minor):
    """
    utility function; given an axis, returns sets the locator properly

    Args:
        see tick_axis_number
    Returns:
        nothing
    """
    scale = ax.get_scale()
    if (scale == 'log'):
        subs = [1,] if n_minor <= 1 else np.linspace(1,n_minor+1,n_minor)
        ax.set_major_locator(LogLocator(numticks=n_major,subs=subs))
    else:
        ax.set_major_locator(MaxNLocator(n_major))
        if (n_minor > 0):
            # get the number of minor ticks per major ticks (for AutoMinor)
            n_minor_per_major = int(np.round(n_minor/n_major))
            ax.set_minor_locator(AutoMinorLocator(n_minor_per_major))

def tom_ticks(ax=None,num_major=4,num_minor=0,**kwargs):
    """
    Convenience wrapper for tick_axis_number to make ticks like tom likes

    Args:
        ax: the axis to use
        num_major: how many ticks to use on the major axis
        kwargs: see tick_axis_number
    Returns:
        nothing
    """
    ax = gca(ax)
    tick_axis_number(ax=ax,
                     num_x_major=num_major,
                     num_x_minor=num_minor,
                     num_y_major=num_major,
                     num_y_minor=num_minor,**kwargs)
    if (num_minor == 0):                     
        ax.tick_params(which='minor',right=False,left=False,top=False,
                       bottom=False,axis='both')
                    
    
def tick_axis_number(ax=None,num_x_major=5,num_x_minor=None,num_y_major=5,
                     num_y_minor=None,change_x=True,change_y=True):
    """
    Sets the locators on the x and y ticks

    Args:
        ax: what axis to use
        num_<x/y>_major: how many major ticks to put on the x,y
        num_<x/y>_minor: how many minor ticks to put on the x,y
        change_<x/y>: if to apply to x/y
    Returns:
        Nothing
    """
    ax = gca(ax)
    if (num_x_minor is None):
        num_x_minor = 2 * num_x_major
    if (num_y_minor is None):
        num_y_minor = 2 * num_y_major
    if (change_x):
        axis_locator(ax.xaxis,num_x_major,num_x_minor)
    if (change_y):
        axis_locator(ax.yaxis,num_y_major,num_y_minor)
    
def tickAxisFont(fontsize=g_font_tick,
                 major_tick_width=g_tick_thickness,
                 major_tick_length=g_tick_length,
                 minor_tick_width=g_minor_tick_width,
                 minor_tick_length=g_minor_tick_length,direction='in',
                 ax=None,common_dict=None,axis='both',bottom=True,
                 top=True,left=True,right=True,add_minor=False,
                 pad=2,**kwargs):
    """
    sets the tick axis font and tick sizes

    Args:
         ax: what tick to use 
         fontsize: for the ticks
         <major/minor>_tick_<width/length>: the length or width for the minor 
         or major ticks. 
         kwargs: passed directly to tick_params
    """
    ax = gca(ax)
    common_dict = dict(direction=direction,pad=pad,
                       axis=axis,bottom=bottom,top=top,right=right,left=left,
                       **kwargs)
    ax.tick_params(length=major_tick_length, width=major_tick_width,
                   labelsize=fontsize,which='major',**common_dict)
    if (add_minor):                   
        ax.tick_params(length=minor_tick_length, width=minor_tick_width,
                       which='minor',**common_dict)
    if (hasattr(ax, 'zaxis') and ax.zaxis is not None):
        ax.zaxis.set_tick_params(width=g_tick_thickness,length=g_tick_length)

def xTickLabels(xRange,labels,rotation='vertical',fontsize=g_font_label,
                **kwargs):
    tickLabels(xRange,labels,True,rotation=rotation,fontsize=fontsize,**kwargs)

def yTickLabels(xRange,labels,rotation='horizontal',fontsize=g_font_label,
                **kwargs):
    tickLabels(xRange,labels,False,rotation=rotation,fontsize=fontsize,**kwargs)

def tickLabels(xRange,labels,xAxis,tickWidth=g_tick_thickness,ax=None,**kwargs):
    ax = gca(ax)
    if (xAxis):
        ax.set_xticks(xRange)
        ax.set_xticklabels(labels,**kwargs)
        mLocs = ['bottom','top']
    else:
        ax.set_yticks(xRange)
        ax.set_yticklabels(labels,**kwargs)
        mLocs = ['left','right']
    for l in mLocs:
        ax.spines[l].set_linewidth(tickWidth)
        ax.spines[l].set_linewidth(tickWidth)

def cmap(num,cmap = plt.cm.gist_earth_r):
    """
    Get a color map with the specified number of colors and mapping

    Args:
        num: number of colors
        cmap: color map to use, from plt.cm
    Returns:
        color map to use
    """
    return cmap(np.linspace(0, 1, num))


def addColorBar(cax,ticks,labels,oritentation='vertical'):
    cbar = plt.colorbar(cax, ticks=ticks, orientation='vertical')
    # horizontal colorbar
    cbar.ax.set_yticklabels(labels,fontsize=g_font_label)
    
def color_frame(color,ax=None,**kw):
    """
    See : color_axis_ticks, except colors the entire frame. kw is shared
    """
    color_x(ax=ax,color=color,**kw)
    color_y(ax=ax,color=color,**kw)

def _color_gen(color,ax,keywords):
    """
    :param ax: axis to choose
    :param color: to make the spines
    :param keywords: see color_axis_ticks
    :return:
    """
    ax = gca(ax)
    for kw_tmp in keywords:
        color_axis_ticks(color=color, ax=ax, **kw_tmp)

def color_x(color,ax=None,**kw):
    keywords = [dict(spine_name="top",axis_name="x",**kw),
                dict(spine_name="bottom",axis_name="x",**kw)]
    _color_gen(color,ax,keywords)

def color_y(color,ax=None,**kw):
    keywords = [dict(spine_name="left", axis_name="y", **kw),
                dict(spine_name="right", axis_name="y", **kw)]
    _color_gen(color,ax, keywords)

def color_axis_ticks(color,spine_name="left",axis_name="y",ax=None,
                     label_color=None):
    """
    colors the specific axis as desired 
    
    Args:
        color: to use
        spine_name: off the axis
        axis_name: x or y-yerr
        ax: to color
    Returns: 
        nothing
    """
    if (label_color) is None:
        label_color = color
    ax = gca(ax)
    ax.tick_params(axis_name,color=color,which='both',labelcolor=label_color)
    ax.spines[spine_name].set_color(color)        
    ax.spines[spine_name].set_edgecolor(color)

def color_x_tick_minor_labels(ax,colors_cat):
    """
    :param ax: to get the x axis on
    :param colors_cat: the colors for the *minor* tick labels
    :return: nothing
    """
    ax = gca(ax)
    tick_labels_minor_tmp = ax.xaxis.get_minorticklabels()
    for i,t in enumerate(tick_labels_minor_tmp):
        t.set_color(colors_cat[i])
    
def secondAxis(ax,label,limits,secondY =True,color="Black",scale=None,
               tick_color='k',tick_axis_kw=dict()):
    """
    Adds a second axis to the named axis

    Args:
        ax: which axis to use
        label: what to label the new axis
        limits: limits to put on the new axis (data units)
        secondY: if true, uses the y axis, else the x
        color: what to color the new axis
        scale: for the axis. if None, defaults to the already present one
    Returns:
        new axis
    """
    current = ax
    if (scale is None):
        if secondY:
            scale = ax.get_yscale() 
        else:
            scale = ax.get_xscale()
    axis = "y" if secondY else "x"
    spines = "right" if secondY else "top"
    if(secondY):
        ax2 = ax.twinx()
        ax2.set_yscale(scale, nonposy='clip')
        ax2.set_ylim(limits)
        # set the y axis to the appropriate label
        lab = ylabel(label,ax=ax2)
        tickLabels = ax2.get_yticklabels()
        tickLims =  ax2.get_yticks()
        axis_opt = dict(axis=axis,left=False,**tick_axis_kw)
        other_axis_opt = dict(axis=axis,right=False)
        ax.yaxis.tick_left()
    else:
        ax2 = ax.twiny()
        ax2.set_xscale(scale, nonposx='clip')
        ax2.set_xlim(limits)
        # set the x axis to the appropriate label
        lab = xlabel(label,ax=ax2)
        tickLabels = ax2.get_xticklabels()
        tickLims =  ax2.get_xticks()
        axis_opt = dict(axis=axis,bottom=False,**tick_axis_kw)
        other_axis_opt = dict(axis=axis,top=False)
    color_axis_ticks(color=tick_color,spine_name=spines,axis_name=axis,ax=ax2)          
    [i.set_color(color) for i in tickLabels]
    lab.set_color(color)
    current.tick_params(**other_axis_opt)
    tickAxisFont(ax=ax2,**axis_opt)
    plt.sca(current)
    return ax2

def pm(stdOrMinMax,mean=None,fmt=".3g"):
    if (mean ==None):
        mean = np.mean(stdOrMinMax)
    arr = np.array(stdOrMinMax)
    if (len(arr) == 1):
        delta = arr[0]
    else:
        delta = np.mean(np.abs(arr-mean))
    return ("{:"+ fmt + "}+/-{:.2g}").format(mean,delta)

def savefig(figure,fileName,close=True,tight=True,subplots_adjust=None,
            bbox_inches='tight',pad=1,pad_inches=0.02,**kwargs):
    """
    Saves the given figure with the options and filenames
    
    Args:
        figure: what figure to use
        fileName: what to save the figure out as
        close: if true (def), clsoes the figure
        tight: if true, reverts to the tight layour
        subplot_adjust: if not none, a dictionary to give to plt.subplots_adjust
        **kwargs: passed to figure savefig
    Returns:
        nothing
    """
    if (tight):
        plt.tight_layout(pad=pad)
    if (subplots_adjust is not None):
        plt.subplots_adjust(**subplots_adjust)
    baseName = util.getFileFromPath(fileName)
    if ("." not in baseName):
        formatStr = ".jpeg"
        fullName = fileName + formatStr
    else:
        _,formatStr = os.path.splitext(fileName)
        fullName = fileName
    """
    for rationale, see (Stack overflow):
    questions/11837979/removing-white-space-around-a-saved-image-in-matplotlib
    """
    figure.savefig(fullName,format=formatStr[1:],pad_inches=pad_inches,
                   dpi=figure.get_dpi(),bbox_inches=bbox_inches,**kwargs)
    if (close):
        plt.close(figure)

def figure(figsize=None,xSize=3.5,ySize=3.5,dpi=600,kw_setup=dict(),**kw):
    """
    wrapper for figure, allowing easier setting I think

    Args:
        figsize: tuple of (x,y). If none, uses xsize and ysize
        xSize: x size of figure in inhes
        ySize: y size of figure in inches
        dpi: dots per inch
    Returns:
        figure it created
    """
    plot_setup(**kw_setup)
    if (figsize is not None):
        xSize = figsize[0]
        ySize = figsize[1]
    return  plt.figure(figsize=(xSize,ySize),dpi=dpi,**kw)

def getNStr(n,space = " "):
    return space + "n={:d}".format(n)

def tom_text_rendering():
    """
    This function sets up matplotlib to use latex and make the font defaults
    close to what time liks
    """
    # turn the file-specific rendering on
    g_tom_text_rendering['on'] = True
    # we need latex and unicode to be safe
    mpl.rc('text', usetex=True)
    mpl.rcParams['text.latex.unicode'] =True
    """
    make the normal font Helvetica :
    stackoverflow.com/questions/11367736/matplotlib-consistent-font-using-latex  
    """
    mpl.rcParams['font.family'] = 'sans-serif'
    mpl.rcParams['font.sans-serif'] = ['Helvetica']    
    mpl.rcParams['font.style'] = 'normal'
    # bm: bold/italic math. 
    # bfdefault: all fonts are assumed bold by default
    # sfdefault: all non-math are sans-serif
    # see :https://stackoverflow.com/questions/2537868/sans-serif-math-with-latex-in-matplotlib
    preamble = [
       u'\\usepackage{siunitx}',   # i need upright \micro symbols, but also
       u'\sisetup{detect-all}',   # ...this to force siunitx for your fonts
       u'\\usepackage{helvet}',    # set the normal font here
       u'\\usepackage{sansmath}',  # load up the sansmath so that math -> helvet
       u'\sansmath',              # <- tricky! -- gotta actually tell tex
       u'\\usepackage{amsmath}',    # use this for bold symbols 
       u'\\usepackage{sfmath}',
       u'\\usepackage{relsize}',
       ]
    mpl.rcParams['text.latex.preamble']= preamble
    mathtext_format = "serif:italic:bold"
    mpl.rcParams['mathtext.it'] = mathtext_format
    mpl.rcParams['mathtext.bf'] = mathtext_format
    mpl.rcParams['mathtext.rm'] = mathtext_format
    # see: https://stackoverflow.com/questions/32725483/matplotllib-and-xelatex
    mpl.rcParams['mathtext.fallback_to_cm'] = False

def bf_italic(s):
    """
    Returns: s formatted in a bold and italic manner. 
    S should *not* be in math mode (the returned string will be)
    """
    if g_tom_text_rendering['on']:
        # make it bold
        fmt = lambda x: r"\boldsymbol{" + x + r"}"
    else:
        # do nothing 
        fmt = lambda x: x
    # always go into math mode
    return "$" + fmt(s) + "$"

def variable_string(label="F"):
    """
    Returns: bf_italic applied to F
    """
    return bf_italic(label)

def unit_string(label="F",units="pN"):
    """
    Returns: bf_italic applied to F, with <units> in parenthesis
    """
    return "{:s} ({:s})".format(variable_string(label=label),units)

def save_twice(fig,name1,name2,close_last=True,**kwargs):
    """
    Saves 'fig' to name1 and name2, passing along **kwargs to savefig,
    closing is close_last is true
    """
    savefig(fig,name1,close=False,**kwargs)
    savefig(fig,name2,close=close_last,**kwargs)

def save_png_and_svg(fig,base,**kwargs):
    """
    See: save_twice, except assumes a png and svg file are needed.
    """
    save_twice(fig,base +".png",base+".svg",**kwargs)
    
def save_tom(fig,base,**kwargs):
    """
    Saves however tom would like me to 
    
    2017-10-12: he wants jpeg.
    """
    savefig(fig,base + ".tiff",close=False,**kwargs)   
    save_twice(fig,base +".jpeg",base+".svg",**kwargs)
    
# legacy API. plan is now to mimic matplotlib 
def colorCyc(num,cmap = plt.cm.winter):
    cmap(num,cmap)
def pFigure(xSize=10,ySize=8,dpi=100):
    return figure(xSize,ySize,dpi)
def saveFigure(figure,fileName,close=True):
    savefig(figure,fileName,close)
