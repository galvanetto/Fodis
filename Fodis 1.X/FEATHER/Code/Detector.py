# force floating point division. Can still use integer with //
from __future__ import division
# This file is used for importing the common utilities classes.
import numpy as np
import matplotlib.pyplot as plt
import sys
from scipy import signal,stats

from . import Analysis
# XXX reduce import size below
from ._no_event import _min_points_between,_predict,\
    _probability_by_cheby_k,_no_event_chebyshev,_event_slices_from_mask
from . import _no_event

def get_slice_by_max_value(interp_sliced,offset,slice_list):
    """
    Given a data set, an offset into that data set, and a list of slices
    relative to that offset, picks the slice giving the largest value

    Args:
        interp_sliced: the data to choose from
        offset: the absolute offset for each slice. If 0, then absolute
        slice_list: list of slice object
    Returns:
        s in slice_list giving the maximum value in interp_sliced
    """
    offset_slices = [slice(max(0,s.start-offset),max(s.stop-offset,0))
                     for s in slice_list]
    regions = [interp_sliced[e] for e in offset_slices]
    value_max = [max(r) if r.size > 0 else -np.inf for r in regions]
    return np.argmax(value_max)

def safe_reslice(original_boolean,original_probability,condition,
                 min_points_between,get_best_slice_func):
    """
    applies the boolean <condition> array without creating new events; if 
    more than one event exists where a previous one existed, picks by 
    get_best_slice_func

    Args;
        original_boolean: boolean array, size N
        original_probability: probability array, size N
        condition: array to apply to above, size N. where condition is 1,
        the boolean array becomes *zero* 

        min_points_between: see _event_slices_from_mask
        get_best_slice_func: given a list of slices in the *original* data
        (ie: size N), this function should return the index of the single
        slice to keep
    Returns:
        tuple of <updated boolean, updated probability>
    """
    new_boolean = original_boolean.copy()
    new_probability = original_probability.copy()
    where_condition = np.where(condition)[0]
    if (where_condition.size > 0):
        new_boolean[where_condition] = 0 
        new_probability[where_condition] = 1
        # get the original and new slices
        mask_original = np.where(original_boolean)[0]
        mask_new = np.where(new_boolean)[0]
        if (mask_new.size == 0 or mask_original.size == 0):
            return new_boolean,new_probability
        # POST: have something to do
        original_events = _event_slices_from_mask(mask_original,
                                                  min_points_between)
        new_events = _event_slices_from_mask(mask_new,min_points_between)
        remove,keep = [],[]
        for e in original_events:
            start,stop = e.start,e.stop
            # determine which new events are within the old events
            candidates = [tmp for tmp in new_events 
                          if (tmp.start >= start) and (tmp.stop <= stop)
                          and (tmp.start < tmp.stop)]
            if (len(candidates) == 0):
                continue
            # determine the best new event within the old event, in the subslice
            # indices
            idx_best = get_best_slice_func(candidates)
            # get the best
            keep.append(candidates[idx_best])
            # remove the events
            remove.extend(candidates[i] for i in range(len(candidates))
                          if i != idx_best)
        # anything left over should also be deleted
        remove.extend(new_events)
        # POST: know what to remove and what to keep
        new_boolean = np.zeros(new_boolean.size)
        new_probability = np.ones(new_probability.size)
        for keep_idx in keep:
            new_boolean[keep_idx] = 1
            new_probability[keep_idx] = original_probability[keep_idx]
        # pick out the minimum derivative slice within each previous slice
    return new_boolean,new_probability

def _condition_no_delta_significance(no_event_parameters_object,df_true,
                                     negative_only):
    """
    Returns a boolean array, 1 where delta is consistent with zero...
    
    Args;
        no_event_parameters_object: see _condition_delta_at_zero
        df_true: Change in function 
        negative_only: if true, only look at negative changes (where positive
        are returned as 1)
        
    Returns;
        boolean array, 1 where nothing happening 
    """                                     
    epsilon = no_event_parameters_object.epsilon
    sigma = no_event_parameters_object.sigma
    epsilon_approach = no_event_parameters_object.delta_epsilon
    sigma_approach = no_event_parameters_object.delta_sigma
    min_signal = (epsilon+sigma)
    if (negative_only):
        baseline = -min_signal
    else:
        # considering __all__ signal. XXX need absolute value df?
        baseline = min_signal
    value_cond = (df_true > baseline)
    """
    plt.plot(df_true)
    plt.axhline(baseline)
    plt.show()
    """
    return value_cond
    
def f_average_and_diff(force,n):
    """
    Returns the local average and centered difference of force 
    
    Args;
        force: the function to average and difference
        n: window size
    Returns;
        tuple of <local average, local diff>
    """
    size = int(np.ceil(int(n/2)))
    half_size = max(int(np.ceil(int(size/2)))-1,1)
    size = max(size,2*half_size+1)
    local_average = Analysis.local_average(force,size,
                                           size=size,origin=half_size)
    average_baseline = np.zeros(local_average.size)
    average_baseline[:-half_size] = local_average[half_size:]
    diff = average_baseline-local_average
    return local_average,diff

def _condition_delta_at_zero(no_event_parameters_object,force,tau_n):
    """
    returns a boolean array with ones where we are consistent with no change
    
    Args:
        no_event_parameters_object: to use in determining the zeros 
        force: the raw y values, assumed zeroed
        n: the number of filterp oints (e.g. tau_num_points)
    Returns:
        array of size like force, 1 where nothing much happening 
    """
    sigma = no_event_parameters_object.sigma
    epsilon = no_event_parameters_object.epsilon
    min_sig_df = no_event_parameters_object.delta_epsilon + \
                 no_event_parameters_object.delta_sigma
    threshold_local_average = min_sig_df+sigma+epsilon
    baseline_interp = min_sig_df+sigma
    local_average,diff =  f_average_and_diff(force,n=2*tau_n)
    to_ret = ( (diff >= -baseline_interp) | 
               (local_average <= threshold_local_average))
    """
    plt.subplot(3,1,1)
    plt.plot(force)
    plt.plot(local_average)
    plt.axhline(threshold_local_average)
    plt.subplot(3,1,2)
    plt.plot(diff)
    plt.axhline(-baseline_interp)
    plt.ylim([-5*baseline_interp,5*baseline_interp])
    plt.subplot(3,1,3)
    plt.plot(to_ret)
    plt.show()
    """
    return to_ret

def delta_mask_function(split_fec,slice_to_use,
                        boolean_array,probability,threshold,
                        no_event_parameters_object,negative_only=True):
    x = split_fec.retract.Time
    force = split_fec.retract.Force
    x_sliced = x[slice_to_use]
    force_sliced = force[slice_to_use]
    tau_n = split_fec.tau_num_points
    min_points_between = _min_points_between(tau_n=tau_n)
    # get the retract df spectrum
    interpolator = no_event_parameters_object.last_interpolator_used
    interp_f = interpolator(x_sliced)
    # offset to right now (assume this is after surface  touchoff /adhesions)
    where_event = np.where(boolean_array)[0]
    n = force.size
    # offset to zero if it makes sense
    event_mask = np.where(boolean_array[slice_to_use])[0]
    offset_idx = 0
    offset_zero_force = interp_f[0]
    if (event_mask.size > 0):
        slices = _event_slices_from_mask(event_mask, min_points_between)
        event_lengths = [s.stop - s.start for s in slices]
        # find the last 'long' event not at the end
        long_event_ends = [s.stop for i, s in enumerate(slices) if
                           event_lengths[i] > 2*tau_n
                           and s.stop < force_sliced.size - 2*tau_n]
        if (len(long_event_ends) > 0):
            last_long_event = long_event_ends[-1]
            offset_idx = last_long_event
            offset_zero_force = np.median(force_sliced[offset_idx:])
        else:
            # couldnt find a long enough event; just zero based on the end
            if (where_event.size > 0 and
                where_event[-1] < force_sliced.size - min_points_between):
                offset_idx = where_event[-1]+1
                offset_zero_force = np.median(force[offset_idx:])
            else:
                offset_idx = n - min_points_between
                offset_zero_force = np.median(force[offset_idx:])
    """
    plt.close()
    plt.plot(x_sliced,force_sliced)
    plt.axhline(offset_zero_force)
    plt.axvline(x_sliced[offset_idx])
    for e in slices:
        plt.plot(x_sliced[e],force_sliced[e],'r')
    plt.show()
    """
    split_fec.zero_retract_force(offset_zero_force)
    interp_f -= offset_zero_force
    df_true = _no_event._delta(x_sliced,interp_f,min_points_between)
    # get the baseline results
    kw_delta = dict(df=df_true,no_event_parameters=no_event_parameters_object)
    ratio_probability = _no_event._delta_probability(**kw_delta)
    tol = 1e-9
    no_event_cond = (1-ratio_probability<tol)
    """
    plt.semilogy(ratio_probability)
    plt.axhline(1-tol)
    plt.show()
    """
    # find where the derivative is definitely not an event
    value_cond = \
        _condition_no_delta_significance(no_event_parameters_object,df_true,
                                         negative_only)
    gt_condition = np.ones(boolean_array.size)
    gt_condition[slice_to_use] = (value_cond) | (no_event_cond)
    get_best_slice_func = lambda slice_list: \
        get_slice_by_max_value(interp_f,slice_to_use.start,slice_list)
    # update the boolean array before we slice
    boolean_ret,probability_updated = \
            safe_reslice(original_boolean=boolean_array,
                         original_probability=probability,
                         condition=gt_condition,
                         min_points_between=min_points_between,
                         get_best_slice_func=get_best_slice_func)
    boolean_ret = probability_updated < threshold
    """
    xlim = min(x), max(x)
    plt.subplot(2, 1, 1)
    plt.plot(x, force)
    plt.plot(x_sliced, interp_f)
    plt.xlim(xlim)
    plt.subplot(2, 1, 2)
    plt.plot(x_sliced, boolean_array[slice_to_use] + 2.1)
    plt.plot(x_sliced, value_cond + 1.1)
    plt.plot(x_sliced, no_event_cond)
    plt.xlim(xlim)
    plt.show()
    """
    deriv = _no_event._spline_derivative(x_sliced,interpolator)
    dt = np.median(np.diff(x_sliced))
    deriv_cond = np.zeros(boolean_ret.size,dtype=np.bool)
    consistent_with_zero_cond = np.zeros(boolean_ret.size,dtype=np.bool)
    sigma_df = no_event_parameters_object.delta_abs_sigma
    epsilon_df = no_event_parameters_object.delta_abs_epsilon
    deriv_cond[slice_to_use] = \
            interp_f + (deriv * min_points_between/2 * dt) < sigma_df
    # XXX debugging...
    df_thresh = np.abs(sigma_df + epsilon_df)
    average_tmp,diff = f_average_and_diff(force,n=2*tau_n)
    diff_abs_sliced = np.abs(diff[slice_to_use])
    change_insignificant = ((diff_abs_sliced < df_thresh) & 
                            (np.abs(df_true) < df_thresh))
    min_zero_idx = n-2*tau_n
    last_greater = np.where(boolean_ret[slice_to_use])[0]
    """
    xlim = [min(x_sliced),max(x)]
    plt.subplot(3,1,1)
    plt.plot(x,force)
    plt.plot(x,average_tmp)
    plt.axvline(x[min_zero_idx])
    plt.xlim(xlim)
    plt.subplot(3,1,2)
    plt.plot(x_sliced,diff_abs_sliced)
    plt.axhline(df_thresh)
    plt.axvline(x[min_zero_idx])        
    plt.xlim(xlim)    
    plt.subplot(3,1,3)
    plt.plot(x_sliced,boolean_ret[slice_to_use])
    plt.plot(x_sliced,change_insignificant,linestyle='--')
    plt.axvline(x[min_zero_idx],label="min idx")    
    plt.axvline(x[min_zero_idx-min_points_between],linestyle='--',
                label="min idx - points between")
    plt.xlim(xlim)    
    plt.legend(loc='upper left')
    plt.show()
    """
    if ( (last_greater.size > 0)):
        last_greater_idx_in_slice = last_greater[-1]
        offset_change_idx = last_greater_idx_in_slice + min_points_between
        change_insig_after_greater = change_insignificant[offset_change_idx:]
        # get where the change is insignificant after  the last event as 
        # an absolute index into force
        where_insignificant_abs = np.where(change_insig_after_greater)[0] + \
                                  offset_change_idx + \
                                  slice_to_use.start
        # only zero if we effectively aren't changing at the end
        if ( (where_insignificant_abs.size > 0) and 
              (where_insignificant_abs[0] < min_zero_idx)): 
            offset_idx = where_insignificant_abs[0]
            offset_tmp = np.median(force[offset_idx:])
            offset_zero_force = offset_tmp
            split_fec.zero_retract_force(offset_zero_force)
            interp_f -= offset_zero_force
    """
    plt.subplot(2,1,1)
    plt.plot(x,boolean_ret)
    plt.subplot(2,1,2)    
    plt.plot(x,force)
    plt.plot(x_sliced,interp_f)
    plt.axhline(0)
    plt.axvline(x[offset_idx])
    plt.show()
    """
    # find where we are consistent with zero
    consistent_with_zero_cond[slice_to_use] = \
            _condition_delta_at_zero(no_event_parameters_object,force_sliced,
                                     tau_n=tau_n)
    condition_non_events = (consistent_with_zero_cond | deriv_cond)
    boolean_ret, probability_updated = \
        consistent_with_zero(boolean_ret,probability_updated,
                             condition_non_events,min_points_between,
                             get_best_slice_func,threshold)
    return slice_to_use,boolean_ret,probability_updated

def consistent_with_zero(boolean_ret,probability_updated,condition_non_events,
                         min_points_between,get_best_slice_func,threshold):
    boolean_ret,probability_updated = \
            safe_reslice(original_boolean=boolean_ret,
                         original_probability=probability_updated,
                         condition=condition_non_events,
                         min_points_between=min_points_between,
                         get_best_slice_func=get_best_slice_func)
    probability_updated[-min_points_between:] = 1
    boolean_ret = probability_updated < threshold
    return boolean_ret,probability_updated

def get_events_before_marker(marker_idx,event_mask,min_points_between):
    if (event_mask.size == 0):
        return []
    # determine events that contain the surface index
    event_boundaries = _event_slices_from_mask(event_mask,min_points_between)
    # get a list of the events with a starting point below the surface
    events_containing_surface = [e for e in event_boundaries
                                 if (e.start <= marker_idx)]
    return events_containing_surface

def set_knots_by_derivative(split_fec,interp,x_all,slice_v):
    """
    sets the knots of a split fec, choosing them proportionally to the absolute
    derivative of the splien interpolator. note that this is randomized

    Args:
        split_fec: the split force extension object to set the knots of
        interp: to get the derivative of
        x_all: the x values for split_fec to use
        slice_v: the subslice which we want the knots in. 
    Returns:
        nothing, but sets the retract knots of split_fec as described above
    """
    x_slice = x_all[slice_v]
    interp_deriv = interp.derivative()(x_slice)
    n_knots = int(np.ceil(x_slice.size/split_fec.tau_num_points))
    prob = np.abs(interp_deriv)
    prob = (prob)/(sum(prob))
    knots = np.random.choice(a=x_slice.size,size=n_knots,replace=False,p=prob)
    split_fec.retract_knots = np.array(sorted(knots)) + slice_v.start


def adhesion_mask_function_for_split_fec(split_fec,slice_to_use,boolean_array,
                                         probability,threshold,
                                         no_event_parameters_object):
    """
   returns the funciton adhesion_mask, with surface_index set to whatever
    the surface index of split_fec is predicted to be by the approach
    
    Args:
        split_fec: the split_force_extension object we want to mask the 
        adhesions of 

        *args,**kwargs: see adhesion
    Returns:
        new mask and probability distribution
    """
    tau_n = split_fec.tau_num_points
    probability_updated = probability.copy()      
    boolean_ret = boolean_array.copy()
    surface_index = split_fec.get_predicted_retract_surface_index()   
    # determine where the surface is 
    non_events = probability_updated > threshold
    min_points_between = _min_points_between(tau_n=tau_n)
    min_idx = surface_index + min_points_between
    x_all = split_fec.retract.Time
    y_all = split_fec.retract.Force
    n = y_all.size
    # determine where delta is first one (necessary but not sufficient for 
    # passing adhesions)
    interp_tmp = no_event_parameters_object.last_interpolator_used
    interp_tmp_deriv = interp_tmp.derivative()(x_all)
    deriv_threshold = no_event_parameters_object.derivative_epsilon + \
                      no_event_parameters_object.derivative_sigma
    where_change_is_low = np.where(interp_tmp_deriv <= deriv_threshold)[0]
    if (where_change_is_low.size > 0):
        min_idx = max(min_idx,where_change_is_low[0])
    # remove all things before the predicted surface, and at the boundary
    boolean_ret[:min_idx] = 0
    boolean_ret[-min_points_between:] = 0
    probability_updated[:min_idx] = 1
    probability_updated[-min_points_between:] = 1
    slice_updated = slice(min_idx,n-min_points_between,1)
    event_mask = np.where(~non_events)[0]
    # POST: we have at least one event and one non-event
    # (could be some adhesion!)
    events_containing_surface = get_events_before_marker(min_idx,event_mask,
                                                         min_points_between)
    # set up the fec and parameters so we are now looking for negatives,
    # using the delta
    no_event_parameters_object._set_valid_delta(True)
    no_event_parameters_object.negative_only = True
    if (len(events_containing_surface) == 0):
        interp = no_event_parameters_object.last_interpolator_used
        kw = dict(tau_n=tau_n,
                  no_event_parameters_object=no_event_parameters_object)
        probability_updated[slice_updated],_ = _no_event.\
                _no_event_probability(x_all[slice_updated],interp,
                                      y_all[slice_updated],
                                      **kw)
        boolean_ret = (probability_updated < threshold)
        return slice_updated,boolean_ret,probability_updated
    """
    plt.subplot(2,1,1)
    plt.plot(x_all,y_all)
    plt.plot(x_all,no_event_parameters_object.last_interpolator_used(x_all))
    plt.axvline(x_all[surface_index])
    plt.subplot(2,1,2)
    plt.semilogy(probability_updated)
    plt.show()
    """
    # POST: have at least one event.
    last_event_containing_surface_end = \
        events_containing_surface[-1].stop + min_points_between
    last_event_containing_surface_end = min(last_event_containing_surface_end,
                                            y_all.size)
    min_idx = max(min_idx,last_event_containing_surface_end)
    # update the boolean array and the probably to just reflect the slice
    # ie: ignore the non-unfolding probabilities above
    boolean_ret[:min_idx] = 0
    slice_tmp = slice(min_idx,slice_updated.stop,1)
    # set the interpolator for the non-adhesion region; need to re-calculate
    # since adhesion (probably) really screws everything up
    x_slice = x_all[slice_tmp]
    y_slice = y_all[slice_tmp]
    if (x_slice.size < min_points_between):
        # it is possible the event is at the very end of the data, in which
        # case we are done. 
        # return the *previous* slice, zeroing out everything
        boolean_ret[:] = 0
        probability_updated[:] = 1
        return slice_updated,boolean_ret,probability_updated   
    # POST: the updated slice should give us some data to look at
    slice_updated = slice_tmp
    slice_interp = slice(slice_updated.start,slice_updated.stop,1)    
    interp = split_fec.retract_spline_interpolator(slice_to_fit=slice_interp)
    interp_slice = interp(x_slice)
    split_fec.set_retract_knots(interp)
    # get the probability of only the negative regions
    kw = dict(tau_n=tau_n,
              no_event_parameters_object=no_event_parameters_object)
    probability_in_slice,_ = _no_event.\
        _no_event_probability(x_slice,interp,y_slice,**kw)
    probability_updated = probability.copy()                              
    probability_updated[:min_idx] = 1
    probability_updated[slice_updated] = probability_in_slice
    boolean_ret =  probability_updated < threshold
    # make sure we aren't at an event right now (due to the delta)
    event_mask_post_delta = np.where(boolean_ret)[0]
    events_containing_surface = get_events_before_marker(min_idx,
                                                         event_mask_post_delta,
                                                         min_points_between)
    if (len(events_containing_surface) == 0):
        return slice_updated,boolean_ret,probability_updated
    # XXX zero by whatever is happening after the last event..
    last_event_containing_surface_end = \
        events_containing_surface[-1].stop + min_points_between
    min_idx = max(min_idx,last_event_containing_surface_end)
    slice_updated = slice(min_idx,slice_updated.stop,1)
    probability_updated[:min_idx] = 1
    boolean_ret =  probability_updated < threshold
    return slice_updated,boolean_ret,probability_updated

def _loading_rate_helper(x,y,slice_event,slice_fit=None):
    """
    Determine where a (single, local) event is occuring in the slice_event
    (of length N) part of x,y by:
    (1) Finding the maximum of y in the slice
    (2) Fitting a line to the N points up to the maximum
    (3) Determining the last point at which y[slice_event] is above the 
    predicted line from (2). If this doesnt exist, just uses the maximum

    Args:
        x, y: x and y values. we assume an event is from high to low in y
        slice_event: where to search for the crossing
        slice_fit: where to fit for the line. If none, assumes = slice_event
    Returns:
        tuple of <fit_x,fit_y,predicted y based on fit, idx_above_predicted>
    """
    if (slice_fit is None):
        slice_fit = slice_event
    # determine the local maximum
    offset = slice_event.start
    y_event = y[slice_event]
    x_event = x[slice_event]
    local_max_idx = offset
    if (y_event.size > 0):
        local_max_idx += np.argmax(y_event)
    fit_x = x[slice_fit]
    fit_y = y[slice_fit]
    if (fit_x.size > 0):
        coeffs = np.polyfit(x=fit_x,y=fit_y,deg=1)
        pred = np.polyval(coeffs,x=x_event)
        # determine where the data *in the __original__ slice* is __last__
        # above the fit (after that, it is consistently below it)
        idx_above_predicted_rel = np.where(y_event > pred)[0]    
        idx_below_predicted_rel = np.where(y_event <= pred)[0]
    else:
        # effectively no data to fit
        pred = y[slice_event.start]
        idx_above_predicted_rel = [slice_event.start]
        idx_below_predicted_rel = [slice_event.start]
    # dont look at things past where we fit...
    idx_above_predicted = [offset + i for i in idx_above_predicted_rel]
    idx_below_predicted = [offset + i for i in idx_below_predicted_rel]
    return fit_x,fit_y,pred,idx_above_predicted,idx_below_predicted,\
        local_max_idx
    
def event_by_loading_rate(x,y,slice_event,interpolator,tau_n):
    """
    see _loading_rate_helper 

    Args:
        interpolator: to use for getting the smoothed maximum negative deriv
        tau_n: number of points in the window
        others: see _loading_rate_helper
    Returns:
        predicted index (absolute) in x,y where we think the event is happening
    """    
    # determine where the derivative is maximum
    x_event = x[slice_event]
    interp_deriv_slice = interpolator.derivative()(x_event)
    abs_max_change_idx = slice_event.start + np.argmin(interp_deriv_slice)
    median_deriv = np.median(interp_deriv_slice)
    where_le_median_rel = np.where(interp_deriv_slice <= median_deriv)[0]
    if (where_le_median_rel.size == 0):
        # then just fit the whole thing
        abs_median_change_idx = abs_max_change_idx
        post_fit_start_idx =  abs_max_change_idx
    else:
        abs_median_change_idx = slice_event.start + where_le_median_rel[0]
        post_fit_start_idx = min(slice_event.stop-_min_points_between(tau_n),
                                 slice_event.start + where_le_median_rel[-1])
    delta = 2*tau_n + 1
    # only *fit* up until the median derivatice
    slice_fit = slice(abs_median_change_idx-delta,abs_median_change_idx,1)
    # *search* in the entire place before the maximum derivative
    start_idx_abs = max(0,abs_max_change_idx-delta)
    # fit a line to the 'post event', to reduce false positives
    post_slice_fit = slice(post_fit_start_idx,slice_event.stop,1)
    post_slice_event = slice(abs_median_change_idx,slice_event.stop,1)
    final_event_idx = abs_max_change_idx
    # need at least three points to fit the line
    if (post_slice_fit.stop - post_slice_fit.start >= 3):
        fit_x_rev,fit_y_rev,pred_rev,_,idx_below_predicted,_ = \
                _loading_rate_helper(x,y,slice_event=post_slice_event,
                                     slice_fit=post_slice_fit)
        if (len(idx_below_predicted) > 0):
            final_event_idx = idx_below_predicted[0]
    slice_event_effective = slice(start_idx_abs,final_event_idx,1)
    fit_x,fit_y,pred,idx_above_predicted,_,local_max_idx = \
            _loading_rate_helper(x,y,slice_event=slice_event_effective,
                                 slice_fit=slice_fit)
    # XXX debugging
    """
    interp_slice = interpolator(x_event)
    xlim_zoom = [min(x_event),max(x_event)]
    plt.subplot(3,1,1)
    plt.plot(x,y,color='k',alpha=0.3)
    plt.plot(fit_x,fit_y)
    plt.axvline(x[slice_event.start])
    plt.axvline(x[slice_event.stop])
    plt.plot(x[slice_event_effective],pred,linewidth=2,color='r')
    plt.subplot(3,1,2)
    plt.plot(x_event,interp_deriv_slice)
    plt.axhline(median_deriv)
    plt.xlim(xlim_zoom)
    plt.subplot(3,1,3)
    plt.plot(x[slice_event],y[slice_event],color='k',alpha=0.3)
    plt.plot(fit_x,fit_y,color='g',alpha=0.3)
    plt.plot(x_event,interp_slice)
    plt.plot(x[slice_event_effective],pred,linewidth=2,color='r')
    try:
        plt.plot(fit_x_rev,fit_y_rev)
        plt.plot(x[post_slice_event],pred_rev)
    except:
        pass
    plt.axvline(x[idx_above_predicted[-1]])
    plt.xlim(xlim_zoom)
    plt.show()
    """
    # POST: have a proper max, return the last time we are above
    # the linear prediction
    if (len(idx_above_predicted) == 0):
        return local_max_idx
    return idx_above_predicted[-1]
    
def make_event_parameters_from_split_fec(split_fec,**kwargs):
    tau_n = split_fec.tau_num_points
    min_points_between = _min_points_between(tau_n=tau_n)
    stdevs,epsilon,sigma,slice_fit_approach,spline_fit_approach =\
        split_fec._approach_metrics()
    split_fec.set_espilon_and_sigma(epsilon,sigma)
    split_fec.set_approach_metrics(slice_fit_approach,spline_fit_approach)
    """
    get the interpolator delta in the slice
    """
    interpolator_approach_x = split_fec.approach.Time[slice_fit_approach]
    approach_f = split_fec.approach.Force[slice_fit_approach]
    interpolator_approach_f = spline_fit_approach(interpolator_approach_x)
    df_approach = _no_event._delta(interpolator_approach_x,
                                   interpolator_approach_f,
                                   n=min_points_between)
    delta_epsilon,delta_sigma = np.median(df_approach),np.std(df_approach)
    abs_df_approach = np.abs(df_approach)
    delta_abs_epsilon, delta_abs_sigma = np.median(abs_df_approach),\
                                         np.std(abs_df_approach)
    """
    get the interpolated integral in the slice
    """
    approach_noise_integral = _no_event.\
        local_noise_integral(approach_f,
                             interpolator_approach_f,
                             tau_n=tau_n)
    integral_epsilon = np.median(approach_noise_integral)
    integral_sigma = np.std(approach_noise_integral)
    """
    get the interpolated derivative in the slice
    """
    approach_interp_deriv = \
            spline_fit_approach.derivative()(interpolator_approach_x)
    derivative_epsilon = np.median(approach_interp_deriv)
    # avoid stage noise
    q_low,q_high = np.percentile(approach_interp_deriv,[1,99])
    idx = np.where( (approach_interp_deriv < q_high) &
                    (approach_interp_deriv > q_low))
    derivative_sigma = np.std(approach_interp_deriv[idx])
    # get the remainder of the approach metrics needed
    # note: to start, we do *not* use delta; this is calculated
    # after the adhesion
    approach_dict = dict(integral_sigma   = integral_sigma,
                         integral_epsilon = integral_epsilon,
                         delta_epsilon = delta_epsilon,
                         delta_sigma   = delta_sigma,
                         derivative_epsilon = derivative_epsilon,
                         derivative_sigma   = derivative_sigma,
                         epsilon=epsilon,sigma=sigma,
                         delta_abs_epsilon=delta_abs_epsilon,
                         delta_abs_sigma=delta_abs_sigma,**kwargs)
    return approach_dict                           
	
                         
def _predict_helper(split_fec,threshold,remasking_functions,**kwargs):
    """
    uses spline interpolation and local stadard deviations to predict
    events.

    Args:
        split_fec: split_force_extension object, already initialized, and 
        zerod, with the autocorraltion time set. 
        remasking_functions: for remasking...
        threshhold: maximum probability that a given datapoint fits the 
        model
        
        kwargs: passed to _predict
    Returns:
        prediction_info object
    """
    retract = split_fec.retract
    time,separation,force = retract.Time,retract.Separation,retract.Force
    tau_n = split_fec.tau_num_points
    # N degree b-spline has continuous (N-1) derivative
    interp_retract = split_fec.retract_spline_interpolator()
    # set the knots based on the initial interpolator, so that
    # any time we make a new splining object, we use the same knots
    split_fec.set_retract_knots(interp_retract)
    # set the epsilon and tau by the approach
    approach_dict = make_event_parameters_from_split_fec(split_fec,**kwargs)
    local_fitter = lambda *_args,**_kwargs: \
                   event_by_loading_rate(*_args,
                                         interpolator=interp_retract,
                                         tau_n=tau_n,
                                         **_kwargs)
    # call the predict function
    final_kwargs = dict(valid_delta=False,negative_only=False,**approach_dict)
    to_ret = _predict(x=time,
                      y=force,
                      tau_n=tau_n,
                      interp=interp_retract,
                      threshold=threshold,
                      local_event_idx_function=local_fitter,
                      remasking_functions = remasking_functions,
                      **final_kwargs)
    return to_ret

def _predict_functor(example,f):
    """
    python doesn't like creating lambda functions using 
    function references in a list (2017-3-1), so I use a functor instead

    Args:
        example: first argument of type like f. split_fec is used in predict
        f: function we are calling. should take split_fec, then *args,**kwargs
        (see _predict
    returns:
        a lambda function passing arguments and keyword argument to f 
    """
    return lambda *args,**kwargs : f(example,*args,**kwargs)

def _predict_split_fec(example_split,threshold,f_refs=None,**kwargs):
    """
    :param f_refs:  see _predict_full
    :param example_split: split_fec to predict based on
    :param threshold: minimum probability
    :param kwargs: see _predict_helper
    :return: prediction_info object
    """
    if (f_refs is None):
        f_refs = [adhesion_mask_function_for_split_fec,delta_mask_function]
    # save copies to restore...
    retract_orig = example_split.retract._slice(slice(0,None,1))
    dwell_orig = example_split.dwell._slice(slice(0,None,1))
    approach_orig =  example_split.approach._slice(slice(0,None,1))
    funcs = [ _predict_functor(example_split,f) for f in f_refs]
    final_dict = dict(remasking_functions=funcs,
                      threshold=threshold,**kwargs)
    pred_info = _predict_helper(example_split,**final_dict)
    # restore anything the filters changed.
    example_split.retract = retract_orig
    example_split.dwell = dwell_orig
    example_split.approach = approach_orig
    return pred_info

def _predict_full(example,threshold=1e-2,f_refs=None,tau_fraction=0.01,
                  **kwargs):
    """
    see predict, example returns tuple of <split FEC,prediction_info>. Except:
    
    Args:
        f_refs: list of functions for adding domain-specific information.
        Defaults to adhesion then delta mask
        **kwargs: passed to predict
    """
    example_split = Analysis.\
        zero_and_split_force_extension_curve(example,
                                             fraction=tau_fraction)            
    pred_info = _predict_split_fec(example_split,threshold,f_refs=f_refs,
                                   **kwargs)
    return example_split, pred_info

def predict(example,threshold=1e-2,add_offsets=False,**kwargs):
    """
    predict a single event from a force extension curve

    Args:
        example: TimeSepForce
        threshold: maximum probability under the no-event hypothesis
        add_offsets: if true, indices are absolute. otherwise, we offset
        into just the retract portion (after splitting into the approach,
        dwell, and retract)
    Returns:
        list of event starts
    """
    example_split,pred_info = _predict_full(example,threshold=threshold,
                                            **kwargs)
    #get the offsets for each...
    if add_offsets:
        offsets = (example_split.approach.Force.size + \
                   example_split.dwell.Force.size)
    else:
        offsets = 0
    return offsets + np.array(pred_info.event_idx)

