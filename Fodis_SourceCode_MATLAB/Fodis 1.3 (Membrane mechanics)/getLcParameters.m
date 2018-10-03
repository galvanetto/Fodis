function [tssMin,tssMax,FMin,FMax,xBin,binSize,histValue,maxHistValue,zerosTempMax,LcMin,LcMax,maxTssOverLc,xBinSizeMax,thresholdHist,xBinFcMax, xBinDeltaLc, minDeltaLc, maxDeltaLc, startLcDeltaLc, persistenceLength] = getLcParameters(handles)
% get Lc parameters

% F max min
FMin = str2double(get(handles.editFMin, 'string')) * 1E-12;
FMax = str2double(get(handles.editFMax, 'string')) * 1E-12;

% bin histogram size
binSize = str2double(get(handles.editBinSize, 'string')) * 1E-9;
binSizeFcMax = str2double(get(handles.editBinSizeFcMax, 'string')) * 1E-12;

% tss min max
tssMin = 0;
tssMax = str2double(get(handles.editTssMax, 'string')) * 1E-9;

% LcMin LcMax
LcMin = 0;
LcMax = str2double(get(handles.editLcMax, 'string')) * 1E-9;

% get bin size for delta Lc computation
binSizeDeltaLc = str2double(get(handles.editBinDeltaLc, 'string')) * 1E-9;
xBinDeltaLc = (LcMin + (binSizeDeltaLc/2)):binSizeDeltaLc:LcMax;

% get ratio
maxTssOverLc = str2double(get(handles.editRatio, 'string'));

% get xBinSizeMax
xBinSizeMax = str2double(get(handles.editBinSizeMax, 'string')) * 1E-9;
xBinSizeMax = (LcMin + (xBinSizeMax/2)):xBinSizeMax:LcMax;

% get threshold hist
thresholdHist = str2double(get(handles.editThresholdNPoints, 'string'));

% set xBin
xBin = (LcMin + (binSize/2)):binSize:LcMax;

% set xBin Fc max
xBinFcMax = (FMin + (binSizeFcMax/2)):binSizeFcMax:FMax;

% set histogram
histValue = zeros(1, length(xBin));
maxHistValue = histValue;

% zeros temp max
zerosTempMax = zeros(1, length(histValue));

% get minDeltaLc maxDeltaLc
minDeltaLc = str2double(get(handles.editMinDeltaLc, 'string')) * 1E-9;
maxDeltaLc = str2double(get(handles.editMaxDeltaLc, 'string')) * 1E-9;

% get percDecreasing
startLcDeltaLc = str2double(get(handles.editStartLcDeltaLc, 'string')) * 1E-9;

% get persistenceLength
persistenceLength = str2double(get(handles.editPersistenceLength, 'string')) * 1E-9;