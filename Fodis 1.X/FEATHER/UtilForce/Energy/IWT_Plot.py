# force floating point division. Can still use integer with //
from __future__ import division
# This file is used for importing the common utilities classes.
import numpy as np
import matplotlib.pyplot as plt
import sys

from UtilGeneral import PlotUtilities
import IWT_Util
from UtilForce.FEC import FEC_Util
from Code import InverseWeierstrass


def TomPlot(LandscapeObj,OutBase,UnfoldObj,RefoldObj,idx,f_one_half_N=0e-12):
    # get a forward and reverse
    ToX = lambda x: x * 1e9
    ToForceY = lambda y: y * 1e12
    fig = PlotUtilities.figure(figsize=(8,4))
    plt.subplot(1,2,1)
    SubplotArgs = dict(alpha=0.4,linewidth=0.5)
    FilterN = 500
    Unfold = FEC_Util.GetFilteredForce(UnfoldObj[idx],FilterN)
    Refold = FEC_Util.GetFilteredForce(RefoldObj[idx],FilterN)
    UnfoldX = ToX(Unfold.Extension)
    UnfoldY = ToForceY(Unfold.Force)
    FoldX = ToX(Refold.Extension)
    FoldY = ToForceY(Refold.Force)
    plt.plot(UnfoldX,UnfoldY,color='r',label="Unfolding",
             **SubplotArgs)
    plt.plot(FoldX,FoldY,color='b',label="Refolding",
             **SubplotArgs)
    fontdict = dict(fontsize=13)
    x_text_dict =  dict(x=60, y=22.5, s="2 nm", fontdict=fontdict,
                        withdash=False,
                        rotation="horizontal")
    y_text_dict =  dict(x=59, y=27, s="5 pN", fontdict=fontdict, withdash=False,
                        rotation="vertical")
    PlotUtilities.ScaleBar(x_kwargs=dict(x=[60,62],y=[24,24]),
                           y_kwargs=dict(x=[60,60],y=[25,30]),
                           text_x=x_text_dict,text_y=y_text_dict)
    PlotUtilities.legend(loc=[0.4,0.8],**fontdict)
    plt.subplot(1,2,2)
    Obj =  IWT_Util.TiltedLandscape(LandscapeObj,f_one_half_N=f_one_half_N)
    plt.plot(Obj.landscape_ext_nm,Obj.OffsetTilted_kT)
    plt.xlim([56,69])
    plt.ylim([-1,4])
    yoffset = 1
    x_text_dict =  dict(x=58.5, y=yoffset+1.5, s="2 nm", fontdict=fontdict,
                        withdash=False,rotation="horizontal")
    y_text_dict =  dict(x=57, y=yoffset+2.5, s=r"1 k$_\mathrm{b}$T",
                        fontdict=fontdict, withdash=False,
                        rotation="vertical")
    PlotUtilities.ScaleBar(x_kwargs=dict(x=[58,60],
                                         y=[yoffset+1.75,yoffset+1.75]),
                           y_kwargs=dict(x=[58,58],y=[yoffset+2,yoffset+3]),
                           text_x=x_text_dict,text_y=y_text_dict,
                           kill_axis=True)
    PlotUtilities.savefig(fig,OutBase + "TomMockup" + str(idx) + ".png",
                          subplots_adjust=dict(bottom=-0.1))
    # save out the data exactly as we want to plot it
    common = dict(delimiter=",")
    ext = str(idx) + ".txt"
    np.savetxt(X=np.c_[UnfoldX,UnfoldY],fname=OutBase+"Unfold" + ext,**common)
    np.savetxt(X=np.c_[FoldX,FoldY],fname=OutBase+"Fold"+ext,**common)
    np.savetxt(X=np.c_[Obj.landscape_ext_nm,Obj.OffsetTilted_kT],
               fname=OutBase+"Landscape"+ext,**common)

def plot_tilted_landscape(LandscapeObj,min_landscape_kT=None,
                          fmt_f_label="{:.0f}",
                          max_landscape_kT=None,f_one_half_N=10e-12,**kwargs):  
    Obj =  IWT_Util.TiltedLandscape(LandscapeObj,f_one_half_N=f_one_half_N,
                                    **kwargs)
    Obj.OffsetTilted_kT -= min(Obj.OffsetTilted_kT)
    plt.plot(Obj.landscape_ext_nm,Obj.OffsetTilted_kT,color='b',alpha=0.7)
    if (max_landscape_kT is None):
        max_landscape_kT = max(Obj.OffsetTilted_kT)*1.5
    if (min_landscape_kT is None):
        min_landscape_kT = np.percentile(Obj.OffsetTilted_kT,5)-2
    plt.ylim( min_landscape_kT,max_landscape_kT)
    ylabel = ("Tilted (F=" + fmt_f_label + "pN) [kT]").format(f_one_half_N*1e12)
    PlotUtilities.lazyLabel("Extension [nm]",ylabel,"",frameon=True)
    return format_kcal_per_mol_second_axis_after_kT_axis()    

def get_limit_kcal_per_mol(ax_kT):
    """
    Returns: kilocalorie per mol limits corresponding to given kT limits
    """
    ylim_kT = np.array(ax_kT.get_ylim())
    ylim_kcal_per_mol = IWT_Util.kT_to_kcal_per_mol() * ylim_kT         
    return ylim_kcal_per_mol
    
def _set_kcal_axis_based_on_kT(ax_kT,ax_kcal):    
    """
    sets the kilocalorie per mol axis based on the current limits of the
    kT axis
    
    Args:
        ax_<kT/kcal>: the axes to use
    Returns;
        nothing
    """
    ylim_kcal_per_mol = get_limit_kcal_per_mol(ax_kT)
    ax_kcal.set_ylim(ylim_kcal_per_mol)
    
def format_kcal_per_mol_second_axis_after_kT_axis():
    """
    formats a second, kcal/mol axis after plotting kT data 
    """
    ax_kT = plt.gca()
    ylim_kcal_per_mol = get_limit_kcal_per_mol(ax_kT)
    ax_kcal = PlotUtilities.secondAxis(ax=ax_kT,label="Energy (kcal/mol)",
                                       limits=ylim_kcal_per_mol,color='b',
                                       secondY=True)
    _set_kcal_axis_based_on_kT(ax_kT,ax_kcal)
    plt.sca(ax_kT)                       
    return ax_kcal

    
def plot_free_landscape(LandscapeObj,**kwargs):
    """
    plots a free landscape version extension
    
    Args:
        LandscapeObj: see plot_single_landscape
        kwargs: passed to TiltedLandscape
    Returns: 
        tilted landscape  
    """
    Obj =  IWT_Util.TiltedLandscape(LandscapeObj,**kwargs)
    plt.plot(Obj.landscape_ext_nm,Obj.Landscape_kT)
    range = max(Obj.Landscape_kT) - min(Obj.Landscape_kT)
    fudge = range/10
    plt.ylim([-fudge,np.max(Obj.Landscape_kT)+fudge])
    PlotUtilities.lazyLabel("","Landscape at F=0 [kT]","",frameon=True)
    format_kcal_per_mol_second_axis_after_kT_axis()    
    return Obj
                            
def plot_single_landscape(LandscapeObj,**kwargs):
    """
    Plots a detailed energy landscape, and saves

    Args:
        LandscapeObj: energy landscape object (untilted)
        **kwargs: passed to plot_tilted_landscape
    Returns:
        second, kcal/mol axis of tilted landscape 
    """                          
    plt.subplot(2,1,1)
    plot_free_landscape(LandscapeObj,**kwargs)  
    plt.subplot(2,1,2)
    to_ret = plot_tilted_landscape(LandscapeObj,**kwargs)
    PlotUtilities.xlabel("Extension (nm)")
    return to_ret
                            
def InTheWeedsPlot(OutBase,UnfoldObj,RefoldObj=[],Example=None,
                   Bins=[50,75,100,150,200,500,1000],**kwargs):
    """
    Plots a detailed energy landscape, and saves

    Args:
        OutBase: where to start the save
        UnfoldObj: unfolding objects
        RefoldObj: refolding objects
        Bins: how many bins to use in the energy landscape plots
        <min/max>_landscape_kT: bounds on the landscape
    Returns:
        nothing
    """
    # get the IWT
    kT = 4.1e-21
    for b in Bins:
        LandscapeObj =  InverseWeierstrass.\
            FreeEnergyAtZeroForce(UnfoldObj,NumBins=b,RefoldingObjs=RefoldObj)
        # make a 2-D histogram of everything
        if (Example is not None):
            fig = PlotUtilities.figure(figsize=(8,8))
            ext_nm = Example.Separation*1e9
            IWT_Util.ForceExtensionHistograms(ext_nm,
                                              Example.Force*1e12,
                                              AddAverage=False,
                                              nBins=b)
            PlotUtilities.savefig(fig,OutBase + "0_{:d}hist.pdf".format(b))
        # get the distance to the transition state etc
        print("DeltaG_Dagger is {:.1f}kT".format(Obj.DeltaGDagger))
        fig = PlotUtilities.figure(figsize=(12,12))
        plot_single_landscape(LandscapeObj,add_meta_half=True,
                              add_meta_free=True,**kwargs)
        PlotUtilities.savefig(fig,OutBase + "1_{:d}IWT.pdf".format(b))

