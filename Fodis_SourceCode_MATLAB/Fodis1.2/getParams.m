function [params] = getParams(handles)

% get params from GUI
params.DensityPlot=str2double(get(handles.editDensityPlot, 'string'));
params.RatioReference=str2double(get(handles.editRatioReference, 'string'));
params.SG_k=str2double(get(handles.SG_k, 'string'));
params.SG_f=str2double(get(handles.SG_f, 'string'));

params.scaleMinTss = str2double(get(handles.editTraceMinTss, 'string'));
params.scaleMaxTss = str2double(get(handles.editTraceMaxTss, 'string'));
params.scaleMinF = str2double(get(handles.editTraceMinF, 'string'));
params.scaleMaxF = str2double(get(handles.editTraceMaxF, 'string'));
params.intervals=str2double(get(handles.NrIntGroup,'string'));
params.editSizeMarker=str2double(get(handles.editSizeMarker, 'string'));
params.editLcTraces=strsplit(get(handles.editLcTraces, 'string'),',');

params.sliderTraces=get(handles.sliderTraces, 'value');
params.FlipTraces=get(handles.checkboxFlipTraces, 'value');
params.Grid=get(handles.checkboxGrid, 'value');
params.SG_fil=get(handles.SGL_fil, 'value');

%Lc
params.FMin = str2double(get(handles.editFMin, 'string'));
params.FMax = str2double(get(handles.editFMax, 'string'));
params.binSize = str2double(get(handles.editBinSize, 'string'));
params.binSizeFcMax = str2double(get(handles.editBinSizeFcMax, 'string'));
params.tssMax = str2double(get(handles.editTssMax, 'string')) ;
params.binSizeDeltaLc = str2double(get(handles.editBinDeltaLc, 'string'));
params.startLcDeltaLc = str2double(get(handles.editStartLcDeltaLc, 'string'));
params.minP = str2double(get(handles.editMinP, 'string'));
params.maxP = str2double(get(handles.editMaxP, 'string'));
params.binP = str2double(get(handles.editBinP, 'string'));

params.maxTssOverLc = str2double(get(handles.editRatio, 'string'));
params.xBinSizeMax = str2double(get(handles.editBinSizeMax, 'string'));
params.thresholdHist = str2double(get(handles.editThresholdNPoints, 'string'));
params.diffforce=str2double(get(handles.ediMaxDiffForce, 'string'));
params.LcMax = str2double(get(handles.editLcMax, 'string'));
params.minDeltaLc = str2double(get(handles.editMinDeltaLc, 'string'));
params.maxDeltaLc = str2double(get(handles.editMaxDeltaLc, 'string'));
params.persistenceLength = str2double(get(handles.editPersistenceLength, 'string'));
params.binhistp=str2double(get(handles.editBinHistP, 'string'));
params.BinFit=str2double(get(handles.editBinFit, 'string'));

params.triggerLc2= getappdata(handles.fig_FtW,'triggerLc2');
params.triggerLc= getappdata(handles.fig_FtW,'triggerLc');