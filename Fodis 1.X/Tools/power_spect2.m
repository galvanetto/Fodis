function power_spect2(handles)

global data
global positiveResult

data.tailex={};
data.tailre={};



nTraces = positiveResult.nTraces;

hhh=waitbar(0,'Wait...');

for ii=1:1:nTraces
    
    
    % update index trace and nTraces
    %Nr total traces
    indexTrace = ii;
    indexeffTrace=positiveResult.indexTrace(indexTrace);       %Actual trace
    
    
    %%  same as showTraces()
    %Load Translation
    translateLc = data.translateLc(indexeffTrace);
    
    % get size marker
    sizeMarker = str2double (get(handles.editSizeMarker, 'string')) * 3;
    % get flag flip
    flagFlip = get(handles.checkboxFlipTraces, 'value');
    
    % get colors
    rgb = distinguishable_colors(nTraces, [1 1 1; 0 0 0; 1 0 0]);
    
    % get Lc parameters
    [tssMin,tssMax,FMin,FMax,xBin,binSize,histValue,maxHistValue,zerosTempMax,...
        LcMin,LcMax,maxTssOverLc,xBinSizeMax,thresholdHist,xBinFcMax,...
        xBinDeltaLc, minDeltaLc, maxDeltaLc, startLcDeltaLc, persistenceLength]...
        = getLcParameters(handles);
    
    % Set GUI values
    set(handles.textFrameRate, 'String', ['/' num2str(nTraces)]);
    set(handles.editFrame, 'String', num2str(indexTrace));
    
    set(handles.sliderTraces, 'Value', indexTrace);
    set(handles.sliderTraces, 'Max', nTraces);
    set(handles.sliderTraces, 'SliderStep', [1 1] / nTraces);
    set(handles.sliderTraces, 'Value', indexTrace);
    set(handles.SGL_fil,'Value',data.SGFilter(indexeffTrace));
    
    [extendTipSampleSeparation,retractTipSampleSeparation,extendVDeflection,...
        retractVDeflection]= getTrace(indexeffTrace, data);
    
    if flagFlip == 1;mirror=-1;else mirror=1;end %flip the signale
    
    temp_e = mirror*extendVDeflection;
    temp_r = mirror*retractVDeflection;
    
    % get tss F
    tss = retractTipSampleSeparation+translateLc;
    F = -retractVDeflection;
    
    
    % get contour lenght
    [Lc, Fc, LcHist, LcHistMax, xBinLcHist, LcHistVar, FcMax, FcProfile, LcMaxPts]...
        = getContourLength(tss, F, tssMin, tssMax, FMin, FMax, LcMin, LcMax,...
        maxTssOverLc, xBin, binSize, zerosTempMax,0, xBinSizeMax,...
        thresholdHist, persistenceLength);
    %%
    
    %keep in mind that
    % 1 . retract speed is half of extend
    % 2 . extend is in the opposite order (need FLIP) ofr oposite counting
    
    retractTipSampleSeparation_2=retractTipSampleSeparation(1:1:end);
    retractVDeflection_2=retractVDeflection(1:1:end);
    
    if ~isempty(LcMaxPts)
        idx_last_peak=min( find( retractTipSampleSeparation_2 > max(LcMaxPts) ) ) + 10;
    else
        idx_last_peak=300;
    end
    
    
    extendVDeflection_flip=flip(extendVDeflection);
    
    
   
    
    figure(100)
    
    
    cla
    hold on
    
    plot(retractVDeflection_2(idx_last_peak:end),'b' );
    plot(extendVDeflection_flip(idx_last_peak:end),'r' );
    
    
    
    
    
    data.tailex{end+1}=extendVDeflection_flip(idx_last_peak:end);
    data.tailre{end+1}=retractVDeflection_2(idx_last_peak:end);
    
    
end

delete(hhh);

end