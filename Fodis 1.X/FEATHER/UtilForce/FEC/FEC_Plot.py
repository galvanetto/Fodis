# force floating point division. Can still use integer with //
from __future__ import division
# This file is used for importing the common utilities classes.
import numpy as np
import matplotlib.pyplot as plt
import sys
from . import FEC_Util
from ..UtilGeneral import PlotUtilities as PlotUtilities
from ..UtilGeneral.IgorUtil import SavitskyFilter
import copy

def_conversion_opts =dict(ConvertX = lambda x: x*1e9,
                          ConvertY = lambda y: y*1e12)

def _fec_base_plot(x,y,n_filter_points=None,label="",
                   style_data=dict(color='k',alpha=0.3),
                   style_filtered=None):
    """
    base function; plots x and y (and their filtered versions)
    
    Args:
        x/y: the x and y to use for plotting    
        n_filter_points: how many points for the savitsky golay
        style_<data/filtered>: plt.plot options for the raw and filtered data.
        defaults to filtered just being alpha=1 (not transparent)
    Returns:
        x and y, filtered versions
    """    
    if (style_filtered is None):
        style_filtered = dict(**style_data)
        style_filtered['alpha'] = 1
        style_filtered['label'] = label
    if (n_filter_points is None):
        n_filter_points = int(np.ceil(x.size * FEC_Util.default_filter_pct))
    if (n_filter_points > 1):
        x_filtered = SavitskyFilter(x,nSmooth=n_filter_points)
        y_filtered = SavitskyFilter(y,nSmooth=n_filter_points)
        plt.plot(x_filtered,y_filtered,**style_filtered)
    else:
        x_filtered = x
        y_filtered = y
    plt.plot(x,y,**style_data)
    return x_filtered,y_filtered
 
    
def _ApproachRetractCurve(Appr,Retr,NFilterPoints=100,
                          x_func = lambda x: x.Separation,
                          y_func = lambda y: y.Force, 
                          ApproachLabel="Approach",
                          RetractLabel="Retract",linewidth=1):
    """
    Most of the brains for the approach/retract curve. does *not* show anything

    Args:
        TimeSepForceObject: what we are plotting
        NFilterPoints: how many points to filter down
        ApproachLabel: label to put on the approach
        RetractLabel: label to put on the retract
    """
    # plot the separation and force, with their filtered counterparts
    _fec_base_plot(x_func(Appr),y_func(Appr),n_filter_points=NFilterPoints,
                   style_data=dict(color='r',alpha=0.3,linewidth=linewidth),
                   label=ApproachLabel)
    _fec_base_plot(x_func(Retr),y_func(Retr),n_filter_points=NFilterPoints,
                   style_data=dict(color='b',alpha=0.3,linewidth=linewidth),
                   label=RetractLabel)

def FEC_AlreadySplit(Appr,Retr,
                     XLabel = "Separation (nm)",
                     YLabel = "Force (pN)",
                     ConversionOpts=def_conversion_opts,
                     PlotLabelOpts=dict(),
                     PreProcess=False,
                     NFilterPoints=50,
                     LegendOpts=dict(loc='best'),
                     **kwargs):
    """

    Args:
        XLabel: label for x axis
        YLabel: label for y axis
        ConversionOpts: see FEC_Util.SplitAndProcess
        PlotLabelOpts: see arguments after filtering of ApproachRetractCurve
        PreProcess: if true, pre-processes the approach and retract separately
        (ie: to zero and flip the y axis).
        NFilterPoints: see FEC_Util.SplitAndProcess, for Savitsky-golay
        PreProcess: passed to 

    """
    ApprCopy = FEC_Util.UnitConvert(Appr,**ConversionOpts)
    RetrCopy = FEC_Util.UnitConvert(Retr,**ConversionOpts)
    if (PreProcess):
        ApprCopy,RetrCopy = FEC_Util.PreProcessApproachAndRetract(ApprCopy,
                                                                  RetrCopy,
                                                                  **kwargs)
    _ApproachRetractCurve(ApprCopy,RetrCopy,
                          NFilterPoints=NFilterPoints,**PlotLabelOpts)
    PlotUtilities.lazyLabel(XLabel,YLabel,"")
    PlotUtilities.legend(**LegendOpts)
    
def z_sensor_vs_time(time_sep_force,**kwargs):
    """
    plots z sensor versus time. See force_versus_time
    """
    plot_labels = dict(x_func=lambda x : x.Time,
                       y_func=lambda x : x.ZSnsr)
    FEC(time_sep_force,
        PlotLabelOpts=plot_labels,
        XLabel="Time (s)",
        YLabel="ZSnsr (nm)",**kwargs)
        
def force_versus_time(time_sep_force,**kwargs):
    """
    Plots force versus time
    
    Args:
        **kwargs: see FEC
    """
    plot_labels = dict(x_func=lambda x : x.Time,
                       y_func=lambda x: x.Force)
    FEC(time_sep_force,
        PlotLabelOpts=plot_labels,
        XLabel="Time (s)",
        YLabel="Force (pN)",**kwargs)
    
def FEC(TimeSepForceObj,NFilterPoints=50,
        PreProcessDict=dict(),
        **kwargs):
    """
    Plots a force extension curve. Splits the curve into approach and 
    Retract and pre-processes by default

    Args:
        TimeSepForceObj: 'Raw' TimeSepForce Object
        PreProcessDict: passed directly to FEC_Util.PreProcessFEC
        **kwargs: passed directly to FEC_Plot.FEC_AlreadySplit
    """
    Appr,Retr= FEC_Util.PreProcessFEC(TimeSepForceObj,
                                      NFilterPoints=NFilterPoints,
                                      **PreProcessDict)
    # plot the approach and retract with the appropriate units
    FEC_AlreadySplit(Appr,Retr,NFilterPoints=NFilterPoints,**kwargs)
    

def heat_map_fec(time_sep_force_objects,num_bins=(100,100),title="FEC Heatmap",
                 separation_max = None,n_filter_func=None,use_colorbar=True,
                 ConversionOpts=def_conversion_opts,cmap='afmhot',bins=None):
    """
    Plots a force extension curve. Splits the curve into approach and 
    Retract and pre-processes by default

    Args:
        time_sep_force_objects: list of (zeroed, but SI) TimeSepForce Object
        num_bins: tuple of <x,y> bins. Passed to hist2d
        n_filter_func: if not none, histograms the savitsky-golay *filtered*
        versuon of the objects given, with n_filter_func being a function
        taking in the TimeSepForce object and returning an integer number of 
        points
        
        use_colorbar: if true, add a color bar
        
        separation_max: if not None, only histogram up to and including this
        separation. should be in units *after* conversion (default: nanometers)
        
        ConversionOpts: passed to UnitConvert. Default converts x to nano<X>
        and y to pico<Y>
    """                 
    # convert everything...
    objs = [FEC_Util.UnitConvert(r,**ConversionOpts) 
            for r in time_sep_force_objects]
    if n_filter_func is not None:
        objs = [FEC_Util.GetFilteredForce(o,n_filter_func(o)) 
                for o in objs]
    filtered_data = [(retr.Separation,retr.Force) for retr in objs]
    separations = np.concatenate([r[0] for r in filtered_data])
    forces = np.concatenate([r[1] for r in filtered_data])
    if (separation_max is not None):
        idx_use = np.where(separations < separation_max)
    else:
        # use everything
        idx_use = slice(0,None,1)
    separations = separations[idx_use]
    forces = forces[idx_use]
    # make a heat map, essentially
    bins_input = bins if bins is not None else num_bins
    counts, xedges, yedges, Image = plt.hist2d(separations, forces,
                                               bins=bins_input,cmap=cmap)
    PlotUtilities.lazyLabel("Separation (nm)",
                            "Force (pN)",
                            title)
    if (use_colorbar): 
        cbar = plt.colorbar()
        label = '# of points in (Force,Separation) Bin'
        cbar.set_label(label,labelpad=10,rotation=270) 

def _n_rows_and_cols(processed,n_cols=3):
    n_rows = int(np.ceil(len(processed)/n_cols))    
    return n_rows,n_cols

def gallery_fec(processed,xlim_nm,ylim_pN,NFilterPoints=100,n_cols=3,
                x_label="Separation (nm)",y_label="Force (pN)",
                approach_label="Approach",
                retract_label="Retract"):
    n_rows,n_cols = _n_rows_and_cols(processed,n_cols)  
    for i,r in enumerate(processed):
        plt.subplot(n_rows,n_cols,(i+1))
        appr,retr = r
        is_labelled = i == 0
        is_first = (i % n_cols == 0)
        is_bottom = ((i + (n_cols)) >= len(processed))
        XLabel = x_label if is_bottom else ""
        YLabel = y_label      if is_first else ""
        ApproachLabel = approach_label if is_labelled else ""
        RetractLabel =  retract_label  if is_labelled else ""
        PlotLabelOpts = dict(ApproachLabel=ApproachLabel,
                             RetractLabel=RetractLabel)
        LegendOpts = dict(loc='upper left',frameon=True)
        FEC_AlreadySplit(appr,retr,XLabel=XLabel,YLabel=YLabel,
                         LegendOpts=LegendOpts,
                         PlotLabelOpts=PlotLabelOpts,
                         NFilterPoints=NFilterPoints)
        plt.xlim(xlim_nm)
        plt.ylim(ylim_pN)
        ax = plt.gca()
        if (not is_bottom):
            ax.tick_params(labelbottom='off')
        if (not is_first):
            ax.tick_params(labelleft='off')   
