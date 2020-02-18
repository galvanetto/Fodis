# force floating point division. Can still use integer with //
from __future__ import division
# other good compatibility recquirements for python3
from __future__ import absolute_import
from __future__ import print_function
from __future__ import unicode_literals
# This file is used for importing the common utilities classes.
import numpy as np
import matplotlib.pyplot as plt
from . import Analysis
from itertools import chain

class prediction_info:
    def __init__(self,event_idx,event_slices,local_stdev,interp,mask,
                 cdf,slice_fit,threshold,probabilities=None,
                 condition_results=None,event_slices_raw=[]):
        """
        record the data from _predict_helper

        Args:
            event_idx : the event centers we found
            start_idx : the boundaries found for events
            local_stdev : the local standad deviation at each point in slice_fit
            mask : indices where an event is possible
            cdf : cummulative density function for the probability of a point
            in slice_fit, given the model of the data we have
        
            slice_fit : slice within the original retract where we tried to 
            find events. We have to remove the first few and last few points
            
            threshold: the threshhold for determining an event
            condition_results: list of masks used for adhesion, 
            list of boolean arrays, one per mask 
        Returns:
            prediction_info object
        """
        self.event_idx = event_idx
        self.event_slices = event_slices
        self.local_stdev = local_stdev
        self.interp = interp
        self.mask = mask
        self.cdf = cdf
        self.slice_fit = slice_fit
        self.threshold = threshold
        self.condition_results = condition_results
        self.probabilities= probabilities
        self.event_slices_raw = event_slices_raw

class no_event_parameters:
    def __init__(self,epsilon,sigma,threshold,
                 delta_epsilon=None,delta_sigma=None,
                 derivative_epsilon=None,derivative_sigma=None,
                 integral_epsilon=None,integral_sigma=None,
                 valid_delta=True,valid_derivative=True,valid_integral=True,
                 mask_is_conditional=True,negative_only=True,
                 delta_abs_epsilon=None,delta_abs_sigma=None,
                 last_interpolator_used=None):
        self.epsilon = epsilon
        self.sigma = sigma
        self.threshold = threshold
        # delta parameters
        self.delta_epsilon=delta_epsilon
        self.delta_sigma=delta_sigma
        # abs delta parameters
        self.delta_abs_epsilon = delta_abs_epsilon
        self.delta_abs_sigma = delta_abs_sigma
        # derivative parameters
        self.derivative_epsilon=derivative_epsilon
        self.derivative_sigma=derivative_sigma
        # integral parameters
        self.integral_epsilon=integral_epsilon
        self.integral_sigma=integral_sigma
        # determine what we can actuallly run
        self._set_valid_delta(valid_delta)
        self._set_valid_derivative(valid_derivative)
        self._set_valid_integral(valid_integral)
        self.mask_is_conditional = mask_is_conditional
        self.negative_only=negative_only
        self.last_interpolator_used = None
    def _set_valid_delta(self,flag):
        self.valid_delta = ((self.delta_epsilon is not None and
                            self.delta_sigma is not None) and flag)
    def _set_valid_integral(self,flag):
        self.valid_integral = (((self.integral_epsilon is not None) and
                                (self.integral_sigma is not None)) and flag)
    def _set_valid_derivative(self,flag):
        self.valid_derivative = (((self.derivative_epsilon is not None) and
                                  (self.derivative_sigma is not None)) and flag)



def _min_points_between(tau_n):
    """
    returns the minimum recquired points between two discrete events,
    given a number of filtering points
    
    Args:
        autocorrelation_tau_num_points: number of filtering points
    """
    return int(np.ceil(tau_n/2))
              

def _event_mask(probability,threshold):
    """
    Given a probability distribution and a threshold, returns the indices
    where the probability is less  than the threshhold
    
    Args:
        example_split: the split force extension curve to use
        probability: array of numbers between 0 and 1
        threshold: maximum value in mask
        condition_functions: list of functions taking in the probability and 
        threshold, and returning a boolean 1/0 array; a 1 is required for an 
        event
    Returns:
        tuple of (indices where the probability is less than the threshold)
    """
    boolean_thresh = (probability <= threshold)
    return np.where(boolean_thresh)[0]

def _probability_by_cheby_k(k):
    """
    given a chebyshev 'k' value (number of stdevs 'out'), returns the 
    probability bound, normalized to 1
    
    Args:
        k: array-like to use
    Returns:
        Probability for each point accoring to chebyshevs, bounded 0->1
    """
    # determine where the chebyshev is 'safe', otherwise we are at or above
    # the mean estimate and hence not a useful metric
    cheby_idx = np.where(np.abs(k) >= 1)
    chebyshev = np.ones(k.size)
    # actually calculate the upper bound for the probability
    chebyshev[cheby_idx] = (1/k[cheby_idx])**2
    return chebyshev


def _no_event_chebyshev(g,epsilon,sigma):
    """
    Given an array of values, an epsilon estimate, and a sigma, returns the 
    no-event probability
    
    Args:
        g: remainder value
        epsilon: mean parameter, estimate of fitting noise
        sigma: stdev parameter, estimate of noise on g-g*
    """
    denom = (g-epsilon)
    k = denom/sigma
    return _probability_by_cheby_k(k)

def _delta(x,interp_f,n):
    """
    gets the local centered change of interpolator, with a window of 
    n arond each other

    Args:
        x: x values to interpolate along
        interp_f: the smoothed / interpolated value to use
        n: number of points
    Returns :
        df, same size as x
    """
    # get the retract df spectrum
    df_true = Analysis.local_centered_diff(interp_f,n=n)
    return df_true

def _delta_probability(df,no_event_parameters):
    negative_only=no_event_parameters.negative_only
    epsilon = no_event_parameters.epsilon
    sigma = no_event_parameters.sigma
    min_signal = (epsilon+sigma)
    if (negative_only):
        baseline = -min_signal
    else:
        # considering __all__ signal. XXX need absolute value df?
        baseline = min_signal
        df = np.abs(df)
    df_relative = df-baseline
    # get the pratio probability
    k_cheby_ratio = df_relative/sigma
    if negative_only:
        k_cheby_ratio = np.minimum(k_cheby_ratio,1)
    ratio_probability= _probability_by_cheby_k(k_cheby_ratio)
    return ratio_probability


def _spline_derivative(x,interpolator):
    """
    see mask_spline_derivative, except this returns the probability 
    distribution of each point p, P(deriv to be less than p) by chebyshev
    
    Args:
        split_fec: the split_force_extension object we want to mask the 
        adhesions of 
    Returns:
        array, 1 where we are within a stdev of the median, otherwise
        (stdev/(p-std))**2
    """
    return interpolator.derivative()(x)

def local_noise_integral(f,interp_f,tau_n):
    min_points_between = _min_points_between(tau_n=tau_n)
    diff = f-interp_f
    stdev = Analysis.local_stdev(diff,n=2*tau_n)
    # essentially: when is the interpolated value 
    # at least one (local) standard deviation above the median
    # we admit an event might be possible
    local_integral = Analysis.local_integral(stdev,
                                             min_points_between)
    return local_integral

def _integral_probability(f,interp_f,tau_n,no_event_parameters_object):
    local_integral = local_noise_integral(f,interp_f,tau_n=tau_n)
    integral_sigma   = no_event_parameters_object.integral_sigma
    integral_epsilon   = no_event_parameters_object.integral_epsilon
    # get the propr probability
    probability_integral = _no_event_chebyshev(local_integral,
                                               epsilon=integral_epsilon,
                                               sigma=integral_sigma)
    """
    plt.subplot(2,1,1)
    plt.plot(local_integral)
    plt.axhline(integral_epsilon+integral_sigma)
    plt.subplot(2,1,2)
    plt.semilogy(probability_integral)
    plt.show()
    """
    return probability_integral
    
    

def _derivative_probability(derivative,no_event_parameters_object):
    negative_only=no_event_parameters_object.negative_only
    deriv_epsilon = no_event_parameters_object.derivative_epsilon
    deriv_sigma = no_event_parameters_object.derivative_sigma
    k = (derivative-deriv_epsilon)/deriv_sigma
    if (negative_only):
        k = np.minimum(1,k)
    to_ret = _probability_by_cheby_k(k)
    return to_ret


def _no_event_probability(x,interp,y,tau_n,no_event_parameters_object):
    """
    returns the no-event probability at each point in y

    Args:
        x: the x values that interp takes, see _event_probabilities
        y: the y values we are searching for an event, see _event_probabilities
        interp: see _event_probabilities
        tau_n: number of points to use in estimating r(q)=g-g* by the
        local standard deviaiton of y-interp(x)
        no_event_params_obj: the no-event parameters object to use
        slice_fit: an optional slice to use to compute the probabilities
    Returns:
        tuple of <probability, local stdevs>
    """
    n_original = x.size
    x_s = x
    y_s = y
    # get the interpolated function
    interpolated_y = interp(x_s)
    stdev_masked,_,_ = Analysis.\
        stdevs_epsilon_sigma(y_s,interpolated_y,n=2*tau_n)
    sigma = no_event_parameters_object.sigma
    epsilon = no_event_parameters_object.epsilon
    # note: chebyshev is like
    # P(|X - mu| >=  k * sigma) <= 1/k^2
    # we write k = (s(q) - epsilon)/scale
    chebyshev = _no_event_chebyshev(stdev_masked,epsilon,sigma)
    # for the edge cases, assume the probability is one                         
    probability_distribution = np.ones(y.size)
    # get the probability for all the non edge cases
    probability_distribution = chebyshev
    no_event_parameters_object.last_interpolator_used = interp
    min_points_between = _min_points_between(tau_n=tau_n)
    if (no_event_parameters_object.valid_derivative):
        derivative = _spline_derivative(x_s,interp)
        p_deriv = _derivative_probability(derivative,no_event_parameters_object)
        probability_distribution *= p_deriv
    if (no_event_parameters_object.valid_integral):
        kw = dict(tau_n=tau_n,
                  no_event_parameters_object=no_event_parameters_object)
        p_int = _integral_probability(y_s,interpolated_y,**kw)
        probability_distribution *= p_int
    if (no_event_parameters_object.valid_delta):
        df = _delta(x_s,interpolated_y,n=min_points_between)
        p_delta = _delta_probability(df,no_event_parameters_object)
        probability_distribution *= p_delta        
    if (no_event_parameters_object.negative_only and 
        no_event_parameters_object.valid_derivative):
        deriv_sigma = no_event_parameters_object.derivative_sigma
        condition = derivative >= 0
        where_condition = np.where(condition)
        probability_distribution[where_condition] = 1
    """
    plt.subplot(2,1,1)
    plt.plot(y)
    plt.plot(interp(x_s))
    plt.subplot(2,1,2)
    plt.semilogy(probability_distribution,label="full")
    plt.semilogy(p_deriv,label='deriv')
    plt.semilogy(p_int,label='int')
    if (no_event_parameters_object.valid_delta):
        plt.semilogy(p_delta,label='delta')
    if (no_event_parameters_object.negative_only):
        plt.plot(condition+1.1)
    plt.legend()
    plt.show()
    """
    return probability_distribution,stdev_masked
        
def _event_probabilities(x,y,interp,tau_n,threshold,
                         no_event_parameters_object):
    """
    determines the mask (and associated event detection information)
    
    Args:
        x,y: independent and dependent variable (ie: 'q' and 'g'
        interp: the approximation to y vs x (ie: g*)
        tau_n: number of points from autocorrelation function (ie: tau)

        threshold: maximum probability that a given datapoint fits the 
        model
    
        no_event_parameters_object: instance of no_event_parameters
    Returns:
        tuple of :
            probability_distribution : no-event probability for each point in y
            stdevs: the local, windowed standard deviation, s(q)
    """
    min_points_between = _min_points_between(tau_n=tau_n)
    probability_distribution = np.ones(x.size)
    probability_distribution,stdevs = \
        _no_event_probability(x,interp,y,tau_n=tau_n,
                        no_event_parameters_object=no_event_parameters_object)
    return probability_distribution,stdevs

def _event_slices_from_mask(mask,min_points_between):
    """
    returns individual event slices for the mask, given that points shouldnt]
    be closer than min_points_between
    
    Args:
        mask: see _event_mask
        min_points_between: minimum number of points between events
        
    Returns:
        list of event slices
    """
    idx_step_changes = np.where(np.diff(mask) >= min_points_between)[0]
    # mask[idx_step_changes] gives the end of event i, for some i 
    # mask[idx_step_changes+1] gives the start of event (i+1), for the same i
    step_end_idx = mask[idx_step_changes]
    step_start_idx = mask[(idx_step_changes + 1)]
    # need to incllude the endpoints to get the proper events
    event_idx_end = list(step_end_idx) + [mask[-1]] 
    event_idx_start = [mask[0]] + list(step_start_idx)
    event_slices = [slice(start,end,1) 
                    for start,end in zip(event_idx_start,event_idx_end)]    
    return event_slices


def _predict(x,y,tau_n,interp,threshold,local_event_idx_function,
             remasking_functions=None,**kwargs):
    """
    general method to predict the event boundaries and centers
    
    Args:
        x: see _event_probabilities
        y: see _event_probabilities
        tau_n: see _event_probabilities
        interp: see _event_probabilities
        threshold: see _event_probabilities
        local_event_idx_function: a function which takes a slice of x,y,slice
        as its  only argument and returns the most likely index of an event. 
        the slice passsed should have only one event
    
        remasking_functions: funcitons that take in the slice, boolean array, 
        probability, and threshold and return update values for all except
        threshold
    
        kwargs: passed to  no_event_parameters
    Returns:
        list of event slices
    """
    min_points_between = _min_points_between(tau_n=tau_n)
    no_event_parameters_object = no_event_parameters(threshold=threshold,
                                                     **kwargs)
    probability_distribution,stdevs = \
        _event_probabilities(x,y,interp,tau_n=tau_n,threshold=threshold,\
                        no_event_parameters_object=no_event_parameters_object)
    bool_array = probability_distribution < threshold
    masks = [np.where(bool_array)[0]]
    probabilities = [probability_distribution.copy()]
    slice_to_use = slice(0,y.size-1,1)
    if (remasking_functions is not None):
        for f in remasking_functions:
            res = f(slice_to_use=slice_to_use,
                    boolean_array=bool_array,
                    probability=probability_distribution,
                    threshold=threshold,
                    no_event_parameters_object=no_event_parameters_object)
            if (res[0].start > res[0].stop):
                bool_array = np.zeros(x.size)
                probabilities = np.zeros(x.size)
                slice_to_use = slice(0,x.size,1)
                break
            # POST: result is OK...
            slice_to_use,bool_array, probability_distribution = res
            # mask on probability distribution, to keep things consistent
            probabilities.append(probability_distribution)
            masks.append(np.where(bool_array)[0])
    # only keep points where we are farther than min_points between from the 
    # edges (ie: from index 0 and N-1)
    mask = np.where(bool_array)[0]
    n = mask.size
    if (mask.size > 0):
        event_slices = _event_slices_from_mask(mask,int(min_points_between))
    else:
        event_slices = []
    event_slices_raw = list(event_slices)
    # XXX reject events with a very small time?
    event_duration = [ abs(e.stop-e.start) for e in event_slices]
    delta_split_rem = [ int(np.ceil(tau_n-(delta//2)))
                        for delta in event_duration]
    # determine where the events are happening locally (guarentee at least
    # a search window of min_points)
    # XXX debugging 
    remainder_split = [max(0,d) for d in delta_split_rem ]
    event_slices = [slice(event.start-remainder,event.stop+remainder,1)
                    for event,remainder in zip(event_slices,remainder_split)]
    max_idx = x.size-1
    # make sure all the indices are in range.
    event_slices = [slice(max(0,e.start),min(e.stop,max_idx+1))
                     for e in event_slices]
    # dont look at any events at the end
    event_slices = [e for e in event_slices
                    if (e.stop < max_idx - min_points_between and
                        e.start > slice_to_use.start + min_points_between)]
    event_idx = [min(max_idx,local_event_idx_function(x,y,e))
                 for e in event_slices]
    # update the probability distribution
    events_final_bool = np.zeros(probability_distribution.size,dtype=np.bool)
    for e in event_slices:
        events_final_bool[e] = 1
    where_events_final = np.where(events_final_bool)[0]
    where_non_events = np.where(np.invert(events_final_bool))[0]
    probability_distribution[where_non_events] = 1
    probabilities[-1][where_non_events] = 1
    masks[-1] = where_events_final
    mask = where_events_final
    to_ret = prediction_info(event_idx = event_idx,
                             event_slices = event_slices,
                             local_stdev = stdevs,
                             interp = interp,
                             mask = mask,
                             cdf=probability_distribution,
                             slice_fit=slice_to_use,
                             threshold=threshold,
                             condition_results=masks,
                             event_slices_raw=event_slices_raw,
                             probabilities=probabilities)
    return to_ret                                
                          

def join_contiguous_slices(slices, offset=0):
    """
    # XXX see:
    stackoverflow.com/questions/24317211/
    merge-overlapping-numeric-ranges-into-continuous-ranges
    """
    flatten = chain.from_iterable
    LEFT, RIGHT = 1, -1
    data = [[s.start,s.stop] for s in slices]
    data = sorted(flatten(((start, LEFT), (stop + offset, RIGHT))
            for start, stop in data))
    c = 0
    for value, label in data:
        if c == 0:
            x = value
        c += label
        if c == 0:
            yield slice(x, value - offset,1)   
