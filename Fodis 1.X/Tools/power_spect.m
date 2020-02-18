function power_spect(handles)

global data
global positiveResult

%%  same as showTraces()
% update index trace and nTraces
nTraces = positiveResult.nTraces;                          %Nr total traces
indexTrace = min( round(get(handles.sliderTraces, 'value')), nTraces);    %Slider Position
indexeffTrace=positiveResult.indexTrace(indexTrace);       %Actual trace

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

retractTipSampleSeparation_2=retractTipSampleSeparation(1:2:end);
retractVDeflection_2=retractVDeflection(1:2:end);

if ~isempty(LcMaxPts)
    idx_last_peak=min( find( retractTipSampleSeparation_2 > max(LcMaxPts) ) ) + 10;
else
    idx_last_peak=100;
end
extendVDeflection_flip=flip(extendVDeflection);


figure(99)


%cla
hold on
%set(gca, 'XScale', 'log')

%% Power spectrum

% [pxxre,w] = periodogram( retractVDeflection_2(idx_last_peak:end) );
% plot(w,10*log10(pxxre),'b');
% 
% [pxxex,w] = periodogram( extendVDeflection_flip(idx_last_peak:end) );
% plot(w,10*log10(pxxex),'r');

%% FFT

Y=fft(retractVDeflection_2(idx_last_peak:end));
L=2000;
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);
plot( P1 ,'b' );

%%

Y=fft(extendVDeflection_flip(idx_last_peak:end));
L=2000;
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);
plot( P1 ,'r' );


    
figure(100)


cla
hold on

plot(retractVDeflection_2(idx_last_peak:end),'b' );
plot(extendVDeflection_flip(idx_last_peak:end),'r' );




% try
%     data.tailex{end+1}=extendVDeflection_flip(idx_last_peak:end);
%     data.tailre{end+1}=retractVDeflection_2(idx_last_peak:end);
% catch ME
%     data.tailex={};
%     data.tailre={};
% end

end