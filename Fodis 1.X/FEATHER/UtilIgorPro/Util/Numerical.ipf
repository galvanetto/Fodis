// Use modern global access method, strict compilation
#pragma rtGlobals=3	

#include ":ErrorUtil"
#pragma ModuleName = ModNumerical

// Default fraction of points for smoothing in savitsky golay
// Effectively filters to f_unfiltered*(DEF_SG_POINT_FRACTION)
Static Constant DEF_SG_POINT_FRACTION = 0.01
// By default, use second order SG
Static Constant DEF_SG_ORDER = 2
// Min and max of savitsky golay; must *also* take into account order
Static Constant SG_MAX_POINTS = 32767
Static Constant SG_MIN_POINTS = 3 // plus the order gives the minimim

Static Function safe_savitsky_smooth_n(raw_factor,order)
	// Turns a raw number into a safe number to use for the savitsky golay filteing
	// must between [SG_MIN_POINTS+order,SG_MAX_POINTS] and be odd
	//
	// Args:
	//	raw_factor: the factor we want
	//	order: the order we want
	// Returns;
	//	the closest thing to raw_factor (rounded up) we can use
	Variable raw_factor,order
	// First of all, we must have an integer
	Variable toRet  = ceil(raw_factor)
	toRet= max(SG_MIN_POINTS+order,toRet)
	toRet = min(toRet,SG_MAX_POINTS)
	// nPoints must be odd for savitsky golay to work
	// Note that this in combination with the ceiling might change the time constant
	// this should only be noticable is the time constant is on 
	// Note also that if we are even, we are guarenteed NOT to be at the min or max (both are odd)
	if (mod(toRet,2) == 0)
		toRet +=1
	EndIf
	return toRet
End Function

Static Function savitsky_smooth(to_smooth,[n_points,order])
	// smoothes to_smooth (! in place) using an order-th order savitsky
	// golay with n_points number of points
	//
	// Args:
	//	to_smooth: wave to smooth
	//	order: of the filter
	// Returns:
	//	nothing, but overwrites the original wave 
	Wave to_smooth
	Variable n_points,order
	Variable maxN = DimSize(to_smooth,0)
	n_points = ParamIsDefault(n_points) ? ceil(DEF_SG_POINT_FRACTION*maxN) : n_points
 	order = ParamIsDefault(order) ? DEF_SG_ORDER : order
	n_points = safe_savitsky_smooth_n(n_points,order)
	// /S: savitsky golay polynomial order, 2 or 4
	// Smooth, V-592:
	Smooth /S=(order) (n_points),to_smooth
End Function

Static Function first_index_greater(wave_x,level)
	// Find the first index where wave_x is greater than level
	//
	// Args:
	//	wave_x: the wave we are interested in 
	// 	level: the crossing level 
	// Returns:
	//	index where the wave crossed
	
	// Arguments to FindLevel:
	// /B=1: do no averaging
	// /EDGE=1: only where levels are increasing
	// /Q: quit run 
	// /P: return value as points (instead of as x value)
	Wave wave_x
	Variable level
	FindLevel /B=1 /EDGE=1 /Q /P wave_x, level
	ModErrorUtil#assert(V_flag == 0,msg="wave never crossed given level")
	// POST: found a crossing.
	return round(V_LevelX)
End Function