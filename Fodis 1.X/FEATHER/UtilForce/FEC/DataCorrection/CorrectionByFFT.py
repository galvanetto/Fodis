# force floating point division. Can still use integer with //
from __future__ import division
# This file is used for importing the common utilities classes.
import numpy as np
import matplotlib.pyplot as plt
import sys
from scipy.fftpack import rfft,irfft
from scipy.interpolate import interp1d 
from FitUtil.FitUtils.Python.FitUtil import GenFit
import copy
from Research.Perkins.AnalysisUtil.ForceExtensionAnalysis import FEC_Util


class CorrectionObject:
    def __init__(self,MaxInvolsSizeMeters = 10e-9,FractionForOffset = 0.2,
                 SpatialGridUpSample = 5,MaxFourierSpaceComponent=10e-9):
        """
        Creates a sklearn-style object for correcting data

        Args
           MaxInvolsSizeMeters: Maximum possible decay constant (in separation)
           from trigger point to zero. 
           FractionForOffset: how much of the approach/retract curve is used for
           offsetting
           SpatialGridUpSample: how much to up-sample the separation grid, to 
           get a uniform fourier series
           MaxFourierSpaceComponent: the maximum spatial component to the 
           Fourier series. This is 1/(2*f_nyquist), where f_nyquist is the
           nysquist 'frequency' (inverse sptial dimension)
        """
        self.MaxInvolsSizeMeters = MaxInvolsSizeMeters
        self.FractionForOffset = FractionForOffset
        self.SpatialGridUpSample = SpatialGridUpSample
        self.MaxFourierSpaceComponent = MaxFourierSpaceComponent
    def ZeroForceAndSeparation(self,Obj,IsApproach):
        """
        See FEC_Util.ZeroForceAndSeparation
        """
        return FEC_Util.ZeroForceAndSeparation(Obj,IsApproach,
                                               self.FractionForOffset)
    def FitInvols(self,Obj):
        """
        Fit to the invols on the (approach!) portion of Obj

        Args:
            Obj: TimeSepForceObject. We get just the approach from it and
            fit to that
        Returns:
            Nothing, but sets the object for future predicts
        """
        Approach,Retract = FEC_Util.GetApproachRetract(Obj)
        # get the zeroed force and separation
        SeparationZeroed,ForceZeroed  = self.ZeroForceAndSeparation(Approach,
                                                                    True)
        ArbOffset = max(np.abs(ForceZeroed))
        A = max(ForceZeroed)
        # adding in the arbitrary offset actually helps quite a bit.
        # we fit versus time, which also helps.
        FittingFunction = lambda t,tau :  np.log(A * np.exp(-t/tau)+ArbOffset)
        # for fitting, flip time around
        MaxTau = self.MaxInvolsSizeMeters
        params,_,_ = GenFit(SeparationZeroed,np.log(ForceZeroed+ArbOffset),
                            model=FittingFunction,
                            bounds=(0,MaxTau))
        # tau is the first (only) parameter
        self.Lambda= params[0]
        self.MaxForceForDecay = max(ForceZeroed)
    def PredictInvols(self,Obj,IsApproach):
        """
        Given an object, predicts the invols portion of its curve. *must* call
        after a fit

        Args:
            Obj: see FitInvols, except this is *either* the approach
            or retract
            IsApproach: see FitInvols
        Returns:
            Predicted, Zero-offset invols decay for Obj
        """
        SeparationZeroed,_ = self.ZeroForceAndSeparation(Obj,IsApproach)
        return self.MaxForceForDecay * np.exp(-SeparationZeroed/self.Lambda)
    def FitInterference(self,Obj):
        """
        Given a TimeSepForce Object, fits to the interference artifact

        Args:
            Obj: TImeSepForceObject
        Returns:
            Nothing, but sets internal state for future predict
        """
        Approach,_ = FEC_Util.GetApproachRetract(Obj)
        # get the zeroed force and separation
        SeparationZeroed,ForceZeroed  = self.ZeroForceAndSeparation(Approach,
                                                                    True)
        # get the residuals (essentially, no 'invols') part
        FourierComponents = max(SeparationZeroed)/self.MaxFourierSpaceComponent
        NumFourierTerms = np.ceil(FourierComponents/self.SpatialGridUpSample)
        # down-spample the number of terms to match the grid
        # get the fourier transform in *space*. Need to interpolate onto
        # uniform gridding
        N = SeparationZeroed.size
        self.linear_grid = np.linspace(0,max(SeparationZeroed),
                                       N*self.SpatialGridUpSample)
        # how many actual terms does that translate into?
        ForceInterp =interp1d(x=SeparationZeroed,
                              y=Approach.Force,kind='linear')
        self.fft_coeffs = rfft(ForceInterp(self.linear_grid))
        # remove all the high-frequecy stuff
        NumTotalTermsPlusDC = int(2*NumFourierTerms+1)
        self.fft_coeffs[NumTotalTermsPlusDC:] = 0 
    def PredictInterference(self,Obj,IsApproach):
        """
        Given a previous PredictIntereference, returns the prediction of the 
        fft (ie: at each spatial point in Obj.Force, returns the prediction)

        Args:
           Obj: See FitInterference
           IsApproach: True if we are predicting the approach
        Returns:
           prediction of fft coefficients
        """
        # interpolate back to the original grid
        SeparationZeroed,_  = self.ZeroForceAndSeparation(Obj,
                                                          IsApproach)
        N = SeparationZeroed.size
        fft_representation = irfft(self.fft_coeffs)
        MaxGrid = np.max(self.linear_grid)
        # should only interpolate (correct) out to however much approach
        # data we have
        GoodInterpolationIndices = np.where(SeparationZeroed <= MaxGrid)
        BadIdx = np.where(SeparationZeroed > MaxGrid)
        fft_pred = np.zeros(SeparationZeroed.size)
        # determine the interpolator -- should be able to use everywhere
        # we are within range
        GoodInterpolator = interp1d(x=self.linear_grid,y=fft_representation)
        fft_pred[GoodInterpolationIndices] =\
            GoodInterpolator(SeparationZeroed[GoodInterpolationIndices])
        # everything else just gets the DC offset, which is the 0-th component
        fft_pred[BadIdx] = fft_representation[0]
        return fft_pred
    def CorrectApproachAndRetract(self,Obj):
        """
        Given an object, corrects and returns the approach and retract
        portions of the curve (dwell excepted)

        Args:
            Obj: see FitInterference
        Returns:
            Tuple of two TimeSepForce Objects, one for approach, one for 
            Retract. Throws out the dwell portion
        """
        Approach,Retract = FEC_Util.GetApproachRetract(Obj)
        SeparationZeroed,ForceZeroed = self.\
                    ZeroForceAndSeparation(Approach,IsApproach=True)
        # fit the interference artifact
        self.FitInterference(Approach)
        fft_pred = self.PredictInterference(Approach,
                                            IsApproach=True)
        # make a prediction without the wiggles
        Approach.Force -= fft_pred
        # just for clarities sake, the approach has now been corrected
        ApproachCorrected = Approach
        RetractNoInvols = Retract
        fft_pred_retract = self.PredictInterference(RetractNoInvols,
                                                    IsApproach=False)
        RetractCorrected = copy.deepcopy(RetractNoInvols)
        RetractCorrected.Force -= fft_pred_retract
        return ApproachCorrected,RetractCorrected
