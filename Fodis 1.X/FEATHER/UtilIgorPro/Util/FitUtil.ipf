// Use modern global access method, strict compilation
#pragma rtGlobals=3	

#pragma ModuleName = ModFitUtil

 // V-88
 // N=1: don't update during the fit
 // /W=2: dont display any results for the curve fitting
 // /Q: quiet, dont print
Static Constant CURVEFIT_DEF_N_SILENT = 1
Static Constant CURVEFIT_DEF_W_SILENT = 1


Static Constant POLY_DEF_DEG = 40

// Find the intersection of
// y=a0*(x-offset0)+b0
// y=a1*(x-offset1)+b1
// a0*(x-offset0) - a1*(x-offset1) = b1 - b0
// a0*x-a1*x  = b1 - b0 + a0*offset0-a1*offset1
// x = (b1 - b0 + a0*offset0-a1*offset1)/(a0-a1)
// XXX add in offset support?
Static Function LineIntersect(a0,b0,a1,b1,[offset0,offset1])
	Variable a0,b0,a1,b1,offset0,offset1
	Variable toRet =  (b1-b0)/(a0-a1)
	return toRet
End Function




// fits line a*x+b =y, passes b and a by *references*
// if no y is found, then fits just to the indices of X
Static Function LinearFit(mY,slope,intercept,[mX])
	Wave mY,mX
	Variable &slope,&intercept
	 // line means a linear fit..
	 Make /O/N=(2) fitCoeffs
	if (!ParamIsDefault(mX))
		 CurveFit /N=(CURVEFIT_DEF_N_SILENT)/Q/W=(CURVEFIT_DEF_W_SILENT) line, kwCWave=fitCoeffs, mY /X=mX
	else
		CurveFit /N=(CURVEFIT_DEF_N_SILENT)/Q/W=(CURVEFIT_DEF_W_SILENT) line, kwCWave=fitCoeffs, mY
	EndIf
	// POST: the coefficients are populated
	intercept = fitCoeffs[0]
	slope = fitCoeffs[1]
	// Kill the wave we used
	KillWaves /Z fitCoeffs
End Function
