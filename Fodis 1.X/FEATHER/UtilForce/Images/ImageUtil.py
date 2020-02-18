# force floating point division. Can still use integer with //
from __future__ import division
# This file is used for importing the common utilities classes.
import numpy as np
import matplotlib.pyplot as plt
import sys

from ..FEC import FEC_Util
from ..UtilIgor import PxpLoader,ProcessSingleWave
from ..UtilGeneral import GenUtilities,PlotUtilities
from mpl_toolkits.axes_grid1 import make_axes_locatable

def line_background(image,deg=3,**kw):
    """
    :param image: original, to correct
    :param deg:  polynomial to subtract from each *row* of image
    :param kw:
    :return: array, polynomial fit to each row of image
    """
    to_ret = np.zeros_like(image)
    shape = to_ret.shape
    coords = np.arange(shape[1])
    n_rows = shape[0]
    for i in range(n_rows):
        raw_row = to_ret[i,:]
        coeffs = np.polyfit(x=coords,y=raw_row,deg=deg,**kw)
        corr = np.polyval(coeffs,x=coords)
        to_ret[i,:] = corr
    return to_ret

def subtract_background(image,deg=3,**kwargs):
    """
    subtracts a line of <deg> from each row in <images>
    """
    corr = line_background(image,deg=deg,**kwargs)
    return image - corr

def read_images_in_pxp_dir(dir,**kwargs):
    """
    Returns: all SurfaceImage objects from all pxps in dir
    """
    pxps_in_dir = GenUtilities.getAllFiles(dir,ext=".pxp")
    return [image
            for pxp_file in pxps_in_dir 
            for image in PxpLoader.ReadImages(pxp_file,**kwargs)]
    

def cache_images_in_directory(pxp_dir,cache_dir,**kwargs):
    """
    conveniewnce wrapper. See FEC_Util.cache_individual_waves_in_directory, 
    except for images 
    """
    load_func = read_images_in_pxp_dir
    to_ret = FEC_Util.cache_individual_waves_in_directory(pxp_dir,cache_dir,
                                                          load_func=load_func,
                                                          **kwargs)
    return to_ret                                                  
    
def smart_colorbar(im,ax=plt.gca(),fig=plt.gcf(),
                   divider_kw=dict(size="5%",pad=0.1),
                   label="Height (nm)",add_space_only=False):
    """
    Makes a color bar on the given axis/figure by moving the axis over a little 
    """    
    # make a separate axis for the colorbar 
    divider = make_axes_locatable(ax)
    cax = divider.append_axes("right", size="5%", pad=0.1)
    if (not add_space_only):
        to_ret = PlotUtilities.colorbar(label,fig=fig,
                               bar_kwargs=dict(mappable=im,cax=cax))
        return to_ret
    else:
        cax.axis('off')
        return None

    
def make_image_plot(im,imshow_kwargs=dict(cmap=plt.cm.afmhot),pct=50):
    """
    Given an image object, makes a sensible plot 
    
    Args:
        im: PxpLoader.SurfaceImage object
        imshow_kwargs: passed directly to plt.imshow 
        pct: where to put 'zero' default to median (probably the surface
    Returns:
        output of im_show
    """
    # offset the data
    im_height = im.height_nm()
    min_offset = np.percentile(im_height,pct)
    im_height -= min_offset
    range_microns = im.range_meters * 1e6
    to_ret = plt.imshow(im_height.T,extent=[0,range_microns,0,range_microns],
                        interpolation='bicubic',**imshow_kwargs)
    PlotUtilities.tom_ticks()
    micron_str = PlotUtilities.upright_mu("m")
    PlotUtilities.lazyLabel(micron_str,micron_str,"",
                            tick_kwargs=dict(direction='out'))    
    return to_ret                                 
