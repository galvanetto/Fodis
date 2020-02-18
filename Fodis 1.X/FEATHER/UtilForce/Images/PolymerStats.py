# force floating point division. Can still use integer with //
from __future__ import division
# other good compatibility recquirements for python3
from __future__ import absolute_import
from __future__ import print_function
from __future__ import unicode_literals
# This file is used for importing the common utilities classes.
import numpy as np
import matplotlib.pyplot as plt
import sys, scipy, copy

from scipy.interpolate import splprep, splev, interp1d, UnivariateSpline

from scipy.stats import binned_statistic

from skimage.morphology import skeletonize, medial_axis, dilation
from skimage import measure
from scipy.interpolate import LSQUnivariateSpline
from skimage.segmentation import active_contour
from skimage.filters import gaussian

class spline_info(object):
    # holds low-level information on the actual fitting used. Everything
    # is in units of pixels
    def __init__(self, u, tck, spline, deriv,x0_px,y0_px):
        self.u = u
        self.tck = tck
        self.spline = spline
        self.deriv = deriv
        self.x0_px = x0_px
        self.y0_px = y0_px

class angle_info(object):
    def __init__(self,theta,L_px):
        self.theta = theta
        self.L_px = L_px
    @property
    def cos_theta(self):
        return np.cos(self.theta)


class polymer_info(object):
    # holds low-level information about the polymer itself
    def __init__(self,theta,cos_theta,
                 L_m,Lp_m,L0_m,L_binned,cos_angle_binned,coeffs):
        self.L_m = L_m
        self.theta = theta
        self.cos_angle = cos_theta
        self.Lp_m = Lp_m
        self.L0_m = L0_m
        self.L_binned = L_binned
        self.cos_angle_binned = cos_angle_binned
        self.coeffs = coeffs


def sorted_concatenated_x_and_y_lists(x_y):
    """
    Args:
        x_y: list, each element is x,y
    Returns:
        tuple of concatenated x, concatenated y
    """
    cat = lambda i: np.concatenate([x[i] for x in x_y])
    x = cat(0)
    y_list = [cat(i) for i in range(1, len(x_y[0]))]
    # sort by contour length
    sort_idx = np.argsort(x)
    return [x[sort_idx]] + [y[sort_idx] for y in y_list]


def get_region_of_interest(height_cropped_nm, background_image,
                           threshold_nm=0.0):
    """
    Returns: single-region of interest

    Args:
        height_cropped_nm: image, elements are in nm
        background_image: value considered the background for height_cropped_nm
        thresold_nm: for thresholding, the minimum above the background
        to be considered not noise

    Returns:
        image, same shape as height_cropped_nm. everything not in the largest
        skeleton region is set to zero
    """
    # threshold anything less than x nM
    image_thresh = height_cropped_nm.copy()
    image_thresh[np.where(image_thresh < background_image + threshold_nm)] = 0
    # binarize the image
    image_binary = image_thresh.copy()
    image_binary[np.where(image_binary > 0)] = 1
    # skeletonize the image
    image_skeleton = skeletonize(image_binary)
    image_label = measure.label(image_skeleton, background=0)
    props = measure.regionprops(image_label)
    diameters = [p.equivalent_diameter for p in props]
    # XXX just use x,y, dialyze that?
    assert len(diameters) > 0, "Couldn't find any objects in region"
    max_prop_idx = np.argmax(diameters)
    largest_skeleton_props = props[max_prop_idx]
    # zero out everything not the one we want
    skeleton_zeroed = np.zeros(image_thresh.shape)
    # take the largest object in the view, zero everything else
    # order the points in that object by the x-y point
    x_skel = largest_skeleton_props.coords[:, 0]
    y_skel = largest_skeleton_props.coords[:, 1]
    for x_tmp, y_tmp in zip(x_skel, y_skel):
        skeleton_zeroed[x_tmp, y_tmp] = 1
    # dilated skeleton; make it 'fat'
    dilation_size = 3
    selem = np.ones((dilation_size, dilation_size))
    skeleton_zeroed = dilation(skeleton_zeroed, selem=selem)
    # mask the original data with the skeletonized one
    image_single_region = skeleton_zeroed * height_cropped_nm
    return image_single_region


def _binned_stat(x, y, bins, **kw):
    """
    Args:
        x,y: the x and y values to fit
        n_bins: the uniform number of bins to use to bin y onto x
        **kw: passed to binned_statistic
    Returns:
        tuple of <x bins, y statistics>
    """
    stat_y, x, _ = binned_statistic(x=x, values=y, bins=bins, **kw)
    # skip the right bin
    x = x[:-1]
    return x, stat_y


def theta_i(theta, i):
    return theta ** i


def theta_stats(polymer_info_obj, n_bins):
    theta = polymer_info_obj.theta
    x = polymer_info_obj.L_m
    fs = [theta_i(theta, i)
          for i in range(1, 5)]
    kw = dict(x=x, n_bins=n_bins)
    x_ys = [_binned_stat(y=f, **kw) for f in fs]
    x = x_ys[0][0]
    thetas = [tmp[1] for tmp in x_ys]
    return [x] + thetas


def L_and_mean_angle(L,cos_angle, bins, min_cos_angle=np.exp(-2)):
    """
    Gets L and <cos(theta(L))>

    Args:
        L: length N, element i is contour length between same segments as
        cos_angle
        cos_angle: length N, element i is angle between two segmens

        n_bins: we will average cos_angle in this many bins from its min to max

        min_cos_angle: we cant use when <cos(Theta)> <= 0,since that would go
        negative when we take a log. So, only look where above this value

    Returns:
       tuple of L_[avg,j],<Cos(Theta_[avg,j])>, where j runs 0 to n_bins-1
    """

    # last edge is right bin
    edges, mean_cos_angle = _binned_stat(x=L, y=cos_angle, bins=bins)
    # filter to the bins with at least f% of the total size
    values, _ = np.histogram(a=L, bins=edges)
    bins_with_data = np.where(values > 0)[0]
    assert bins_with_data.size > 0
    mean_cos_angle = mean_cos_angle[bins_with_data]
    edges = edges[bins_with_data]
    # only look at where cos(theta) is reasonable positive, otherwise we
    # cant take a log. This amounts to only looking in the upper quad
    good_idx = np.where((mean_cos_angle > min_cos_angle))[0]
    assert good_idx.size > 0
    sanit = lambda x: x[good_idx]
    mean_cos_angle = sanit(mean_cos_angle)
    edges = sanit(edges)
    assert edges.size > 0, "Couldn't find data to fit"
    return edges, mean_cos_angle


def Lp_log_mean_angle_and_coeffs(L, mean_cos_angle):
    """
    :param L: the lengths
    :param mean_cos_angle: <Cos(theta(L)>
    :return:  persistence length, -Log(<Cos(Theta(L))), and linear polynomial
    coefficients for a given <Cos(Theta(L))>
    """
    log_mean_angle = -np.log(mean_cos_angle)
    # fit to -log<Cos(angle)> to edges_nm
    coeffs = np.polyfit(x=L, y=log_mean_angle, deg=1)
    persistence_length = 1 / coeffs[0]
    return persistence_length, log_mean_angle, coeffs

def contour_lengths(x,y):
    """
    :param x: x location at index i, size N
    :param y: y location at index i, size N
    :return: contour_length[j], the total contour length up to index j
    """
    # POST: unit vector are normalized, |v| = 1
    dx_spline = np.array([0] + list(np.diff(x)))
    dy_spline = np.array([0] + list(np.diff(y)))
    # d_spline(i) is the change from i-i to i (zero if i=0)
    d_spline = np.sqrt(dx_spline ** 2 + dy_spline ** 2)
    assert (dx_spline <= d_spline).all()
    contour_lengths = np.cumsum(d_spline)
    return contour_lengths

def angle_differences(x_deriv,y_deriv):
    """
    :param x_deriv: the x derivatives (or dx/dt) at index i, size N
    :param y_deriv: the y derivatives (or dy/dt) as index i, size N
    :return: ThetaMatrix (i,j), angle between between locations i and j
    """
    deriv_unit_vector = np.array((x_deriv, y_deriv))
    deriv_unit_vector /= np.sqrt(np.sum(np.abs(deriv_unit_vector ** 2), axis=0))
    deriv_unit_vector[np.where(np.isnan(deriv_unit_vector))] = 0
    assert ((np.sum(deriv_unit_vector ** 2, axis=0) - 1) < 1e-6).all(), \
        "Unit vectors not correct"
    dx_deriv = deriv_unit_vector[0, :]
    dy_deriv = deriv_unit_vector[1, :]
    angle2 = np.arctan2(dy_deriv, dx_deriv)
    angle_diff_matrix = _difference_matrix(angle2.T, angle2.T)
    # normalize to 0 to 2*pi
    where_le_0 = np.where(angle_diff_matrix < 0)
    angle_diff_matrix[where_le_0] += 2 * np.pi
    assert ((angle_diff_matrix >= 0) & (angle_diff_matrix <= 2 * np.pi)).all()
    return angle_diff_matrix

def lengths_and_angles(spline,spline_derivative):
    """
    gets Cos(Theta(i)) and L(i), where i runs along the spline order given,
    and L is the contour length between segments chosen at index i

    Args:
        spline: tuple of x_spline,y_spline -- x and y values of the line, size N
        deriv: the continuous derivative of spline, size N
    Returns:
        tuple of L(i),Cos(Theta(L(i))). Note that L0 = max(L(i)), where i is
        an index running over all possible non-redudant differences.
    """
    # get the x and y coordinates of the spline
    x_spline, y_spline = spline
    x_deriv, y_deriv = spline_derivative
    L_contour = contour_lengths(x_spline, y_spline)
    n = L_contour.size
    contour_length_matrix = _difference_matrix(L_contour, L_contour)
    angle_diff_matrix = angle_differences(x_deriv, y_deriv)
    # POST: angles calculated correctly...
    # only look at the upper triangular part
    idx_upper_tri = np.triu_indices(n)
    idx_upper_tri_no_diag = np.triu_indices(n, k=0)
    # upper diagonal should have >0 contour length
    assert (contour_length_matrix[idx_upper_tri_no_diag] >= 0).all(), \
        "Contour lengths should be non-negative"
    # POST: contour lengths and angles make sense; we only want upper triangular
    # (*including* the trivial 0,0 point along the diagonal)
    sanit = lambda x: x[idx_upper_tri].flatten()
    sort_idx = np.argsort(sanit(contour_length_matrix))
    sanit_and_sort = lambda x: sanit(x)[sort_idx]
    # return everything sorted as per sort_idx
    flat_L = sanit_and_sort(contour_length_matrix)
    flat_angle = np.arccos(np.cos(sanit_and_sort(angle_diff_matrix)))
    return flat_L,flat_angle


def _difference_matrix(v1, v2):
    """
    Args:
        v<1/2>: the two vectors to subtract, size n and m
    Returns:
        matrix, size n X m, element i,j  is v1[j]-v2[i]
    """
    return (v2 - v1[:, np.newaxis])


def _dot_matrix(v1, v2):
    """
    Args:
        see _difference_matrix
    Returns:
        matrix M, where element i,j is v1[i] . v2[j]
    """
    return np.dot(v1, v2.T)
