function setParams(handles, params)

% get params from GUI
set(handles.editDensityPlot, 'string',num2str(params.DensityPlot));
set(handles.editRatioReference, 'string',num2str(params.RatioReference));
set(handles.SG_k, 'string',num2str(params.SG_k));
set(handles.SG_f, 'string',num2str(params.SG_f));

set(handles.editTraceMinTss, 'string',num2str(params.scaleMinTss));
set(handles.editTraceMaxTss, 'string',num2str(params.scaleMaxTss ));
set(handles.editTraceMinF, 'string',num2str(params.scaleMinF));
set(handles.editTraceMaxF, 'string',num2str(params.scaleMaxF));
set(handles.editSizeMarker, 'string',num2str(params.editSizeMarker));

if ~isempty(params.editLcTraces)
allOneString = sprintf('%.0f,' , str2double(params.editLcTraces));  %string conversion
allOneString = allOneString(1:end-1);                            %remove the comma
set(handles.editLcTraces, 'string',allOneString);                % show selection
end

set(handles.checkboxFlipTraces, 'value',params.FlipTraces);
set(handles.checkboxGrid, 'value',params.Grid);
set(handles.SGL_fil, 'value',params.SG_fil);
set(handles.sliderTraces, 'value',params.sliderTraces);

%Lc
set(handles.editFMin, 'string',num2str(params.FMin));
set(handles.editFMax, 'string',num2str(params.FMax));
set(handles.editBinSize, 'string',num2str(params.binSize));
set(handles.editBinSizeFcMax, 'string',num2str(params.binSizeFcMax));
set(handles.editTssMax, 'string',num2str(params.tssMax)) ;
set(handles.editBinDeltaLc, 'string',num2str(params.binSizeDeltaLc ));
set(handles.editStartLcDeltaLc, 'string',num2str(params.startLcDeltaLc));
set(handles.editMinP, 'string',num2str(params.minP));
set(handles.editMaxP, 'string',num2str(params.maxP));
set(handles.editBinP, 'string',num2str(params.binP ));

set(handles.editRatio, 'string',num2str(params.maxTssOverLc));
set(handles.editBinSizeMax, 'string',num2str(params.xBinSizeMax ));
set(handles.editThresholdNPoints, 'string',num2str(params.thresholdHist));
set(handles.ediMaxDiffForce, 'string',num2str(params.diffforce));
set(handles.editLcMax, 'string',num2str(params.LcMax));
set(handles.editMinDeltaLc, 'string',num2str(params.minDeltaLc));
set(handles.editMaxDeltaLc, 'string',num2str(params.maxDeltaLc));
set(handles.editPersistenceLength, 'string',num2str(params.persistenceLength ));
set(handles.editBinHistP, 'string',num2str(params.binhistp));
set(handles.editBinFit, 'string',num2str(params.BinFit));

setappdata(handles.fig_FtW,'triggerLc2',params.triggerLc2);
setappdata(handles.fig_FtW,'triggerLc',params.triggerLc);