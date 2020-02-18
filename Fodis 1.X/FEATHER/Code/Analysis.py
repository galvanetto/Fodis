# force floating point division. Can still use integer with //
from __future__ import division
# This file is used for importing the common utilities classes.
import numpy as np
import matplotlib.pyplot as plt
import sys,warnings,copy
from scipy import interpolate
from scipy.stats import norm
from scipy.ndimage.filters import uniform_filter1d,generic_filter1d
from scipy.integrate import cumtrapz

min_tau_num_points = 4

class simple_fec:
    def __init__(self,time,z_sensor,separation,force,trigger_time,
                 dwell_time,events=[]):
        self.Time = time
        self.ZSnsr = z_sensor
        self.Separation = separation
        self.Force = force
        self.TriggerTime = trigger_time
        self.DwellTime = dwell_time
        self.Events = events
    def _slice(self,slice_v):
        s = lambda x: x[slice_v].copy()
        return simple_fec(time=s(self.Time),
                          z_sensor=s(self.ZSnsr),
                          separation=s(self.Separation),
                          force=s(self.Force),
                          trigger_time=self.TriggerTime,
                          dwell_time=self.DwellTime,
                          events=self.Events)

class split_force_extension(object):
    """
    class representing a force-extension curve, split into approach, dwell,
    and retract
    """
    def __init__(self,approach,dwell,retract,tau_num_points=None):
        self.approach = approach
        self.dwell = dwell
        self.retract = retract
        self.set_tau_num_points(tau_num_points)
        self.retract_knots = None
        self.epsilon = None
        self.sigma = None
    def set_retract_knots(self,interpolator):
        """
        sets the retract knots; useful for gridding data
        """
        self.retract_knots = interpolator.get_knots()
    def get_epsilon_and_sigma(self):
        return self.epsilon,self.sigma
    def set_espilon_and_sigma(self,epsilon,sigma):
        self.epsilon =epsilon
        self.sigma = sigma
    def set_approach_metrics(self,slice_to_fit,interpolator):
        self.cached_approach_interpolator = interpolator
        self.cached_approach_slice_to_fit = slice_to_fit
    def _approach_metrics(self,tau_n=None,slice_fit_approach=None):
        if (tau_n is None):
            tau_n = self.tau_num_points_approach
        if (slice_fit_approach is None):
            approach_surface_idx = self.get_predicted_approach_surface_index()
            slice_fit_approach= slice(0,approach_surface_idx,1)
        spline_fit_approach = \
            self.approach_spline_interpolator(slice_to_fit=slice_fit_approach)
        approach = self.approach
        approach_time_fit = approach.Time[slice_fit_approach]
        approach_force_sliced = approach.Force[slice_fit_approach]
        approach_force_interp_sliced = spline_fit_approach(approach_time_fit)
        # get the residual properties of the approach
        stdevs,epsilon,sigma = \
            stdevs_epsilon_sigma(approach_force_sliced,
                                 approach_force_interp_sliced,n=2*tau_n)
        return stdevs,epsilon,sigma,slice_fit_approach,spline_fit_approach
    def stdevs_epsilon_and_sigma(self,**kwargs):
        stdevs,epsilon,sigma,slice_fit_approach,spline_fit_approach = \
           self._approach_metrics(**kwargs)
        return stdevs,epsilon,sigma
    def retract_spline_interpolator(self,slice_to_fit=None,knots=None,**kwargs):
        """
        returns an interpolator for force based on the stored time constant tau
        for the retract force versus time curbe

        Args:
            slice_to_fit: which part of the retract to fit
            knots: where to put the spline knots. if none, defaults to
            self.retract_knots (which could also be none; then just uniform)
            
            kwargs: passed to spline_interpolator
        """
        if (slice_to_fit is None):
            slice_to_fit = slice(0,self.retract.Time.size-1,1)
        if knots is None:
            knots = self.retract_knots
        if (knots is not None):
            # POST: actually have some knots; find the ones we can use
            x = self.retract.Time
            start = slice_to_fit.start
            stop = slice_to_fit.stop
            if stop is None:
                stop = -1
            condition = ((knots >= x[start]) & (knots <= x[stop]))
            good_idx = np.where(condition)[0]
            if (good_idx.size  == 0):
                err_str = "No valid knots! Analysis.retract_spline_interpolator"
                warnings.warn(err_str, DeprecationWarning)
                # give up on whatever we were trying to do 
                knots = None
            else:
                knots = knots[good_idx]
        return spline_fit_fec(self.tau,self.retract,slice_to_fit=slice_to_fit,
                              knots=knots,**kwargs)
    def approach_spline_interpolator(self,slice_to_fit=None,**kwargs):
        """
        See retract_spline_interpolator, but for the approach
        """
        tau_approach = self.tau_num_points_approach*self.dt
        return spline_fit_fec(tau_approach,self.approach,
                              slice_to_fit=slice_to_fit,**kwargs)        
    def retract_separation_interpolator(self,**kwargs):
        """
        returns an interpolator for separation based on the stored time
        constant tau for the retract force versus time curbe

        Args:
            kwargs: passed to spline_interpolator
        """    
        x,f = self.retract.Time,self.retract.Separation
        return spline_interpolator(self.tau,x,f,**kwargs)
    def set_tau_num_points_approach(self,tau_num_points):
        """
        sets the approach number of points for tau (may be different 
        due to different loading rates, etc)

        Args:
            tau_num_points: number of points to use
        Returns:
            nothing, sets tau appropriately
        """
        self.tau_num_points_approach = max(min_tau_num_points,tau_num_points)
    def set_tau_num_points(self,tau_num_points):
        """
        sets the autocorrelation time associated with this curve
        
        Args:
            tau_num_points: integer number of points
        Returns:
            Nothing
        """
        # for the purpose of smoothing, tau must be a certain size
        if (tau_num_points is not None):
            self.tau_num_points = max(min_tau_num_points, tau_num_points)
            # we assume the rate of time sampling is  the same everywhere
            self.dt = np.median(np.abs(np.diff(self.approach.Time)))
            self.tau = self.dt*self.tau_num_points
        else:
            self.tau = None
    def zero_retract_force(self,offset):
        self.retract.Force -= offset
    def zero_all(self,separation,zsnsr,force,force_retract):
        """ 
        zeros the distance and force of the approach,dwell, and retract
        
        Args:
            separation,zsnsr,force: offsets in their respective categories
        """
        self.approach.offset(separation,zsnsr,force)
        self.dwell.offset(separation,zsnsr,force)
        self.retract.offset(separation,zsnsr,force_retract)
    def flip_forces(self):
        """
        multiplies all the forces by -1; useful after offsetting
        """
        self.approach.Force *= -1
        self.dwell.Force *= -1
        self.retract.Force *= -1
    def n_points_approach_dwell(self):
        """
        Returns:
            the number of points in the approach and dwell curves
        """
        return self.approach.Force.size + self.dwell.Force.size
    def get_retract_event_idx(self):
        """
        gets the slices of events *relative to the retract* (ie: idx 0 is
        the first point in the retract curve)
        
        Returns:
            list, each element is a slice like (start,stop,1) where start and   
            stop are the event indices
        """
        offset = self.n_points_approach_dwell() 
        # each event is a start/end tuple, so we just offset the min and max
        idx = [ slice(min(ev)-offset,max(ev)-offset,1) 
                for ev in self.retract.Events]
        return idx
    def has_events(self):
        return len(self.retract.Events) > 0 
    def get_retract_event_slices(self):
        event_idx_retract = self.get_retract_event_centers()
        starts = [0] + event_idx_retract
        ends = event_idx_retract + [None]
        slices = [slice(i,f,1) for i,f in zip(starts,ends)]
        return slices
    def get_retract_event_starts(self):
        """
        get the start to all the events
        """
        return [ i.start for i in self.get_retract_event_idx()]
    def get_retract_event_centers(self):
        """
        Returns:
            the mean of the event start and stop (its 'center')
        """
        get_mean = lambda ev: int(np.round(np.mean([ev.start,ev.stop]) ))
        return [ get_mean(ev) for ev in  self.get_retract_event_idx()]
    def surface_distance_from_trigger(self):
        """
        returns the distance in separtion units from the trigger point
        """
        return abs(min(self.approach.Separation))
    def get_predicted_approach_surface_index(self):
        """
        returns the predicted place the surface is on the approach
        """    
        return np.where(self.approach.Force >0)[0][-1]
    def get_predicted_retract_surface_index(self):
        """
        Assuming this have been zeroed, get the predicted retract surface index
        """
        approach_idx = self.get_predicted_approach_surface_index()
        # how far is the surface from the approach, in Z?
        dZ_surface = self.approach.Zsnsr[-1] - self.approach.Zsnsr[approach_idx]
        dZ_needed = abs(dZ_surface)
        # return the first time the retract is above the surface Z
        dZ_retract = np.abs(self.retract.ZSnsr - self.retract.ZSnsr[0])
        where_retract_above_surface = np.where(dZ_retract >= dZ_needed)[0]
        assert where_retract_above_surface.size > 0 , \
            "Couldn't find surface in retract. Z_retract never reached surface."
        # return the first time we are above the surface Z...
        return where_retract_above_surface[0]

def _index_surface_relative(x,offset_needed):
    """
     returns a crude estimate for  the predicted index offset for the surface
        
    Args:
        x: the time series of separation
        offset_needed: the x offset 
    Returns: 
        number of points for x to displace by offset_needed
    """    
    sep_diff = np.median(np.abs(np.diff(x)))
    n = int(np.ceil(offset_needed/sep_diff))
    return n
        
def spline_fit_fec(tau,time_sep_force,slice_to_fit=None,**kwargs):
    """
    returns an interpolator object on the given TimeSepForce object
     
    Args:
        tau: see spline_interpolator
        time_sep_force: get t he time and force from this as x,y to 
        spline_interpolator
        
        slice_to_fit: part of x,f to fit
        **kwargs: passed to spline_interpolator
    returns:
        see spline_interpolator
    """    
    x,f = time_sep_force.Time,time_sep_force.Force
    if (slice_to_fit is None):
        slice_to_fit = slice(0,None,1)
    return spline_interpolator(tau,x[slice_to_fit],f[slice_to_fit],
                               **kwargs)        
        
def local_integral(y,n,mode='reflect'):
    """
    gets the integral of y_i from -n to n (total of 2*n points)

    Args:
        y: to integrate
        n: window size (in either direction)
        mode: see cumtrapz
    Returns:
        array, same size as y, of the centered integral (edges are 
        clamped in integral centering)
    """
    cumulative_integral = cumtrapz(y=y, dx=1.0, axis=-1, initial=0)
    return local_centered_diff(cumulative_integral,n)

def local_centered_diff(y,n):
    """
    return the local centered difference: y[n]-y[-n], with zeros at the 
    boundaries points (ie 0 and y.size-1), 

    Args:
        y: to get the centered diff of
        n: the size of the window
    Returns:
        array a, same size as y, where a[i] = y[min(i,y.size-1)]-y[max(0,i)]
    """
    # get the 'initial' points. this is the first point for the first n,
    # then the remainder of the array (eg: y[n] has an initial of y[0],
    #  y[n+1] has an initial of y[1], but y[0] has an initial of y[0]
    yi = np.zeros(y.size)
    yi[:n] = y[0]
    yi[n:] = y[:-n]
    # ibid, except the final points. y[0] gets y[n], y[n] gets y[n]
    yf = np.zeros(y.size)
    yf[-n:] = y[-1]
    yf[:-n] = y[n:]
    return yf-yi

def local_average(f,n,size=None,origin=None,mode='reflect'):
    """
    get the local, windowed function of the average, +/- n

    Args:
        f: what we want the stdev of
        n: window size (in either direction)
        mode: see uniform_filter1d
    Returns:
        array, same size as f, with the dat we want
    """
    if (size is None):
        size = 2*n
    if (origin is None):
        origin = 0
    return uniform_filter1d(f, size=size, mode=mode, origin=origin)

def local_stdev(f,n):
    """
    Gets the local standard deviaiton (+/- n), except at boundaries 
    where it is just in the direction with data

    Args:
        f: what we want the stdev of
        n: window size (in either direction)
    Returns:
        array, same size as f, with the dat we want
    """
    max_n = f.size
    # go from (i-n to i+n)
    """
    for linear stdev, see: 
    stackoverflow.com/questions/18419871/
    improving-code-efficiency-standard-deviation-on-sliding-windows
    """
    mode = 'reflect'
    c1 = local_average(f,n)
    c2 = local_average(f*f,n)
    # sigma^2 = ( <x^2> - <x>^2 )^(1/2), shouldnt dip below 0
    safe_variance = np.maximum(0,c2 - c1*c1)
    stdev = (safe_variance**.5)
    return stdev


def filter_fec(obj,n_points):
    to_ret = copy.deepcopy(obj)
    if (n_points > 1):
        to_ret.Force = spline_interpolated_by_index(obj.Force,n_points)
        to_ret.Separation = spline_interpolated_by_index(obj.Separation,n_points)
        to_ret.ZSnsr = spline_interpolated_by_index(obj.ZSnsr,n_points)
    return to_ret

def bc_coeffs_load_force_2d(loading_true,loading_pred,bins_load,
                            ruptures_true,ruptures_pred,bins_rupture):
    """
    returns the bhattacharya coefficients for the distriutions of the loading
    rate, rupture force, and 2-d version

    Args:
        <x>_<true/pred>: the list of <x> values that are ground truth or 
        predicted

        bins<x>: for histogramming
    Return:
        three-tuple of BC coefficient (between 0 and 1)for the distributions of
        loading rate, rupture force, and their 2-tuple 
    """
    coeff_load = bhattacharyya_probability_coefficient_1d(loading_true,
                                                          loading_pred,
                                                          bins_load)
    coeff_force = bhattacharyya_probability_coefficient_1d(ruptures_true,
                                                           ruptures_pred,
                                                           bins_rupture)
    # do a 2-d coefficient
    tuple_true = [loading_true,ruptures_true]
    tuple_pred = [loading_pred,ruptures_pred]
    tuple_bins = [bins_load,bins_rupture]
    coeff_2d = bhattacharyya_probability_coefficient_dd(tuple_true,tuple_pred,
                                                        tuple_bins)
    coeffs = [coeff_load,coeff_force,coeff_2d]
    return coeffs

def bhattacharyya_probability_coefficient_1d(v1,v2,bins):
    """
    # return the bhattacharyya distance between two 1-d arras

    Args:
        v<1/2>: see  bhattacharyya_probability_coefficient_dd, except 1-D      
        bins: how to bin them, see 
    Returns:
        bhattacharyya distance, see bhattacharyya_probability_coefficient
    """
    return bhattacharyya_probability_coefficient_dd(v1,v2,[bins])

def bhattacharyya_probability_coefficient_dd(v1,v2,bins,normed=False):
    """
    # return the bhattacharyya distance between arbitrary-dimensional
    #probabilities, see  bhattacharyya_probability_coefficient

    Args:
        v<1/2>: two arbitrary-dimensional lists to compare
        bins: how to bin them
    Returns:
        bhattacharyya distance, see bhattacharyya_probability_coefficient
    """
    histogram_kwargs = dict(bins=bins,weights=None,normed=normed)
    v1_hist,v1_edges = np.histogramdd(sample=v1,**histogram_kwargs)
    v2_hist,v2_edges = np.histogramdd(sample=v2,**histogram_kwargs)
    return bhattacharyya_probability_coefficient(v1_hist,v2_hist)

def div0(a,b,replace_div_0=0):
    """
    divide a by b, replacing any diviede by zero with repalace_div_0

    Args:
        a: numerator 
        b: denom
        replace_div_0: what to replace the value with if we divide by zero
    """
    with np.errstate(divide='ignore', invalid='ignore'):
        c = np.true_divide( a, b )
        c[~np.isfinite( c )] = replace_div_0  # -inf inf NaN
    return c

def bhattacharyya_probability_coefficient(v1_hist,v2_hist):
    """
    # return the bhattacharyya distance between the probabilities, see:
    # https://en.wikipedia.org/wiki/Bhattacharyya_distance

    Args:
        v<1/2>_hist: values of two ditributions in each bins
    Returns:
        bhattacharyya distance
    """
    v1_hist = v1_hist.flatten()
    v2_hist = v2_hist.flatten()
    # if we divide by zero, then one of the probabilities was all zero -- ignore
    p1 = v1_hist/sum(v1_hist)
    p2 = v2_hist/sum(v2_hist)
    prod = p1 * p2
    return sum(np.sqrt(prod))
    
def stdevs_epsilon_sigma(y,interpolated_y,n):
    # get a model for the local standard deviaiton
    diff = y-interpolated_y
    stdevs = local_stdev(diff,n)
    sigma = np.std(stdevs)
    epsilon = np.median(stdevs)
    return stdevs,epsilon,sigma

def _surface_index(filtered_y,y,last_less_than=True):
    """
    Get the surface index
    
    Args:
        y: the y we are searching for the surface of (raw)
        filtered_y: the filtered y value
        n_smooth: number to smoothing   
        last_less_than: if true (default, 'raw' data), then we find the last
        time we are less than the baseline in obj.Force. Otherwise, the first
        time we are *greater* than...
    Returns 
        the surface index and baseline in force
    """
    median = np.median(y)
    lt = np.where(y < median)[0]
    # determine the last time we were less than the median;
    # use this as a marker between the invols and the surface region
    last_lt = lt[-1]
    x = np.arange(start=0,stop=y.size,step=1)
    x_approach = x[:last_lt]
    x_invols = x[last_lt:]
    coeffs_approach = np.polyfit(x=x_approach,y=y[:last_lt],deg=1)
    coeffs_invols = np.polyfit(x=x_invols,y=y[last_lt:],deg=1)
    pred_approach = np.polyval(coeffs_approach,x=x)
    pred_invols = np.polyval(coeffs_invols,x=x)
    surface_idx = np.argmin(np.abs(pred_approach-pred_invols))
    # iterate to get the final surface touchoff ; where is the filtered
    # version less than the line?
    where_touch = np.where( (x <= surface_idx) & 
                            (filtered_y <= pred_approach))[0]
    if (where_touch.size > 0):
        surface_idx = where_touch[-1]
    # the final baseline is just the value of the approach
    median = pred_approach[surface_idx]
    return median,surface_idx

def get_surface_index(obj,n,last_less_than=True):
    """
    Get the surface index
    
    Args:
        see _surface_index
    Returns 
        see _surface_index, except last (extra) tuple element is filtered
        obj 
    """
    filtered_obj = filter_fec(obj,n)
    baseline,idx = _surface_index(filtered_obj.Force,obj.Force,
                                  last_less_than=last_less_than)
    return baseline,idx,filtered_obj

def zero_by_approach(split_fec,tau_n_approach,flip_force=True):
    """
    zeros out (raw) data, using n_smooth points to do so 
    
    Args:
        split_fec: instead of split_force_extension
        n_smooth: number of points for smoothing
        flip_force: if true, multiplies the zeroed force by -1
    Returns:
        nothing, but modifies split_fec to be zerod appropriately. 
    """
    # PRE: assume the approach is <50% artifact and invols
    approach = split_fec.approach
    force_baseline,idx_surface,filtered_obj = \
        get_surface_index(approach,n=2*tau_n_approach,last_less_than=True)
    idx_delta = approach.Force.size-idx_surface
    # get the separation at the baseline
    separation_baseline = filtered_obj.Separation[idx_surface]
    zsnsr_baseline = filtered_obj.Zsnsr[idx_surface]
    """
    plt.subplot(2,1,1)
    plt.plot(approach.Force,alpha=0.3)
    plt.plot(filtered_obj.Force)
    plt.axvline(idx_surface)
    plt.subplot(2,1,2)
    plt.plot(split_fec.retract.Force)
    plt.show()     
    """
    # zero everything 
    split_fec.zero_all(separation_baseline,zsnsr_baseline,force_baseline,
                       force_baseline)
    if (flip_force):
        split_fec.flip_forces()
   
   
def slice_func_fec(fec,slice_v):
    """
    makes a copy of the fec, slicing the data fields to slice_v

    Args:
        fec: the force-extension curve to use
        slice_v: the slice of fec to get
    Returns:
        the sliced version of fec
    """
    to_ret = fec._slice(slice_v)
    return to_ret
        
def split_FEC_by_meta(time_sep_force_obj):
    """
    given a time_sep_force object, splits it into approach, retract, and dwell
    by the meta information
        
    Args:
        time_sep_force_obj: whatever object to split, should have triggertime
        and dwelltime 
    Returns:
        scipy.interpolate.LSQUnivariateSpline object, interpolating f on x
    """
    start_of_dwell_time = time_sep_force_obj.TriggerTime
    end_of_dwell_time = start_of_dwell_time + \
                        time_sep_force_obj.SurfaceDwellTime
    get_idx_at_time = lambda t: np.argmin(np.abs(time_sep_force_obj.Time-t))
    start_of_dwell = get_idx_at_time(start_of_dwell_time)
    end_of_dwell = get_idx_at_time(end_of_dwell_time)
    # slice the object into approach, retract, dwell
    slice_func = lambda s:  slice_func_fec(time_sep_force_obj,s)
    approach = slice_func(slice(0             ,start_of_dwell,1))
    dwell    = slice_func(slice(start_of_dwell,end_of_dwell  ,1))
    retract  = slice_func(slice(end_of_dwell  ,None          ,1))
    retract.Events = time_sep_force_obj.Events
    """
    plt.plot(approach.Time,approach.Force)
    plt.plot(dwell.Time,dwell.Force)
    plt.plot(retract.Time,retract.Force)
    print(start_of_dwell,end_of_dwell)
    plt.show()
    """
    return split_force_extension(approach,dwell,retract)

def spline_residual_mean_and_stdev(f,f_interp,start_q=1):
    """
    returns the mean and standard deviation associated with f-f_interp,
    from start_q% to 100-startq%
    
    Args:
        f: the 'noisy' function
        f_interp: the interpolated f (splined)
        start_q: the start perctile; we have to ignore huge outliers
    Returns:
        tuple of mean,standard deviation
    """
    # symetrically choose percentiles for the fit
    f_minus_mu = f-f_interp
    qr_1,qr_2 = np.percentile(a=f_minus_mu,q=[start_q,100-start_q])
    idx_fit = np.where( (f_minus_mu >= qr_1) &
                        (f_minus_mu <= qr_2))
    # fit a normal distribution to it, to get the standard deviation (globally)
    mu,std = norm.fit(f_minus_mu[idx_fit])
    return mu,std
    
def spline_gaussian_cdf(f,f_interp,std):
    """
    returns the CDF associated with the random variable with mean given by  
    f_interp and standard deviation associated with std, assuming gaussian
    about f-finterp
    
    Args:
        f: see spline_residual_mean_and_stdev
        f_interp: see spline_residual_mean_and_stdev
        std: standard deviation
    Returns:
        cummulative distribution
    """
    # get the distribution of the actual data
    distribution_force = norm(loc=f_interp, scale=std)
    # get the cdf of the data
    return distribution_force.cdf(f)
    
def spline_interpolated_by_index(f,nSmooth,**kwargs):
    """
    returnsa spline interpolator of f versus 0,1,2,...,(N-1)
    
    Args:
        f: function to interpolate
        nSmooth: distance between knots (smoothing number)
        **kwargs: passed to spline_interpolator
    Returns: 
        spline interpolated value of f on the indices (*not* an interpolator
        object, just an array) 
    """
    x,interp = spline_interpolator_by_index(f,nSmooth,**kwargs)
    return interp(x)
    
def spline_interpolator_by_index(f,n_smooth,**kwargs):
    """
    see spline_interpolated_by_index. except returns tuple of <x,interpolator
    object>
    
    Args:
        see spline_interpolated_by_index
    Returns: 
        see spline_interpolated_by_index 
    """
    x = np.arange(start=0,stop=f.size,step=1)
    return x,spline_interpolator(n_smooth,x,f,**kwargs)

def spline_interpolator(tau_x,x,f,knots=None,deg=2):
    """
    returns a spline interpolator with knots uniformly spaced at tau_x over x
    
    Args:
        tau_x: the step size in whatever units of c
        x: the unit of 'time'
        f: the function we want the autocorrelation of
        knots: the locations of the knots (default to uniform in x)
        deg: the degree of the spline interpolator to use. continuous to 
        deg-1 derivative
    Returns:
        scipy.interpolate.LSQUnivariateSpline object, interpolating f on x
    """
    # note: stop is *not* included in the iterval, so we add an extra step 
    # to make it included
    if (knots is None):
        step_knots = tau_x
        min_x,max_x = min(x), max(x)
        knots = np.linspace(start=min_x,stop=max_x,
                            num=np.ceil((max_x-min_x)/step_knots),
                            endpoint=True)
    # get the spline of the data
    spline_args = \
        dict(
            # degree is k, (k-1)th derivative is continuous
            k=deg,
            # specify the spline knots (t) uniformly in time at the 
            # autocorrelation time. dont want the endpoints
            t=knots[1:-1]
            )
    return interpolate.LSQUnivariateSpline(x=x,y=f,**spline_args)

def auto_correlation_helper(auto):
    # normalize the auto correlation, add in a small bias to avoid 
    # taking the log of 0. data is normalized to 0->1, so it should be OK
    tol = 1e-9
    # auto norm goes from 0 to 1
    auto_norm = (auto - np.min(auto))/(np.max(auto)-np.min(auto)) 
    auto_median_normed = auto_norm - np.median(auto_norm)
    # statistical norm goes from -1 to 1
    statistical_norm = (auto_norm - 0.5) * 2
    log_norm = np.log(auto_norm + tol)
    fit_idx_max = np.where(auto_median_normed < 0.25)[0]
    assert fit_idx_max.size > 0 , "autocorrelation doesnt dip under threshold"
    # get the first time we cross under the threshold
    fit_idx_max =  fit_idx_max[0]
    return auto_norm,statistical_norm,log_norm,fit_idx_max
    
def auto_correlation_tau(x,f_user,deg_autocorrelation=1,
                         autocorrelation_skip_points=None,fit_idx_max=None):
    """
    get the atucorrelation time of f (ie: fit polynomial to log(autocorrelation)
    vs x, so the tau is more or less the exponential decay constant
    
    Args:
        x: the unit of 'time'
        f_user: the function we want the autocorrelation of 
        deg_autocorrelation: the degree of autocorrelation to use. defaults to  
        linear, to get the 1/e time of autocorrelation
        
        fit_idx_max: maximum index to fit. defaults to until we hit 0 in
        the statistical autocorrelation 
    Returns:
        tuple of <autocorrelation tau, coefficients of log(auto) vs x fit,
                  auto correlation ('raw')>
    """
    f = f_user - np.mean(f_user)
    auto = np.correlate(f,f,mode='full')
    # only want the last half (should be identical?) 
    size = int(auto.size/2)
    auto = auto[size:]
    if (autocorrelation_skip_points is not None):
        auto = auto[autocorrelation_skip_points:]
    auto_norm,statistical_norm,log_norm,fit_idx_max_tmp = \
        auto_correlation_helper(auto)
    if fit_idx_max is None:
        fit_idx_max = fit_idx_max_tmp
    # git a high-order polynomial to the auto correlation spectrum, get the 1/e
    # time.
    coeffs = np.polyfit(x=x[:fit_idx_max],y=log_norm[:fit_idx_max],
                        deg=deg_autocorrelation)
    # get just the linear and offset
    linear_auto_coeffs = coeffs[-2:]
    # get tau (coefficient in the exponent, y=A*exp(B*t), so tau=1/B
    # take the absolute value, since tau is a decay, has a minus 
    tau = abs(1/linear_auto_coeffs[0])
    return tau,coeffs,auto

def _zero_fec(example_split,fraction,flip_force=True):
    approach = example_split.approach
    retract = example_split.retract
    f = approach.Force
    x = approach.Time
    n_approach = f.size
    n_retract = retract.Force.size
    # allow for different velocities and offsets between approach and retract
    dZ_appr = max(approach.ZSnsr) - min(approach.ZSnsr)
    dZ_retr = max(retract.ZSnsr) - min(retract.ZSnsr)
    dZ_ratio = dZ_retr / dZ_appr
    num_points_approach = int(np.ceil(n_approach * fraction * dZ_ratio))
    num_points_retract = int(np.ceil(n_retract * fraction))
    # zero out everything to the approach using the autocorrelation time
    zero_by_approach(example_split, tau_n_approach=num_points_approach,
                     flip_force=flip_force)
    example_split.set_tau_num_points(num_points_retract)
    example_split.set_tau_num_points_approach(num_points_approach)
    return example_split

def zero_and_split_force_extension_curve(example,fraction=0.02):
    """
    zeros a force extension curve by its meta information and the touchoff
    on the approach

    Args:
        example: 'raw' force extension to use (negative force is away
        from surface on molecule)
        fraction: the portion of the curve to use for smoothing
    returns:
        example as an Analysis.split_force_extension object
    """
    example_split = split_FEC_by_meta(example)
    to_ret =  _zero_fec(example_split,fraction)
    return to_ret

def _loading_rate_helper(x,y):
    if (x.size < 2):
        raise IndexError("Can't fit a line to something with <2 points")
    coeffs = np.polyfit(y=y,x=x,deg=1)
    predicted = np.polyval(coeffs,x=x)
    loading_rate, _ = coeffs
    # determine the last time the *data* is above the prediction
    where_above = np.where(y > predicted)[0]
    if (where_above.size == 0):
        # unlikely but worth checking
        last_idx_above = np.argmax(y)
    else:
        last_idx_above = where_above[-1]
    # determine what we *predict* to be the value at that point
    rupture_force = predicted[last_idx_above]
    return coeffs,predicted,loading_rate,rupture_force,last_idx_above

def loading_rate_rupture_force_and_index(time,force,slice_to_fit):
    """
    given a portion of time and force to fit, the loading rate is determined 
    by the local slope. The rupture force is determined by finding the last
    time the (XXX should use two lines in case of flickering)
    
    Args:
        time/force: should be self-explanatory. Force should be zeroed.
        slice_to_fit: where we are fitting
    Returns:
        tuple of <loading rate,rupture force,index_of_rupture>
    """
    x = time[slice_to_fit]
    y = force[slice_to_fit]
    # XXX can fit a line, throw an error?
    _,_,loading_rate,rupture_force,last_idx_above = \
        _loading_rate_helper(x,y)
    return loading_rate,rupture_force,last_idx_above
    
def get_before_and_after_and_zoom_of_slice(split_fec):
    event_idx_retract = split_fec.get_retract_event_centers()
    index_before = [0] + [e for e in event_idx_retract]
    index_after = [e for e in event_idx_retract] + [None]
    slices_before = [slice(i,f,1) 
                     for i,f in zip(index_before[:-1],index_after[:-1])]
    slices_after = [slice(i,f,1) 
                     for i,f in zip(index_before[1:],index_after[1:])]
    return slices_before,slices_after
