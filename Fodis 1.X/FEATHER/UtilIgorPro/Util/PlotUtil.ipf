// Use modern global access method, strict compilation
#pragma rtGlobals=3	

#pragma ModuleName = ModPlotUtil
#include ":IoUtil"
#include ":ErrorUtil"
#include ":FitUtil"
#include ":Numerical"

Constant  ColorMax = 65535
Constant PredefinedColors = 7
// Constants for making the figure
Constant DEF_DISP_H_HIDE = 1 // Don't show the window by default; assume we are saving
Constant DISP_HIDE_SHOW_WINDOW = 0 // show the window
Constant DISP_HIDE_HIDE_WINDOW = 1 // dont Sshow the window
Constant DEF_DISP_DPI = 400 // Dots per Inch
Constant DEF_DISP_HEIGHT_IN = 12 // Inches
Constant DEF_DISP_WIDTH_IN = 10 // Inches
// Based on 10-8-2015, ModfiyGraph --> Width(Left) --> 1, looks like command is based on 1 -> 72
Constant IGOR_DPI = 72
Constant DEF_MODGRAPH_WIDTH=36
StrConstant DEF_FONT_NAME = "Monaco" // Nice and monospaced
// Constants for saving the figure
// See: SavePICT, pp 558 of igor manual
Constant DEF_FIG_TRANSPARENT = 0
Constant DEF_FIG_GFX_FMT = -5 // uses PNG
Static StrConstant DEF_FIG_SAVEFILE_EXTENSION = ".png"
Constant DEF_FIG_CLOSE_ON_SAVE =1 // True. XXX wll need to be changed if true changes
StrConstant DEF_FIG_SAVEPATH = "home"
// Default Graph name; Gets the uniqueName
StrConstant DEF_DISP_NAME = "UtilDisp"
// XXX move to util?
//  pp 729 of igor pro, UniqueName object type for graph
Constant DEF_UNINAME_GRAPH = 6 
// Constants for graph font defaults
Constant DEF_FONT_TITLE = 24
Constant DEF_FONT_AXIS = 24
Constant DEF_FONT_TICK_LABELS = 20
Constant DEF_FONT_LEGEND = 16
// TextBox, p 710 of igor manual
Constant DEF_TBOX_FRAME = 0 // Default, no Frame.
// For identifying the axes / general methods
StrConstant X_AXIS_DEFLOC = "bottom"
StrConstant Y_AXIS_DEFLOC = "left"
// TraceNameList: optionsflag, igor manual V-726
// Include normal graph traces, do *not* omit hidden traces
Constant TRACENAME_INCLUDE_ALL = 3
// Drawlayer graph,, V-571
StrConstant DRAW_LAYER_GRAPH = "UserFront"
// WinList,  V-758
StrConstant WINLIST_GRAPHS = "WIN:1" // kills all graphs
// See AppendToGraph V-28 and 'Notebooks as Subwindows in Control Panels' in III-96:
// This is the delimiter to separator a subwindow from its parent
Static StrConstant DELIM_SUBWINDOW = "#"
// Defined color strings
// For the major colors, we also allow 
Static StrConstant COLOR_ABBR_RED = "r"
Static StrConstant COLOR_ABBR_GREEN = "g"
Static StrConstant COLOR_ABBR_BLUE = "b"
Static StrConstant COLOR_ABBR_BLACK = "k"
Static StrConstant COLOR_ABBR_PURPLE = "m"
Static StrConstant COLOR_ABBR_ORANGE = "o"
Static StrConstant COLOR_ABBR_WHITE = "w"
Static StrConstant COLOR_ABBR_GREY = "grey"
Static Constant DEF_AXLINE_WIDTH = 2.0

// See: ModifyGraph, V-415:
Static StrConstant  MARKER_DOTTED_LINE = "--"
Static StrConstant MARKER_NO_LINE = ""
Static StrConstant MARKER_LINE = "-"
Static StrConstant MARKER_POINTS = "."
Static StrConstant MARKER_SCATTER_CIRCLE = "o"
Static StrConstant MARKER_SCATTER_PLUS = "+"
Static StrConstant MARKER_SCATTER_SQUARE = "s"
Static StrConstant MARKER_SCATTER_DIAMOND = "d"
Static StrConstant MARKER_SCATTER_TRIANGLE = "^"
Static StrConstant MARKER_NONE= ""
// Seee II-253 for defintiion of shapes
Static Constant MARKERMODE_PLUS = 0
Static Constant MARKERMODE_SQUARE = 5
Static Constant MARKERMODE_TRIANGLE = 6
Static Constant MARKERMODE_DIAMOND = 7
Static Constant MARKERMODE_CIRCLE = 8
Static Constant MARKERMODE_NONE_SPECIFIED = 63 // greater than the maximum number
// Anything else (besides above markers) is a combination
Static Constant GRAPHMODE_LINES_BETWEEN_POINTS = 0 
Static Constant GRAPHMODE_DOTS_AT_POINTS = 2
Static Constant GRAPHMODE_MARKERS = 3
Static Constant GRAPHMODE_LINES_AND_MARKERS = 4
// Dottd lystyle (ModifyGraph)
Static Constant PLOT_LSTYLE_DOTTED = 7
// Default line width, in pixells
Static Constant DEF_LINE_WIDTH = 2
Static Constant DEF_MARKER_SIZE = 4
// Color mapping.
Static StrConstant DEF_CMAP = "Greys"
// Window separator
Static StrConstant WINDOW_SEP = "#"
// Default Alpha 
Static Constant DEF_ALPHA = 0.8
// For setDrawEnv, we have dash and solid patterns 
// V-567,  ' SetDashPattern'
Static Constant DEF_LINE_PATTERN_DASHED = 8 // Pattern looks like "- - - -"
Static Constant DEF_LINE_PATTERN_SOLID = 0      // Pattern looks like "_____"
Static StrConstant DEF_AX_V_OR_H_LINE = "--" // default to dotted for dashed line 
// The default decimation factor to filter data with, relative to the bandwith of the data. 
// If "N" is the number of datapoints, then we use "N*factor" for smoothing (ceiling to the minimum size)
Static Constant DEF_SMOOTH_FACTOR =0.01
// Locations for text box anchor points
StrConstant ANCHOR_TOP_RIGHT = "RT"
StrConstant ANCHOR_BOTTOM_RIGHT = "RB"
StrConstant ANCHOR_BOTTOM_MIDDLE = "MB"
StrConstant ANCHOR_TOP_MIDDLE = "MT"
StrConstant ANCHOR_TOP_LEFT = "LT"
StrConstant ANCHOR_BOTTOM_LEFT = "LB"
// Constant for separating legend labels
StrConstant PLOT_UTIL_DEF_LABEL_SEP = ","
// For drawing lines and rectangles...
Static Constant TYPE_DRAW_LINE = 0
Static Constant TYPE_DRAW_RECT =  1
// ModifyGraph for axies
Static Constant AXIS_SUPRESS_LABEL= 1
// Default number of ticks for the axes...
Static Constant DEF_NUM_TICKS = 5

Constant DEF_LABEL_MARGIN = 17
Constant DEF_LABEL_MODE = 2 // This is margin sclaled

Structure PlotObj
	Wave X
	Wave Y
	String mColor
	String formatMarker 
	Variable linewidth 
	Variable markersize
	String mLabel
	String mXLabel
	String mYLabel
	String mTitle
	String mGraphName
	Variable alpha
	Variable hasX
	Variable hasY
	Variable soften
EndStructure



Static StrConstant NANO = "n"
Static StrConstant PICO = "p"
Static StrConstant MICRO = "u"
Structure PlotFormat
	// RGB color
	Struct RGBColor rgb
	// transparency
	Variable alpha	
	// Line style
	Variable DashPattern
	// thickness
	Variable Thickness
	// XXX probably want to add in a 'give legend' or something
	// like that.
EndStructure

// Defines for plotting (XXX move to plotUtil?
Structure ColorMapDef
	// Color Maps
	String GREY 
	String TERRAIN 
	String HEAT
EndStructure

Structure ColorDefaults
	// Red, Yellow, Green
	Struct RGBColor Red
	Struct RGBColor Gre
	Struct RGBColor Blu
	Struct RGBColor Yel
	Struct RGBColor Bla
	Struct RGBColor Pur
	Struct RGBColor Ora
	Struct RGBColor AllColors[PredefinedColors]
EndStructure

Structure pWindow
	Variable width,height
	Variable Left,Top,Right,Bottom
EndStructure

Static Function InitPlotObj(toInit,[X,Y,mColor,marker,linewidth,markersize,mLabel,mXLabel,mYLabel,mTitle,mGraphName,alpha,soften])
	Struct PlotObj & ToInit
	// all the arguments for the plotting object
	Wave X
	Wave Y
	String mColor
	String marker 
	Variable linewidth 
	Variable markersize
	String mLabel
	String mXLabel
	String mYLabel
	String mTitle
	String mGraphName
	Variable alpha,soften
	// Initialize the structure
	if (ParamIsDefault(X))
		ToInit.hasX = ModDefine#False()
	else
		ToInit.hasX = ModDefine#True()
		ToInit.X = X
	EndIf
	if (ParamIsDefault(Y))
		ToInit.hasY = ModDefine#False()
	else
		ToInit.hasY = ModDefine#True()
		ToInit.Y = Y
	EndIf
	ToInit.mColor = mColor
	ToInit.linewidth  = linewidth
	ToInit.markersize = markersize
	ToInit.alpha = alpha
	if (!ParamIsDefault(mColor))
		ToInit.mColor  = mColor
	EndIf
	if (!ParamIsDefault(marker))
		ToInit.formatMarker  = marker
	EndIf
	if (!ParamIsDefault(mLabel))
		ToInit.mLabel = mLabel
	EndIf
	if (!ParamIsDefault(mXLabel))
		ToInit.mXLabel = mXLabel
	EndIf
	if (!ParamIsDefault(mYLabel))
		ToInit.mYLabel = mYLabel
	EndIf
	if (!ParamIsDefault(mTitle))
		ToInit.mTitle = mTitle
	EndIf
	if (!ParamIsDefault(mGraphName))
		ToInit.mGraphName = mGraphName
	EndIf	
	if (!ParamIsDefault(soften))
		ToInit.soften = soften
	endIf	
	// XXX add in structure noting if things are default?
End Function

Static Function /S SetRGBString(r,g,b,[roundToInt])
	Variable r,g,b
	Variable roundToInt
	String toRet
	roundToInt = ParamIsDefault(roundToInt) ? ModDefine#False() : roundToInt
	if (!roundToInt)
		sprintf toRet,"%.4f,%.4f,%.4f",r,g,b
	else
		sprintf toRet,"%d,%d,%d",r,g,b
	endIf
	return toRet
End Function

// Assume CSV numbers between 0 and 1, gets them as numbers
// Returns true/false if it could find the strings or not.
Static Function ParseRGBFromString(mStr,r,g,b)
	String mStr
	variable &r,&g,&b
	// possible numbers, followed by possible literal dot, followed by possible numbers and comma, repeated 3x
	String numberRegex = "(\d*\.?\d*)"
	// delimited by spaces and/or commas
	String delimRegex = "[\s,]+"
	String mRegex = numberRegex + delimRegex + numberRegex + delimRegex + numberRegex
	String rStr,gStr,bStr
	if (GrepString(mStr,mRegex))
		SplitString /E=(mRegex) mStr, rStr,gStr,bStr
		r = str2num(rStr)
		g = str2num(gStr)
		b = str2num(bStr)
		return ModDefine#True()
	else
		return ModDefine#False()
	EndIf
End Function

Static Function GetRGBFromString(mStr,r,g,b)
	String mStr
	Variable &r,&g,&b
	Struct RgbColor mRgb
	strSwitch (mStr)
		case COLOR_ABBR_RED:
			initRed(mRgb)
			break
		case COLOR_ABBR_GREEN: 
			initGreen(mRgb)
			break
		case COLOR_ABBR_BLUE:
			initBlue(mRgb)
			break
		case COLOR_ABBR_BLACK:
			initBlack(mRgb)
			break
		case COLOR_ABBR_PURPLE :
			initPurple(mRgb)
			break
		case COLOR_ABBR_ORANGE:
			initOrange(mRgb)
			break
		case COLOR_ABBR_GREY:
			initGrey(mRgb)
			break
		case COLOR_ABBR_WHITE:
			initWhite(mRgb)
			break
		default:	
			// make one last check for csv-separated normalized numbers
			if (!ParseRGBFromString(mStr,r,g,b))
				String mErr
				sprintf mErr,"Color code [%s] wasn't recognized",mStr
				ModErrorUtil#DevelopmentError(description=mErr)
			EndIF
			// Else: We can initialize the rgb
			InitRGB_Dec(mRgb,r,g,b)
	EndSwitch
	// POST: have the proper colors in RGB
	// set the colors (by reference)
	r = mRgb.red
	b = mRgb.blue
	g = mRgb.green
End Function

Static Function GetMarker(MarkerString)
	String MarkerString
	Make /O/T mMarkerRegex = {MARKER_SCATTER_CIRCLE ,MARKER_SCATTER_PLUS,MARKER_SCATTER_SQUARE,MARKER_SCATTER_DIAMOND,MARKER_SCATTER_TRIANGLE}
	Variable i,nMarkers=DimSize(mMarkerRegex,0)
	String mMarker = MARKER_NONE
	for (i=0; i<nMarkers; i+=1)
		String tmpMarker = mMarkerRegex[i]
		if (strsearch(MarkerString,tmpMarker,0) >= 0)
			mMarker = tmpMarker
			break
		EndIf
	EndFor
	// POST: mMarker is set by either the method or in the inner loop
	Variable mMarkerToRet
	strswitch (mMarker)
		case MARKER_SCATTER_CIRCLE:
			mMarkerToRet = MARKERMODE_CIRCLE
			break
		case MARKER_SCATTER_PLUS:
			mMarkerToRet = MARKERMODE_PLUS
			break
		case MARKER_SCATTER_SQUARE:
			mMarkerToRet = MARKERMODE_SQUARE
			break
		case MARKER_SCATTER_DIAMOND:
			mMarkerToRet = MARKERMODE_DIAMOND
			break
		case MARKER_SCATTER_TRIANGLE:
			mMarkerToRet = MARKERMODE_TRIANGLE
			break
		default:
			// set to an out-of-bounds marker
			// XXX throw error? OK if just line..
			mMarkerToRet = MARKERMODE_NONE_SPECIFIED
			break
	EndSwitch
	KillWaves /Z mMarkerRegex
	return mMarkerToRet
End Function

Static Function IsDottedFormat(MarkerString)
	String MarkerString
	return GrepString(MarkerString,MARKER_DOTTED_LINE)
End Function

Static Function IsSolidLine(MarkerString)
	String MarkerString
	return GrepString(MarkerString,MARKER_LINE)
End Function

Static Function GetTraceDisplayMode(MarkerString,markerMode)
	String MarkerString
	Variable markerMode
	Variable ModeToRet
	strswitch (MarkerString)
		// dotted lines and marker lines are both lines
		case MARKER_DOTTED_LINE:
		case MARKER_LINE:
			ModeToRet = GRAPHMODE_LINES_BETWEEN_POINTS
			break
		// just points
		case MARKER_POINTS:
			ModeToRet = GRAPHMODE_DOTS_AT_POINTS
			break
		default:
			// first, check and see if we are a line connecting markers
			Variable isDotted =IsDottedFormat(MarkerString)
			Variable isLine =  IsSolidLine(MarkerString)
			Variable validMarker = markerMode !=MARKERMODE_NONE_SPECIFIED
			if ( (isDotted || isLine) && validMarker)
				// then we are dotted or with a line, with a marker
				// This eans we set the mode to markers *and* lines
				ModeToRet = GRAPHMODE_LINES_AND_MARKERS
			elseif (validMarker)
				// NO lines, but a valid marker.
				ModeToRet = GRAPHMODE_MARKERS
			else
				// something bad happended; we either have a weird marker or aren't dotted
				String mErr
				sprintf mErr,"Couldn't find string related to %s\r",MarkerString
				ModErrorUtil#DevelopmentError(description=mErr)
			EndIf	
			break
	EndSwitch
	// POST: ModeToRet has the mode we want
	return ModeToRet
End Function

Static Function PlotGen(mObj)
	Struct PlotObj & mObj
	// XXX switch; could also put in r,g,b default?
	String mColor = mObj.mColor
	// set up the red,green, and blue colors
	Variable r,g,b
	if (mObj.soften)
		mColor = SoftenColorRGBString(mColor)
	endIf
	// get the read rgb
	GetRGBFromString(mColor,r,g,b)
	String mWinName = mObj.mGraphName
	if (mObj.hasX)
		AppendToGraph /W=$(mWinName) /C=(r,g,b) mObj.Y vs mObj.X 
	Else
		AppendToGraph /W=$(mWinName) /C=(r,g,b) mObj.Y	
	EndIf
	// POST: plotted correctly. Now need to modify the traces accordingly
	// Get the marker we will use (if any)
	Variable mMarker = GetMarker(mObj.formatMarker)
	// Get the trace display mode
	Variable mMode = GetTraceDisplayMode(mObj.formatMarker,mMarker)
	// Set the marker, if we have one
	//ModifyGraph expects trace names, not wave references.
	// See Trace Name Parameters on page IV-72
	String mTraceName  = NameOfWave(mObj.Y)
	if (mMarker != MARKERMODE_NONE_SPECIFIED)
		ModifyGraph /W=$(mWinName) marker($mTraceName)=mMarker
	EndIf
	if (IsDottedFormat(mObj.formatMarker))
		ModifyGraph /W=$(mWinName) lstyle($mTraceName)=(PLOT_LSTYLE_DOTTED)	
	EndIf
	// Set the display mode
	ModifyGraph /W=$(mWinName) mode($mTraceName)=(mMode)
	// Set the line width
	ModifyGraph /W=$(mWinName) lSize($mTraceName)=(mObj.linewidth)	
	// Set the marker size
	ModifyGraph /W=$(mWInNAme) msize($mTraceName)=(mObj.markersize)
	Variable rawAlpha = mObj.alpha
	// Get alpha in the appropriate bounds
	Variable safeAlpha = max(rawAlpha,0)
	safeAlpha = min(safeAlpha,1)
	ModifyGraph /W=$(mWInName) opaque($mTraceName)=(safeAlpha)
	// Make the plot easier to look at; igor's default formatting sucks.
	PlotBeautify(graphName=mWinName)
End Function

Static Function ColorTableIsValid(mColor)
	String mColor
	String mList = CTabList()
	// Is the color table in the color table list?
	return (strsearch(mList,mColor,0) >=0)
End Function


Static Function SwapAxis([graphName])
	String graphNAme
	if (ParamIsDefault(graphName))
		graphName = gcf()
	EndIf
	ModifyGraph /W=$(graphName) swapXY=(ModDefine#True())
End Function
// Y: y to plot
// Everything else is optional
// mX: what to plot against; defaults to X of Y
// graphName: which graph
// ...
// alpha: transparency. 0 --> transparent, 1 --> opaque
Static Function Plot(Y,[mX,alpha,graphName,color,marker,linestyle,linewidth,markersize,soften])
	Wave mX,Y
	String graphName,color,marker,linestyle
	Variable  linewidth,markersize,alpha,soften
	Variable nPoints = DimSize(Y,0)
	if (ParamIsDefault(color))
		color = COLOR_ABBR_BLUE
	EndIf
	if (ParamIsDefault(graphName))
		graphName = gcf()
	EndIf
	if (ParamIsDefault(alpha))
		alpha = DEF_ALPHA
	EndIF
	if (ParamIsDefault(marker))
		marker = MARKER_NONE
	EndIF
	if (PAramIsDefault(linestyle))
		linestyle =MARKER_LINE
	EndIf
	markersize = ParamIsDefault(markersize) ? DEF_MARKER_SIZE  : markersize
	linewidth = ParamIsDefault(linewidth) ? DEF_LINE_WIDTH : linewidth	
	soften = ParamIsDefault(soften) ? ModDefine#False() : soften
	Struct PlotObj mObj
	// If no x was given, note it. Otherwise, save the X..
	if (!ParamIsDefault(mX))
		Wave mObj.X = mX
		mObj.hasX = MOdDefine#True()
	Else
		mObj.hasX = MOdDefine#False()
	EndIf
	// POST: all parameters are set
	// Wrap up everything in the object that plotGen expects
	Wave mObj.Y = Y
	mObj.soften = soften
	mObj.mColor = color
	mObj.mGraphName = graphName
	mObj.formatMarker = marker + linestyle
	mObj.linewidth = linewidth
	mObj.markersize = markersize
	mObj.alpha = alpha
	PlotGen(mObj)
End Function


Static Function InitCmap(cmap)
	Struct ColorMapDef &cmap
	cmap.GREY = "Grays256"
	cmap.TERRAIN = "Terrain256"
	cmap.HEAT = "YellowHot256"
End Function

// tried to get colors from http://prideout.net/archive/colors.php

Static Function InitRed(mColor)
	Struct RGBColor & mColor
	// crimsom
	InitRGB_Dec(mColor,0.863,0.235,0.235)
End function

Static Function InitBlue(mColor)
	Struct RGBColor & mColor
	// medium blue
	InitRGB_Dec(mColor,0.0,0.0,0.804)
End function

Static Function InitGreen(mColor)
	Struct RGBColor & mColor
	// Green
	InitRGB_Dec(mColor,0.0,0.502,0.0)
End Function

Static Function InitBlack(mColor)
	Struct RGBColor & mColor
	InitRGB_Dec(mColor,0,0,0)
End Function

//  values for the next from http://www.december.com/html/spec/colorcodes.html
Static Function InitYellow(mColor)
	Struct RGBColor & mColor
	// Gold
	InitRGB_Dec(mColor,1.0,0.843,0.0)
End Functon

Static Function InitPurple(mColor)
	Struct RGBColor & mColor
	//Indigo
	InitRGB_Dec(mColor,0.4,0.0,0.4) 
End Function

Static Function InitOrange(mColor)
	Struct RGBColor & mColor
	// Dark ORange
	InitRGB_Dec(mColor,1.0,0.549,0.0)
End Function 

Static Function InitGrey(mColor)
	Struct RGBColor & mColor
	InitRGB_Dec(mColor,0.871, 0.769, 0.871)
End Function 

Static Function InitWhite(mColor)
	Struct RGBColor & mColor
	InitRGB_Dec(mColor,1,1,1)
End Function 


Static Function InitDefColors(colors)
	Struct ColorDefaults & colors
	InitRed(colors.Red)
	InitGreen(colors.Gre)
	InitBlue(colors.blu)
	// Sign Yellow
	InitBlack(colors.bla)
	InitYellow(colors.Yel)
	// indigo
	InitPurple(colors.Pur)
	// Orange Crush
	InitOrange(colors.Ora)
	// save all the predefined colors, for looping
	// Note: i gets passed by reference and incremented
	Variable i=0
	AddColor(colors,colors.Red,i)
	AddColor(colors,colors.Gre,i)
	AddColor(colors,colors.Blu,i)
	AddColor(colors,colors.Pur,i)
	AddColor(colors,colors.Bla,i)
	AddColor(colors,colors.Yel,i)
	AddColor(colors,colors.Ora,i)
End Function

Static Function Grey(toGet,[transparency])
	Struct RGBColor &toGet
	Variable transparency
	transparency = ParamIsDefault(transparency) ? 0.8 : transparency
	InitRGB_Dec(toGet,transparency,transparency,transparency)
End Function

Static Function Red(toGet)
	Struct RGBColor &toGet
	InitRGB_Dec(toGet,1.0,0,0)
End Function

Static Function InitRGB(RGB,Red,Green,Blue)
	// Initialize RBG From values between 0 and COLORMAX
	// RBG Is the structure to initialize
	// XXX check that values are in the right range?
	Struct RGBColor &RGB
	Variable Red,Green,Blue
	RGB.red = Red
	RGB.green = Green
	RGB.blue = Blue
End Function

Static Function InitRGB_Dec(RGB,Red,Green,Blue)
	// Red,Green,And Blue and between 0 and 1.0
	Struct RGBColor &RGB
	Variable Red,Green,Blue
	InitRGB(RGB,floor(Red*ColorMax),floor(Green*ColorMax),floor(Blue*ColorMax))
End Function

Structure PlotDefines
	Struct ColorDefaults colors
	Struct ColorMapDef cmaps
	//	 The maximum value color can tke (e.g. 65K for 16 bit)
	Variable MaxColor
	// The number of default defined Colors (for 'category' plots)
	Variable NDefColors
EndStructure

Static Function AddColor(def,ToAdd,index)
	// return the thing to add, increment the index
	Struct ColorDefaults & def
	Struct RGBColor &ToAdd
	Variable &Index
	def.AllColors[Index] = toAdd
	Index += 1
End Function

Static Function /S GetUniFigName(name)
	// Given a name for a figure, gets a unique version of it 
	//
	// Args:
	//		name: base name
	//		
	// Returns:
	//		unique name for the figure
	//
	String name
	// 0 is starting index
	return UniqueName(name,DEF_UNINAME_GRAPH,0)
End Function 

// Returns a new display window, returns the unique name
Static Function /S Figure([name,heightIn,widthIn,hide])
	// Makes a new figure, returns its handle
	//
	// Args:
	//		name: name of the figure (defaults to unique default)
	//		heightIn: the height in inches
	//		widthIn: the width in inches
	//		hide: if true, hides the graph (default)
	// Returns:
	//		name/handle to the figure
	//
	// XXX give figure struct?
	String name
	Variable heightIn,widthIn,hide
	heightIn = ParamIsDefault(heightIn) ? DEF_DISP_HEIGHT_IN : heightIn
	widthIn = ParamIsDefault(widthIn) ? DEF_DISP_WIDTH_IN : widthIn
	hide = ParamIsDefault(hide) ?  DEF_DISP_H_HIDE :hide
	if (ParamIsDefault(name))
		// Get a unique version of the default graph
		name = DEF_DISP_NAME
	EndIf
	// POST: name exists
	name = GetUniFigName(name)
	// POST: name is unique
	// I specifies /W (left,top,right,bottom) is in inches
	Display /HIDE=(hide) /I /W=(0,0,widthIn,heightIn) /N=$(name)
	return name
End Function

Static Function Title(TitleStr,[xOffset,yOffset,graphName,Location,fontSize])
	// Makes a tite; overwrites the existing text box, if one exists
	//
	// Args:
	//		TitleStr: what the tite should say
	//		xoffset: for the title, in units textbox understands
	//	 	yOffset: for the title, in units textbox understands
	//		graphName: which graph to put the title on 
	//		fontSIze: size of the font
	// Returns:
	//		Nothing
	//
	String TitleStr,graphName,Location
	Variable fontSize,xOffset,yOffset
	xOffset= ParamIsDefault(xOffset) ? 0 : xOffset
	yOffset= ParamIsDefault(yOffset) ? 0 : yOffset
	fontSize = ParamIsDefault(fontSize) ? DEF_FONT_TITLE : fontSize
	if (ParamIsDefault(graphName))
		graphName = gcf()
	EndIf
	// Add the font size to the title string
	sprintf titleStr,"\\Z%d%s",fontSize,TitleStr
	// Textbox: V-711, pp 711 of igormanual
	// F=0: no frame
	// /B: background is transparent
	// C: Overwrite existing
	// N: name
	// A: location (MT: middle top)
	TextBox /X=(xOffset)/Y=(yoffset)/E=2/B=1/C/N=text1/F=0/A=MT(titleStr)
End Function

Static Function BeautifyAxisLabels(WindowName,WhichAxis,[FontSize])
	String WindowName,WhichAxis
	Variable FontSize
	FontSize = ParamIsDefault(FontSize)? DEF_FONT_AXIS : FontSize
	// Sets the axes 
	// XXX TODO: I don't think I need this line anymore (previously, axis labels on y were colliding).
	// 
	ModifyGraph /W=$(WindowName) margin($X_AXIS_DEFLOC)=(2*DEF_MODGRAPH_WIDTH)
	ModifyGraph /W=$(WindowName) margin($Y_AXIS_DEFLOC)=(2*DEF_MODGRAPH_WIDTH)
	// set a 'tight' top margin'
	ModifyGraph /W=$(WindowName) lblMargin($X_AXIS_DEFLOC)=(-2*DEF_MODGRAPH_WIDTH)
End Function


Static Function /S GetFormattedLabel(LabelStr,[FontName,FontSize])
	String LabelStr,FontName
	Variable FontSize
	String toRet
	if (ParamIsDefault(FontName))
		FontName = DEF_FONT_NAME
	EndIf
	if (ParamIsDefault(FontSize))
		FontSize= DEF_FONT_LEGEND
	EndIf
	// pp 333 Label of igor manual
	// see also: http://www.igorexchange.com/node/3029
	// \f1: makes it bold
	// \\Z: font size
	// /F: specifices font name
	sprintf toRet, "\\Z%d\[0\F'%s'\]0\f01%s",fontSize,fontName,LabelStr
	return toRet
End Function

Static Function GenLabel(LabelStr,WindowName,FontName,WhichAxis,FontSize)
	String LabelStr,WindowName,FontName,WhichAxis
	Variable FontSize
	LabelStr = GetFormattedLabel(LabelStr,FontName=FontName,FontSize=FontSize)
	Label /W=$(WindowName) $(WhichAxis), (LabelStr) 
	BeautifyAxisLabels(WindowName,WhichAxis,FontSize=FontSize)
End Function


Static Function pLegend([graphName,labels,location,labelStr,fontName,fontSize,labelStrSep,x_offset,y_offset])
	// Puts labels for the traces (assumed in same order as plotted) onto graphname
	// at location (anchor code). 'labels' is a wave, or labelStr is a string. (*default is csv*)	//
	//
	// Args:
	//		graphName: which graph to put the legend on
	//		labels: what to label each trace. assume a csv string, one entry per trace; if empty, dont label
	//		location: where to put the legend, in terms of the 'A' flag of Legend
	//		fontName / font size: what font and size to use
	//		labelStrSep: can use something besides comma if you set this
	//		x_offset,y_offset: the x and y offdsets fed to the legend 
	// Returns:
	//		Nothing
	//
	String graphName,location
	String labelStr,labelStrSep
	Wave /T Labels
	Variable fontSize,x_offset,y_offset
	String fontName
	x_offset = ParamIsDefault(x_offset) ? 0 : x_offset
	y_offset = ParamIsDefault(y_offset) ? 0 : y_offset
	if (ParamIsDefault(fontSize))
		fontSize = DEF_FONT_LEGEND
	EndIf
	if (ParamIsDefault(fontName))
		fontName = DEF_FONT_NAME
	EndIf
	if (paramIsDefault(labelStrSep))
		labelStrSep = PLOT_UTIL_DEF_LABEL_SEP
	EndIf
	If (!ParamIsDefault(labelStr))
		Make /O/N=(0)/T labels
		ModDataStructures#pListToTextWave(labels,labelStr,Sep=labelStrSep)
	EndIf
	if (ParamIsDefault(location))
		location = ANCHOR_BOTTOM_MIDDLE
	EndIf
	if (ParamIsDefault(graphName))
		graphName = gcf()
	EndIf
	// Create a default legend (empty legendStr), or add all the labels, if we need them
	// Note that if either labels or labelStr isn't empty, then we should have a viable labels
	String mLegendStr = ""
	if (!ParamIsDefault(labels) || !ParamIsDefault(labelStr) )
		// Get all the waves
		Make /O/N=0/T mTraces
		GetTracesAsWave(graphName,mTraces)
		// Get all the trace identifiers (see V-341, Legend)
		// "
		// You can put a legend in a page layout with a command such as:
		//Legend "\s(Graph0.wave0) this is wave0"
		// "
		Duplicate /O/T mTraces,mTraceLabels
		Variable n = min(DimSize(mTraces,0),DimSize(labels,0))
		// Get the unformatted version of the labels
		mTraceLabels[0,n-1] = "\s(" + graphName + "." + (mTraces[p]) + ")" + labels[p]
		// format all the labels
		mTraceLabels[]  = GetFormattedLabel(mTraceLabels[p],FontName=FontName,FontSize=FontSize)
		Variable i, hasLabel
		for (i=0; i<n; i += 1)
			// if no label present, then dont put anything
			hasLabel = (strlen(labels[i]) > 0)
			if (!hasLabel)
				continue
			EndIf
			mLegendStr += mTraceLabels[i]
			// add a newline if we aren't last, and if next isn't  label
			if (i < n-1)
				mLegendStr += "\r"
			EndIf
		EndFor
	EndIf
	KillWaves mTraceLabels
	// "If legendStr is missing or is an empty string (""), the text needed for a default legend is automatically generated. "
	// Textbox (711)
	// /C:  changes existing (XXX need name?)
	// /A: anchor code
	Legend /X=(x_offset)/Y=(y_offset)/W=$(graphName) /A=$(location) (mLegendStr)
End Function

// adds units to labelStr (assuming units isn't empty)
Static Function /S AddUnitsToLabel(LabelStr,Units)
	String LabelStr,Units
	return LabelStr + " [" + units + "]" 
End Function

Static Function XLabel(LabelStr,[graphName,fontSize,topOrBottom,units])
	// graph name is the window
	// fontsize is the font size
	// topOrBottom is where to put this x axis.
	String labelStr, graphName,topOrBottom,units
	Variable fontsize
	fontsize = ParamIsDefault(fontSize) ? DEF_FONT_AXIS : fontSize
	if (ParamIsDefault(graphName))
		// If no graph supplied, assume it is the top graph, get it.
		graphName = gcf()
	EndIf
	if (ParamISDefault(topOrBottom))
		topOrBottom = X_AXIS_DEFLOC
	EndIf
	if (!ParamIsDefault(units))
		labelStr = AddUnitsToLabel(labelStr,units)
	EndIf
	GenLabel(LabelStr,graphName,DEF_FONT_NAME,topOrBottom,FontSize)
End Function

Static Function YLabel(LabelStr,[graphName,fontSize,leftOrRight,units])
	// See xLabel, same thing except leftOrRight
	String labelStr, graphName,leftOrRight,units
	Variable fontsize
	fontsize = ParamIsDefault(fontSize) ? DEF_FONT_AXIS : fontSize
	if (ParamIsDefault(graphName))
		// If no graph supplied, assume it is the top graph, get it.
		graphName = gcf()
	EndIf
	if (ParamIsDefault(leftOrRight))
		leftOrRight = Y_AXIS_DEFLOC
	EndIf
	if (!ParamIsDefault(units))
		labelStr = AddUnitsToLabel(labelStr,units)
	EndIf
	// Add the font size and font type to the label string
	GenLabel(LabelStr,graphName,DEF_FONT_NAME,leftOrRight,FontSize)
End Function

Static Function SaveGen(Path,exportFormat,Transparent,dpi,figname,saveName,saveAsPxp)
	String Path,saveName,figname
	Variable dpi,transparent,exportFormat,saveAsPxp
	if (saveAsPxp)
		// Presummably we want to be able to see the graph when we open it.
		// XXX Pause, so when we stop hiding the graph it doesn't give us a seizure if we do this a bunch
		DoWindow /Hide=(DISP_HIDE_SHOW_WINDOW) $figName
		SaveGraphCopy /P=$path/O/W=$(figName) as saveName
		// Hide it again 
		DoWindow /Hide=(DISP_HIDE_HIDE_WINDOW) $figName
	else
		SavePict            /P=$path/O/TRAN=(transparent)/B=(dpi)/WIN=$(figName)/W=(0,0,0,0)/E=(exportFormat) as saveName
	EndIf
End Function

Static Function SaveFig([saveName,saveAsPxp,figName,path,closeFig,dpi,transparent,exportFormat])
	// Saves the figure as specified
	//
	// Args:
	//		saveName: what to save it as 
	//		saveAsPxp: if true, saves as a pxp (inludes all the data, etc)
	//		figName: the name of the figure to save
	//		path: symbolic name to start the save as. default to home (where  the ipf was run)
	//		closefig: if true, closes the figure after saving
	//		dpi: dots per inch to save
	//		transparent: if true, figure is saved with a transparent background
	//		exportformat: for non-pxp files, how to save (e.g. PNG)
	// Returns:
	//		Nothing
	String saveName,figName
	String path
	Variable closeFig,dpi,transparent,exportFormat
	Variable saveAsPxp
	saveAsPxp = ParamIsDefault(saveAsPxp) ? ModDefine#False() : saveAsPxp
	dpi = ParamIsDefault(dpi) ? DEF_DISP_DPI : dpi
	transparent = ParamIsDefault(transparent) ? DEF_FIG_TRANSPARENT : transparent
	if (ParamIsDefault(figName))
		// Get the current top window
		figName = gcf()
	EndIF
	if (ParamIsDefault(saveName))
		saveName = figName
	EndIf
	// POST: savename exists
	if (ParamIsDefault(exportFormat) && ! saveAsPxp)
		exportFormat = DEF_FIG_GFX_FMT
		saveName= ModIoUtil#EnsureEndsWith(saveName,DEF_FIG_SAVEFILE_EXTENSION)
	EndIf
	if (saveAsPxp)
		saveName= ModIoUtil#EnsureEndsWith(saveName,".pxp")	
	EndIf
	closeFig = ParamISDefault(closeFig) ? DEF_FIG_CLOSE_ON_SAVE : closeFig
	if (ParamIsDefault(path))
		path = DEF_FIG_SAVEPATH
	EndIF
	 SaveGen(Path,exportFormat,Transparent,dpi,figname,saveName,saveAsPxp)
	// POST: everything is 'filled out', except perhaps savename
	// O: overwrite
	// P: symbolic path (location of this experiment)
	if (closeFig)
		KillWindow $figName
	EndIf
End Function

Static Function window_exists(name)
	// Args:
	//	name: of the window
	// Returns: 
	//	true if the window exists
	String name
	// /Z: suppress errors
	GetWindow /Z $(name) active
	return V_flag == 0 
End Function

Static Function assert_window_exists(name)
	// Throws an error if the given window doesn't exist
	//
	// Args:
	//	See: window_exists	
	String name
	ModErrorUtil#assert(window_exists(name),msg=("Couldn't find window: " + name))
End Function

Static Function /S gcf()
	// Get the current FIgure. See: pp 230 or igor manual, GetWindow
	// By side effect, this stores the window 'path' in S_Value
	GetWindow kwTopWin,activeSW
	return S_Value
End Function

Static Function scf(figure)
	// Sets the top window to the specified window
	// Args:
	//	figure: the name of the figure
	String figure
	assert_window_exists(figure)
	// /F:Brings the window with the given name to the front (top of desktop).
	DoWindow /F $(figure)
End Function

Static Function /S trace_list(fig)
	// Returns: the (y) traces associated with each figure
	String fig
	return TraceNameList(fig,PLOT_UTIL_DEF_LABEL_SEP,1)
End Function

Static Function trace_on_graph(fig,trace_name)
	// Retuns: True iff trace_name is plotted as a y value on fig
	String fig,trace_name
	String traces = trace_list(fig)
	Variable idx = (WhichListItem(trace_name,traces,PLOT_UTIL_DEF_LABEL_SEP))
	return (idx > -1)
End Function
	
Static Function assert_trace_on_graph(fig,trace_name)
	// Asserts that trace_on_graph is true
	String fig,trace_name
	String error
	sprintf error, "Couldn't find trace '%s' on graph '%s'",trace_name,fig
	ModErrorUtil#assert( trace_on_graph(fig,trace_name),msg=error)
End Function

Static Function /WAVE graph_wave_x(fig,trace_name)
	// See: graph_wave, except returns the x wave reference
	String fig,trace_name
	assert_window_exists(fig)
	assert_trace_on_graph(fig,trace_name)
	Wave low_res_wave = XWaveRefFromTrace(fig,trace_name)
	return low_res_wave
End Function

Static Function /Wave graph_wave(fig,trace_name)
	// Returns the *reference* to the given trace on the figurre 
	//
	// Args:
	//	See graph_wave_note
	// Returns:
	//	Reference to the relvant wave
	String trace_name,fig
	assert_window_exists(fig)
	assert_trace_on_graph(fig,trace_name)
	Wave low_res_wave = TraceNameToWaveRef(fig,trace_name)
	return low_res_wave
End Function

Static Function InitPlotDef(ToInit)
	// Initialize the Plot Definitions...
	Struct PlotDefines &ToInit
	// save the maximum color 
	ToInit.MaxColor = ColorMax
	// Number of predefined 'category' colors
	ToInit.NDefColors = PredefinedColors
	// make the color maps and predefined colors
	InitDefColors(ToInit.colors)
	InitCmap(ToInit.cmaps)
End Function

Static Function PlotBeautify([GraphName])
	// Function used to beautify the current plot
	// Use Inside Ticks
	String graphName
	if (ParamIsDefault(graphName))
		graphName = gcf()
	EndIf	
	Variable tickInside = 2
	ModifyGraph /W=$(graphName) tick(left)=tickInside, tick(bottom)=tickInside
	Variable lineWidth = 3
	// make the frame a little thick
	ModifyGraph /W=$(graphName)axThick(bottom)=(lineWidth), axThick(left)=(lineWidth)
	// Make the tick markers slighlty larger 
	ModifyGraph /W=$(graphName) btLen(left)=(3*lineWidth), btLen(bottom)=(3*lineWidth)
	// full frame around the graph
	ModifyGraph /W=$(graphName) mirror(left)=1, mirror(bottom)=1
	// turn off units on the ticks.
	//  for some reason you set this high to turn it off
	ModifyGraph /W=$(graphName) tickunit=1, tickexp=0
	// beautify the axis ticks
	BeautifyAxisLabels(graphName,X_AXIS_DEFLOC,FontSize=(DEF_FONT_AXIS))
	BeautifyAxisLabels(graphName,Y_AXIS_DEFLOC,FontSize=(DEF_FONT_AXIS))
	// Change the font size for the labels
	ModifyGraph /W=$(graphName) fsize(bottom)=(DEF_FONT_TICK_LABELS), fsize(left)=(DEF_FONT_TICK_LABELS)	
End

Static Function DefColorIter(i,RGB,PlotDef,[MaxColors])
	// Uses the 'allColors' to easily iterate through the default colors
	Variable i 
	Struct RGBColor & RGB
	Struct PlotDefines &PlotDef
	Variable MaxColors
	// We mod the variable i (iteraiton number) to MaxColors
	MaxColors = paramIsDefault(MaxColors) ? PlotDef.NDefColors :  MaxColors
	// XXX throw warning or error if the Max Colors is more?...
	MaxColors =  min(MaxColors,PlotDef.NDefColors )
	// POST: MaxColors is the proper thing to modulo by, should be in range
	// Get the index of this color
	Variable index = mod(i,MaxColors)
	RGB = PlotDef.colors.AllColors[index]
End Function

Static Function AxisLim(lower,upper,name,windowName)
	Variable lower,upper
	String name,Windowname
	// XXX check for error? does window exist, etc
	SetAxis /W=$windowName $name,lower,upper
       // 'DoUpdate' will autoscale for us 
       // autoscale the other axis
       String axisToScale
       strswitch (name)
               case X_AXIS_DEFLOC:
                       // also adjust y to be in the range
                       axisToScale = Y_AXIS_DEFLOC
                       break
               case Y_AXIS_DEFLOC:
                       // also adjust x to be in the range
                       axisToScale = X_AXIS_DEFLOC
                       break
       EndSwitch
       // '/A' flag autoscales
       SetAxis /A=2/W=$windowName $axisToScale
End Function

Static Function XLim(lower,upper,[graphName])
	// Gets the x limits by refernec
	//
	// Args:
	//	lower/upper: pass-by-reference min and max x value
	//	to get from graphname
	//	
	//	graphName: which graph to use. defaults to current/top
	// Returns: 
	//	nothing, but sets the lower and upper to the x limits
	Variable lower,upper
	String graphName
	If (ParamISDefault(graphName))
		graphName = gcf()
	EndIf
	// POST: we have a windowname
	AxisLim(lower,upper,X_AXIS_DEFLOC,graphName)
End Function

Static Function YLim(lower,upper,[graphName])
	Variable lower,upper
	String graphName
	If (ParamISDefault(graphName))
		graphName = gcf()
	EndIf
	// POST: we have a windowname
	AxisLim(lower,upper,Y_AXIS_DEFLOC,graphName)
End Function

Static Function /S ForceStr()
	// Tom likes f to be italicized
	// \[0: 'stores' the current style
	// /f03: italic
	// \]0: 'restores' the previous style
	return  "\[0\f03 F\]0"
End Function

Static Function Normed(val,minV,maxV)
	Variable val,minV,maxV
	// returns val between 0 and 1, where minV corresponds to 0 and maxV corresponds to 1
	return (val-minV)/(maxV-minV)
End Function	

Static function get_xlim(lower_x,upper_x,[m_window])
	// Sets the lower and upper x limits by reference
	// 
	// Args:
	//	<lower/upper_x> the pass-by-reference variable to be set
	//	m_window: graph to get the limits of. defaults to gcf()
	// Returns:
	//	nothing, sets the <lower/upper>_x variable appropriately 
	String m_window
	Variable & lower_x,&upper_x
	if (ParamIsDefault(m_window))
		m_window = gcf()
	EndIf
	Variable lower_y,upper_y
	GetAxisLimits(m_window,lower_x,upper_x, lower_y,upper_y,mDoUpdate=1)	
End Function


Static Function relative_coordinates(window_var,point_var,get_x)
	// Get a point in relative axis coordinates: how far we are 
	// from the top/left if this is y or x
	//
	// Args:
	//	window_var: the rectangle of the window
	//	point: the point within the window
	//	get_x: if we should return the x or y
	// Returns:
	//	the 0/1 relative index...
	struct rect & window_var
	struct point & point_var
	Variable get_x
	Variable coord,min_coord,max_coord
	// (0,0) is at the top left 
	If (get_x)
		coord = point_var.h
		min_coord = window_var.left
		max_coord = window_var.right
	Else
		coord = point_var.v
		min_coord = window_var.top
		max_coord = window_var.bottom
	EndIf
	return max(0,coord-min_coord)/(max_coord-min_coord)
End Function


// Gets the axis limits for the axis 'mwindow'
Static Function GetAxisLimits(mWindow,lowerX,upperX,lowerY,upperY,[mDoUpdate])
	String mWindow
	Variable & lowerX, &upperX, &lowerY, & upperY
	Variable mDoUpdate
	// by default, do an update 
	mDoUpdate = ParamIsDefault(mDoUpdate) ? ModDefine#True() : ModDefine#False()
	if (mDoUpdate)
		DoUpdate
	EndIf
	// Get the X limits
	GetAxis /W=$mWindow/Q $X_AXIS_DEFLOC
	lowerX = V_Min
	upperX = V_Max
	// Get the Y Limes
	GetAxis /W=$mWindow/Q $Y_AXIS_DEFLOC
	lowerY = V_Min
	upperY = V_Max
End Function

Static Function GetGraphPixels(mWindow,lowerX,upperX,lowerY,upperY)
	String mWindow
	Variable & lowerX, &upperX, &lowerY, & upperY
	DoUpdate
	// get all the pixels
	GetWindow $(mWindow),psizeDC
	lowerX = V_left
	upperX = V_right
	lowerY = V_top
	upperY = V_bottom
End Function

Static Function GraphDimensionInPoints(mWindow,lowerX,upperX,lowerY,upperY)
	String mWindow
	Variable lowerX,upperX,lowerY,upperY
	// Reads the number of points into V_left, V_right, V_top, and V_bottom
	GetWindow $(mWindow) psize
	lowerX = V_left
	upperX = V_right
	lowerY= V_top
	upperY= V_bottom
End Function	

Static Function ResetPlotUtil()	
	// Clear all the graphs
	ModPlotUtil# ClearAllGraphs()
	// Reset the axline dir
	String mDir = GetAxisDirForPlotting()
	KillDataFolder /Z $mDir
	ModIoUtil#EnsurePathExists(mDir)
End Function

// For axhline and axvline, have to create (incredibly tiny) waves
Static Function /S GetAxisDirForPlotting()
	String mDir = "root:PlotAxLines:"
	return mDir
End Function

// Function to get the axis line wave name. Yes, it is this sucky.
Static Function /S GetAxisWaveName(mWin,axisName)
	String mWin,axisName
	String mDir = GetAxisDirForPlotting()
	ModIoUtil#EnsurePathExists(mDir)
	String mFolderOrig = ModIoUtil#cwd() 
	SetDataFolder $mDir
	String base = mWin + axisName
	String mWaveName = ModIoUtil#UniqueWave(ModIoUtil#Sanitize(base))
	mWaveName = mDir + mWaveName
	SetDataFolder $mFolderOrig
	return mWaveName
End Function

Static Function DrawGen(mWin,axisName,valueI,valueF,mPlotObj,mDoUpdate,Type)
	// Get the axis for this graph (mWin is the name)
	// Q: don't print anything
	String mWin,axisName
	Variable valueI,valueF,mDoUpdate,type
	Struct PlotObj & mPlotObj
	// Make a 'DoUpdate', so that getAxis is working with updated information
	if (mDoUpdate)
		DoUpdate
	EndIf
	Variable lowerX,upperx,lowerY,upperY
	GetAxisLimits(mWin,lowerX,upperX,lowerY,upperY,mDoUpdate=ModDefine#False())
	// figure out what we will plot
	Variable x0,y0,x1,y1
	strswitch (axisName)
		case X_AXIS_DEFLOC:
			// horizontal line
			// constant y at value
			x0 = lowerX
			x1 = upperX
			// Note that we do MAXy-y to get the coordinates, since
			// y=0 is at the top, y=1 is the bottom (in normalized)
			y0 = valueI
			y1 = valueF
			break
		case Y_AXIS_DEFLOC:
			// vertical line
			// constant x at value
			x0 = valueI
			x1 = valueF
			y0 = lowerY
			y1 = upperY
			break
	EndSwitch
	// POST: x0,x1,y0,y1 are the values we want
	Variable x0Norm = x0
	Variable x1Norm = x1
	Variable y0Norm = y0
	Variable y1Norm = y1
	String xWave = GetAxisWaveName(mWin,X_AXIS_DEFLOC) 
	String yWave = GetAxisWaveName(mWin,Y_AXIS_DEFLOC) 
	Make /O $xWave = {x0Norm,x1Norm}
	Make /O $yWave = {y0Norm,y1Norm}
	Wave mPlotObj.X = $xWave
	Wave mPlotObj.Y = $yWave
	mPlotObj.hasX = ModDefine#True()
	mPlotObj.mGraphName = mWin
	switch (Type)
		case TYPE_DRAW_LINE:
			PlotGen(mPlotObj)
			break
		case TYPE_DRAW_RECT:
			// XXX TODO:
			break
	endSwitch
End Function


Static Function AxGenLine(mWin,axisName,valueI,valueF,mPlotObj,mDoUpdate)	
	// Get the axis for this graph (mWin is the name)
	// Q: don't print anything
	String mWin,axisName
	Variable valueI,valueF,mDoUpdate
	Struct PlotObj & mPlotObj
	// both valus are the same...
	 DrawGen(mWin,axisName,valueI,valueF,mPlotObj,mDoUpdate,TYPE_DRAW_LINE)
End Function

Static Function axvline(xValue,[GraphName,color,mDoUpdate])
	// 'xValue' is the x location we want the vertical line to pass through
	Variable xValue
	Variable mDoUpdate 
	String GraphName
	String color
	Struct PlotFormat toUse
	if (ParamIsDefault(color))
		color = COLOR_ABBR_RED
	EndIf
	// POST: color is not default
	mDoUpdate = ParamIsDefault(mDoUpdate) ? ModDefine#True() : mDoUpdate
	// Get the current, if the graph wasn't given
	if (ParamIsDefault(GraphName))
		GraphName = gcf()
	EndIF
	Struct PlotObj mPlotObj
	// XXX add these as default parameters
	Variable linewidth = DEF_AXLINE_WIDTH
	String mMarker = MARKER_LINE
	InitPlotObj(mPlotObj,mColor=color,linewidth=linewidth,marker=mMarker)
	 AxGenLine(GraphName,Y_AXIS_DEFLOC,xValue,xValue,mPlotObj,mDoUpdate)	
End Function

Static Function axhline(yValue,[GraphName,color,mDoUpdate])
	// 'yValue' is the y location we want the vertical line to pass through
	Variable yValue
	Variable mDoUpdate 
	String GraphName
	String color
	Struct PlotFormat toUse
	if (ParamIsDefault(color))
		color = COLOR_ABBR_RED
	EndIf
	// POST: color is not default
	mDoUpdate = ParamIsDefault(mDoUpdate) ? ModDefine#True() : mDoUpdate
	// Get the current, if the graph wasn't given
	if (ParamIsDefault(GraphName))
		GraphName = gcf()
	EndIF
	Struct PlotObj mPlotObj
	// XXX add these as default parameters
	Variable linewidth = DEF_AXLINE_WIDTH
	String mMarker = MARKER_LINE
	InitPlotObj(mPlotObj,mColor=color,linewidth=linewidth,marker=mMarker)
	 AxGenLine(GraphName,X_AXIS_DEFLOC,yValue,yValue,mPlotObj,mDoUpdate)	
End Function

Static Function GetTracesAsWave(GraphName,mWave)
	Wave /T mWave
	String GraphName
	String Sep = ModDefine#DefListSep()
	String Traces = TraceNameList(GraphName,Sep,TRACENAME_INCLUDE_ALL)
	Variable nItems = ItemsInList(Traces,Sep)
	// Resize the wave to the appropriate number of items
	Redimension /N=(nItems) mWave
	// Add all the items
	mWave[] =  StringFromList(p,Traces,Sep)
End Function

Function KillAllGraphs()
	// Kills all open graphs or windows
	// See:
	//http://www.igorexchange.com/node/2555
	string fulllist = WinList("*", ";","WIN:1")
	string name, cmd
	variable i
 
	for(i=0; i<itemsinlist(fulllist); i +=1)
		name= stringfromlist(i, fulllist)
		sprintf  cmd, "Dowindow/K %s", name
		execute cmd		
	endfor
end

Static Function ClearFig([GraphName])
	String GraphName
	// See if we were given a real window name
	if (ParamIsDefault(GraphName))
		GraphName = gcf()
	EndIf
	// Get all the traces
	Make /O/N=0/T mTracesClearFig
	GetTracesAsWave(GraphName,mTracesClearFig)
	// Kill Each of th trace in this window
	Variable nItems = DimSize(mTracesClearFig,0)
	Variable i
	String tmp
	for (i=0; i< nItems;  i+= 1)
		tmp = mTracesClearFig[i]
		// remove this trace
		// /Z : silence, in the case of NANs
		RemoveFromGraph /Z/W=$(GraphName) $tmp
	EndFor
	// kill anything drawn
	SetDrawLayer /K/W=$GraphName $DRAW_LAYER_GRAPH
	KillWaves /Z mTracesClearFig
End Function

// Functions for getting strings of Greek letters

Static Function /S Mu()
	return num2char(0xB5)
End Function

Static Function ClearAllGraphs()
	// Closes every open graph window we can find
	// Args: None
	// Returns: None
	String mSep = ModDefine#DefListSep()
	String mList = WinList("*",mSep,WINLIST_GRAPHS)
	Variable nWIn = ItemsInList(mList,mSep)
	Variable i
	String tmpWindow
	// Kill each window
	for (i=0; i<nWin; i+=1)
		tmpWindow = StringFromList(i,mList,mSep)
		KillWindow $(tmpWindow)
	EndFor
End Function

Static Function clf()	
	//	 Just clears all the graphs we can find; syntactic sugar
	ClearAllGraphs()
End Function

Static Function TightAxes([fig, points_left,points_right,points_bottom,points_top])
	// Reduces the margins to the same value for the given figure. Probably want to do this *after* other formatting
	//
	// Args:
	//		ax: what axis to use
	//	    	points_<x>: how many points to use
	// Returns:
	//	 	Nothing
	String fig
	Variable points_left,points_right,points_bottom,points_top
	if (ParamIsDefault(fig))
		fig = gcf()
	EndIf
	Variable DefaultPoints = 2
	points_left = ParamIsDefault(points_left) ? DefaultPoints : points_left
	points_right = ParamIsDefault(points_right) ? DefaultPoints : points_right
	points_top = ParamIsDefault(points_top) ? DefaultPoints : points_top
	points_bottom = ParamIsDefault(points_bottom) ? DefaultPoints : points_bottom
	ModifyGraph /W=$(fig) margin(left)=points_left,margin(bottom)=points_bottom,margin(top)=points_top,margin(right)=points_right
End Function

Static Function AxisOff([ax])
	// Turns off the x and y axis (ie: ticks and such)
	//
	// Args:
	//		ax: what axis to use
	// Returns:
	//	 	Nothing
	String ax 
	if (ParamIsDefault(ax))
		ax = gcf()
	EndIf
	ModifyGraph /W=$(ax) mirror(bottom)=0,nticks(bottom)=0,sep(bottom)=1, axThick(bottom)=0
	ModifyGraph  /W=$(ax) mirror(left)=0,nticks(left)=0,sep(left)=1,axThick(left)=0
End Function
	

Static Function SubplotLoc(nRows,nCols,number,leftWin,topWin,rightWin,bottomWin,left,top,right,bottom)
	Variable nRows,nCols,number,leftWin,topWin,rightWin,bottomWin
	Variable &left,&top,&right,&bottom
	// Determine which column
	// We assume left to right, then top to bottom
	// Assume numbers are one based, just like in python
	ModErrorUtil#AssertGt(number,0)
	ModErrorUtil#AssertGt(nRows,0)
	ModErrorUtil#AssertGt(nCols,0)
	Variable mCol = mod(number-1,nCols)
	Variable mRow = floor((number-1)/nCols)
	// Check and make sure we are in range
	if (number > nRows*nCols)
		ModErrorUtil#OutOfRangeError(description="Subplot number out of range")
	EndIf
	if (mRow > nRows || mCol > nCols)
		ModErrorUtil#OutOfRangeError(description="Subplot number out of range")
	EndIf
	// POST: we are in bounds, get where this plot should actually start and end
	// Note: these are *relative* coordinates, to the host
	// See: display, /W flag, pp 120
	Variable width = 1/(nCols)
	Variable height = 1/(nRows)
	// mCol has range [1,nCols], so it has a max of one
	left = (mCol) * width
	top  = (mRow) * height
	right = left + width
	bottom = top + height
End Function

Static Function /S DefDisplayName(windowName,num)
	String windowName
	Variable num
	return windowName + "_" + num2str(num)
End Function

Static Function /S AppendedWindowName(baseWindow,subWindow)
	String baseWindow,subWindow
	return ModIoUtil#AppendedPath(baseWindow,subwindow,mSep=DELIM_SUBWINDOW)
End Function

// makes a display within 'windowname' (defaults to current)
// assuming the entire window has nRows,nCols, and we are at plot 'current'
// (everything is one based, like in python). *returns the name of the display*,
// which should be displayname, if passed
// Should only call this *once* per number, otherwise subplot will get confused
// XXX could just reference the window or kill, if it already exists
// XXX TODO: known bug: doesn't work quite right with non-column plots
Static Function /S Subplot(nRows,nCols,Current,[windowName,displayName])
	Variable nRows,nCols,Current
	String windowName,displayName
	if (ParamIsDefault(windowName))
		// Get the name of the current figure or graph
		windowName = gcf()
		// Remove everything after the last "#" (window separator)
		windowName = ModIoUtil#RemoveAfterLast(windowName,WINDOW_SEP)
	EndIf
	if (ParamIsDefault(displayName))
		displayName = DefDisplayName(windowName,current)
	Endif
	Variable winLeft,winTop,winRight,winBottom
	ModIoUtil#GetWindowLeftTopRightBottom(windowname,winLeft,winTop,winRight,winBottom)
	// POST: have the dimensions. Figure out where to put this one
	Variable left,top,right,bottom
	 SubplotLoc(nRows,nCols,Current,winLeft,winTop,winRight,winBottom,left,top,right,bottom)
	 // POST: know where to put this display
	 // /HOST: the host window we are using
	 // /W: the relative dimensions.
	 // /N: the name to use.
	ModIoUtil#SafeKillWindow(displayName)
	// POST:  displayName isn't being used.
	DIsplay /HOST=$(windowName)/W=(left,top,right,bottom) /N=$(displayName)
	// get the full (unambiguous) path to the display
	return AppendedWindowName(windowName,displayName)
End Function

Static Function /S DisplayGen(xAbsI,yAbsI,xAbsF,yAbsF,[hostname,graphName])
	Variable xAbsI,yAbsI,xAbsF,yAbsF
	String hostname,graphName
	// Make sure we have the parameters we need.
	if (ParamIsDefault(graphName))
		// Then get a new graph name
		graphName = ModIoUtil#UniqueGraphName("prhGraph")
	EndIf
	if (ParamISDefault(hostname))
		Display /W=(xAbsI,yAbsI,xAbsF,yAbsF)/N=$(GraphName) 			
	else
		Display /W=(xAbsI,yAbsI,xAbsF,yAbsF)/N=$(GraphName) 	/HOST=$(hostName)
	EndIf
	return graphName
End Function

// Returns the name of the screen displayed
Static Function /S DisplayRelToScreen(xRel,yRel,widthRel,heightRel)
	Variable xRel,yRel,widthRel,heightRel
	Variable width,height
	ModIoUtil#GetScreenHeightWidth(width,height)	
	// POST: we have the screen height, no ahead and get the rest.
	Variable xAbsI,yAbsI,xAbsF,yAbsF
	SetAbsByRelAndAbs(xRel,yRel,widthRel,heightRel,width,height,xAbsI,yAbsI,xAbsF,yAbsF)
	return DisplayGen(xAbsI,yAbsI,xAbsF,yAbsF)
End Function

// Set the absolute X,Y locations by relative X/Y/Width/Height and absolute width/height.
// Useful for sizing based on a screen. Note that the final 4 parameters (sent to displayGen)
// are pass by reference
Static Function SetAbsByRelAndAbs(xRel,yRel,widthRel,heightRel,abswidth,absHeight,xAbsI,yAbsI,xAbsF,yAbsF)
	Variable xRel,yRel,widthRel,heightRel,abswidth,absHeight
	Variable & xAbsI, &yAbsI,&xAbsF,&yAbsF // Reference!
	 xAbsI = xRel * absWidth
	 yAbsI = yRel*absHeight
	 xAbsF = xAbsI + widthRel * absWidth
	 yAbsF = yAbsI + heightRel * absHeight
End Function

Static Function DisplayRel(hostName, GraphName,mWindow,xRel,yRel,widthRel,heightRel)
	Struct pWindow &mWindow
	String hostName,GraphName
	Variable xRel,yRel,widthRel,heightRel
	// Determine the absolute left top right bottom coordinates
	Variable absHeight = mWindow.height
	Variable absWidth = mWindow.width
	Variable xAbsI,yAbsI,xAbsF,yAbsF
 	SetAbsByRelAndAbs(xRel,yRel,widthRel,heightRel,abswidth,absHeight,xAbsI,yAbsI,xAbsF,yAbsF)
	// Make the display as usual
	DisplayGen(xAbsI,yAbsI,xAbsF,yAbsF,hostname=hostname,graphname=graphName)
End Function

Static Function /S SoftenColorRGBString(color)
	String color
	Variable r,g,b
	 GetRGBFromString(color,r,g,b)
	// make an rgb string which is a 'faded' version of this one
	// XXX add in alpha param?
	Variable alpha = 0.2
	// re-normalize after making it more transparent. (closer to 1)
	r = min(r+alpha*ColorMax,ColorMax)
	g = min(g+alpha*ColorMax,ColorMax)
	b = min(b+alpha*ColorMax,ColorMax)
	String rawColor = SetRGBString(r,g,b)
	return rawColor
End Function

// Plot rawdata as grey, then filter it and plot the filtiered using 'color'
Static Function PlotWithFiltered(RawData,[graphName,X,color,nFilterPoints,rawColor])
	// Plot the raw data as a grey line
	Wave RawData,X
	Variable nFilterPoints
	String color,graphName,rawColor
	Variable nDataPoints = DimSize(RawData,0)
	if (ParamIsDefault(graphName))
		graphName = gcf()
	EndIf
	if (ParamIsDefault(color))
		color = "b"
	EndIf
	// Get some reasonable number for the filtering factor if we dont have one (
	nFilterPoints = ParamIsDefault(nFilterPoints) ? ceil(nDataPoints*DEF_SMOOTH_FACTOR) :  nFIlterPoints
	if (ParamIsDefault(rawColor))
		// Get the RGB string for the original color
		rawColor = SoftenColorRGBString(color)
	endIf
	String rawMarker = ""
	if (!ParamIsDefault(X))
		ModPlotUtil#Plot(RawData,graphName=graphName,marker=rawMarker,color=rawColor,mX=X)
	Else
		ModPlotUtil#Plot(RawData,graphName=graphName,marker=rawMarker,color=rawColor)		
	EndIf
	// Get a filtered version of the raw data
	String filterName = NameOfWave(RawData) + "filtered"
	Duplicate /O RawData, $filterName
	Wave Smoothed = $filterName
	ModNumerical#savitsky_smooth(Smoothed,n_points=nFIlterPoints)
	// Plot the filtered version of the data
	// Use the same marker (just a line) 
	if (!ParamIsDefault(X))
		
		ModPlotUtil#Plot(Smoothed,marker=rawMarker,color=color,graphName=graphName,mX=X)
	Else
		ModPlotUtil#Plot(Smoothed,marker=rawMarker,color=color,graphName=graphName)		
	EndIf
End Function

Static Function HideAxisLabel(axisName,GraphName)
	String GraphName
	String axisName
	// set up 
	ModifyGraph /W=$(GraphName)noLabel($axisName)=(AXIS_SUPRESS_LABEL)
	// x label should be flush
	ModifyGraph /W=$(GraphName) lblMargin($X_AXIS_DEFLOC)=(0)
	// make the magin for the bottom axis much smaller (nothing there)...
	ModifyGraph /W=$(GraphName) margin($X_AXIS_DEFLOC)=(DEF_MODGRAPH_WIDTH/5)
End Function

Static Function NormalizeTicks([nTicks,graphName])
	String GraphName
	Variable nTicks
	nTIcks = ParamIsDefault(nTicks) ? DEF_NUM_TICKS : nTicks
	if (ParamIsDefault(GraphName))
		GraphName = gcf()
	EndIf	
	ModifyGraph /W=$(GraphName) nticks($X_AXIS_DEFLOC)=(nTicks)
	ModifyGraph /W=$(GraphName) nticks($Y_AXIS_DEFLOC)=(nTicks)
End Function

Static Function HideXAxisLabel([GraphName])
	String GraphName
	if (ParamIsDefault(GraphName))
		GraphName = gcf()
	EndIf
	String mAxis = X_AXIS_DEFLOC
	HideAxisLabel(mAxis,GraphName)
	// make the axis 'tight'...
	TightFig(GraphName=GraphName)
End Function

Static Function TightFig([GraphName])
	String GraphName
	if (ParamIsDefault(GraphName))
		GraphName = gcf()
	EndIf
	ModifyGraph /W=$(GraphName) margin($"top")=(DEF_MODGRAPH_WIDTH/4)
End Function

