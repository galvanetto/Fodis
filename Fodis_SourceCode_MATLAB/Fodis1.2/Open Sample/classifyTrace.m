function [experiment, contactPoint, transientPoint, firstPoint, endPoint, constraints]=...
    classifyTrace(mainHandles,handles,data,indexTrace)
% classify the trace


% get Lc parameters
[tssMin, tssMax, FMin, FMax, xBin, binSize, ~, ~,...
    zerosTempMax, LcMin, LcMax, maxTssOverLc, xBinSizeMax, thresholdHist,...
    ~, ~, ~, ~, ~, persistenceLength] = getLcParameters(mainHandles);

[extendTipSampleSeparation, retractTipSampleSeparation, extendVDeflection,...
    retractVDeflection, ~]  = getTrace(indexTrace, data);
translateLc = data.translateLc(indexTrace);

% get tss F
tss = retractTipSampleSeparation+translateLc;
F = -retractVDeflection;

% get contour lenght
[Lc, Fc, LcHist, LcHistMax, xBinLcHist, LcHistVar, FcMax, FcProfile, ~]...
    = getContourLength(tss, F, tssMin, tssMax, FMin, FMax, LcMin,...
    LcMax, maxTssOverLc, xBin, binSize, zerosTempMax, 0, xBinSizeMax,...
    thresholdHist, persistenceLength);

% initialize
firstPoint.x = [];
firstPoint.y = [];
endPoint.x = [];
endPoint.y = [];

% format value
extendTip = extendTipSampleSeparation * 1E9;
retractTip = retractTipSampleSeparation * 1E9;
extendV = extendVDeflection * 1E12;
retractV = retractVDeflection * 1E12;

% ensure crescent monotony and remove duplicates
[extendTip,idx,~] = unique(extendTip);
extendV = extendV(idx);
[retractTip,idx,~] = unique(retractTip);
retractV = retractV(idx);

% initialize variables
experiment = 1;
[minExtendTip,maxExtendTip] = detectMinMax(extendTip);
[minRetractTip,maxRetractTip] = detectMinMax(retractTip);

constraints.tipSampleSeparation = 1;
constraints.extendMotion = 1;
constraints.slopeInTransient = 1;
constraints.firstDellAtZero = 1;
constraints.extendNoDrifting = 1;
constraints.retractFinished = 1;
constraints.noCrossAfterTransient = 1;

constraints.moreDellsAfterFirstDell = 1;
constraints.distanceInTransient = 1;

constraints.empty = 1;
constraints.LcRange1 = 1;
constraints.LcRange2 = 1;
constraints.unexpectedError = 1;

if isempty(extendV)
    contactPoint.x = NaN;
    contactPoint.y = NaN;
    transientPoint.x = NaN;
    transientPoint.y = NaN;
    firstPoint.x = NaN;
    firstPoint.y = NaN;
    endPoint.x = NaN;
    endPoint.y = NaN;
    experiment = 1;
    constraints.empty = 1;
end


% Get Parameters from Gui
% Parameters Retract
thresholdRetract = str2double(get(handles.editDistanceEndPoint, 'String'));
thresholdVarEndPoint = str2double(get(handles.editThresholdVarEndPoint, 'String'));
% Parameters Extend
maxCrossingDistance = str2double(get(handles.editMaxCrossingDistance, 'String'));
thresholdVarExtendMotion = str2double(get(handles.editThresholdVarExtendMotion, 'String'));
maxDistanceDrifting= str2double(get(handles.editMaxDistanceDrifting, 'String'));

maxSlopeDifference= str2double(get(handles.editMaxSlopeDifference, 'String'));

% % Parameters Global
tipSampleSeparationPerc = str2double(get(handles.editTipSampleSeparation, 'String'));
windowVar = str2double(get(handles.editWindowVar, 'String'));


% get peaks
idx = LcHistMax > 0;

% get xBin
tempXBin = xBin(idx) * 1E9;

% CONSTRAINTS:
% 1) TIP-SAMPLE SEPARATION
% 2) EXTEND MOTION
% 3) SLOPE IN TRANSIENT
% 4) FIRST DELL AT ZERO
% 5) EXTEND NO DRIFTING
% 6) RETRACT FINISHED
% 7) NO CROSS AFTER TRANSIENT
% 8) MORE DELLS
% 9) EMPTY
% 10) AT LEAST ONE PEAK IN LC RANGE1
% 11) END IN LC RANGE
% 12) UNEXPECTED ERROR

if(~isempty(extendV))
    % set threshold to detect the point contact and transient points
    thresholdPoint = 3;
    
    % CONTACT POINT
    [idxContactPoint] = find(retractV <= thresholdPoint, 1, 'first');
    if(isempty(idxContactPoint) || idxContactPoint == 1)
        idxContactPoint = 1;
    end
    x = retractTip(idxContactPoint);
    y = retractV(idxContactPoint);
    contactPoint.x = x;
    contactPoint.y = y;
    
    % TRANSIENT POINT
    [~,idxTransientInterval] = find(extendV <= thresholdPoint, 1, 'first');
    
    if(isempty(idxTransientInterval) || idxTransientInterval == 1)
        idxTransientInterval = 1;
    end
    
    x = extendTip(idxTransientInterval);
    y = extendV(idxTransientInterval);
    transientPoint.x = x;
    transientPoint.y = y;
    
    % get extend
    idx = extendTip <= transientPoint.x;
    transientExtendTip = extendTip(idx);
    transientExtendV = extendV(idx);
    idx = extendTip > transientPoint.x;
    regimeExtendTip = extendTip(idx);
    regimeExtendV = extendV(idx);
    
    % get retract
    idx = retractTip <= transientPoint.x;
    transientRetractTip = retractTip(idx);
    transientRetractV = retractV(idx);
    idx = retractTip > transientPoint.x;
    regimeRetractTip = retractTip(idx);
    regimeRetractV = retractV(idx);
    
    % 1) TIP-SAMPLE SEPARATION
    if(abs(1 - (maxExtendTip - minExtendTip) / (maxRetractTip - minRetractTip)) > tipSampleSeparationPerc)
        constraints.tipSampleSeparation = -1;
    end
    
    % 2) EXTEND MOTION
    if(var(regimeExtendV(:)) > thresholdVarExtendMotion)
        constraints.extendMotion = -1;
    end
    
    % 3) SLOPE IN TRANSIENT
    % Get Slopes
    slope1 = (extendV(1) - transientPoint.y) / (extendTip(1) - transientPoint.x);
    slope2 = (retractV(1) - contactPoint.y) / (retractTip(1) - contactPoint.x);
    if(((slope1 < 0 && slope2 > 0) || (slope1 > 0 && slope2 < 0)) || abs(1 - slope1 / slope2) > maxSlopeDifference)
        constraints.slopeInTransient = -1;
    end
    
    % 4 6
    idxVarPeaks = [];
    % check if there is only noise
    if(-min(regimeRetractV(:)) <= thresholdRetract)
        % violation 4 6
        constraints.firstDellAtZero = -1;
        constraints.retractFinished = -1;
    else
        % set retract window
        [windowVarEndPoint] = find((regimeRetractTip - regimeRetractTip(1)) > windowVar, 1, 'first');
        if(isempty(windowVarEndPoint) || windowVarEndPoint < 5)
            windowVarEndPoint = 5;
        else
            windowVarEndPoint = windowVarEndPoint - 1;
        end
        if(mod(windowVarEndPoint, 2) == 0)
            windowVarEndPoint = windowVarEndPoint + 1;
        end
        
        % moving average filtering
        if(size(regimeRetractV, 1) == 1 && size(regimeRetractV, 2) > 1)
            retractVFiltered = medfilt1(padarray(regimeRetractV', windowVarEndPoint, 'replicate')', windowVarEndPoint);
            % retractVFiltered = movavgFilt(padarray(retractV', windowVarEndPoint, 'both')', windowVarEndPoint, 'Center');
        else
            retractVFiltered = medfilt1(padarray(regimeRetractV, windowVarEndPoint, 'replicate'), windowVarEndPoint);
            % retractVFiltered = movavgFilt(padarray(retractV, windowVarEndPoint, 'both'), windowVarEndPoint, 'Center');
        end
        
        retractVFiltered = retractVFiltered((windowVarEndPoint + 1):1:(windowVarEndPoint + length(regimeRetractV)));
        
        % END POINT
        % get moving variance
        varRetractV = movingstd(padarray(retractVFiltered', windowVarEndPoint, 'replicate')', windowVarEndPoint) .^ 2;
        varRetractV = varRetractV(windowVarEndPoint:1:(windowVarEndPoint + length(regimeRetractV) - 1));
        [peaks,idxVarPeaks] = findpeaks(varRetractV, 'MINPEAKHEIGHT', thresholdVarEndPoint);
        idxVarPeaks(regimeRetractV(idxVarPeaks) <= -thresholdRetract) = [];
        idxVarPeaks(regimeRetractTip(idxVarPeaks) <= transientPoint.x) = [];
        
        if(~isempty(idxVarPeaks) && (idxVarPeaks(length(idxVarPeaks)) >=(length(regimeRetractTip) - windowVarEndPoint)))
            idxVarPeaks(length(idxVarPeaks)) = [];
        end
        
        endPoint.x = [];
        endPoint.y = [];
        
        if(~isempty(idxVarPeaks))
            idx = idxVarPeaks(length(idxVarPeaks));
            endPoint.x = regimeRetractTip(idx);
            endPoint.y = regimeRetractV(idx);
        end
        
        % 4) FIRST DELL AT ZERO
        firstPoint.x = [];
        firstPoint.y = [];
        if(~isempty(idxVarPeaks))
            firstPoint.x = regimeRetractTip(idxVarPeaks(1));
            firstPoint.y = regimeRetractV(idxVarPeaks(1));
        end
        if(isempty(idxVarPeaks))
            constraints.firstDellAtZero = -1;
        end
        % 6) RETRACT FINISHED
        if(isempty(endPoint.y) || -regimeRetractTip(length(regimeRetractTip)) > thresholdRetract) || -regimeRetractV(end) > thresholdRetract
            constraints.retractFinished = -1;
        end
    end
    
    % 5) EXTEND NO DRIFTING
    if(max(regimeExtendV(:)) - min(regimeExtendV(:)) > maxDistanceDrifting)
        constraints.extendNoDrifting = -1;
    end
    
    % 7) NO CROSS AFTER TRANSIENT
    % detect the min max value for tss
    minTip1 = min(extendTip(:));
    maxTip1 = max(extendTip(:));
    minTip2 = min(retractTip(:));
    maxTip2 = max(retractTip(:));
    if(minTip1 > minTip2)
        minTip = minTip1;
    else
        minTip = minTip2;
    end
    if(maxTip1 < maxTip2)
        maxTip = maxTip1;
    else
        maxTip = maxTip2;
    end
    
    % set retract to start from minTip
    idx = retractTip >= minTip;
    retractTip = retractTip(idx);
    retractV = retractV(idx);
    idx = retractTip <= maxTip;
    retractTip = retractTip(idx);
    retractV = retractV(idx);
    
    % set extend to start from minTip
    idx = extendTip >= minTip;
    extendTip = extendTip(idx);
    extendV = extendV(idx);
    idx = extendTip <= maxTip;
    extendTip = extendTip(idx);
    extendV = extendV(idx);
    
    % interpolate data
    [extendTip, retractTip, extendV, retractV] = interpolateValidRange(extendTip, retractTip, extendV, retractV);
    regimeRetractV = retractV(retractTip > transientPoint.x);
    idx = round(length(regimeRetractV) * 0.1):1:(length(regimeRetractV) - 10);
    regimeRetractV = regimeRetractV(idx);
    regimeInterpExtendV = extendV(extendTip > transientPoint.x);
    regimeInterpExtendV = regimeInterpExtendV(idx);
    
    idx = regimeRetractV > regimeInterpExtendV;
    if(sum(idx(:)) ~= 0)
        % get distance when retract is greater then extend
        distanceRegime = regimeRetractV(idx) - regimeInterpExtendV(idx);
        if(max(distanceRegime(:)) > maxCrossingDistance)
            experiment = -1;
            constraints.noCrossAfterTransient = -1;
        end
    end
    
    
    % 9) EMPTY
    % check if the trace has not any peaks
    if isempty(tempXBin)
        constraints.empty = -1;
    end
    
end


function [eTip, rTip, eV, rV] = interpolateValidRange(extendTip, retractTip, extendV, retractV)
% interpolate value in valid range

% detect major vector
tipI = extendTip;
if(length(tipI) < length(retractTip))
    tipI = retractTip;
end

% interpolate
eV = interp1(extendTip, extendV, tipI, 'nearest');
rV = interp1(retractTip, retractV, tipI, 'nearest');
eTip = tipI;
rTip = tipI;

toRemove = isnan(eV) + isnan(rV);
toRemove = toRemove ~= 0;
eV(toRemove) = [];
rV(toRemove) = [];
eTip(toRemove) = [];
rTip(toRemove) = [];



function [minValue,maxValue] = detectMinMax(trace)
% detect min max
minValue = min(trace(:));
maxValue = max(trace(:));


