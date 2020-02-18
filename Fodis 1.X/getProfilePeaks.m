function [lcPeaks, slideTrace] = getProfilePeaks(tss, F, tssMin, tssMax, FMin, FMax, LcMin, LcMax, maxTssOverLc, xBin, binSize, zerosTempMax, translateLc, xBinSizeMax, thresholdHist, initialPersistanceLength)

% to avoid step
stepTss = (xBinSizeMax(2) - xBinSizeMax(1)) / 2;
% stepTss = 3E-9;

% maximum deviation from initial position of the peaks
% rangeLc = 20E-9;

% get peaks
[Lc, Fc, LcHist, LcHistMax, xBinLcHist, LcHistVar, FcMax, FcProfile, lcPeaks] = getContourLength(tss, F, tssMin, tssMax, FMin, FMax, LcMin, LcMax, maxTssOverLc, xBin, binSize, zerosTempMax, translateLc, xBinSizeMax, thresholdHist, initialPersistanceLength); 
maxF = max(FcMax);
% binSizeMax = xBinSizeMax(2) - xBinSizeMax(1);

% initialize slideTrace {slide of the F; startPoint; endPoint}
slideTrace = zeros(length(lcPeaks), 2);
idxPeaks = lcPeaks > 0;

% for each peak
for ii = 1:length(lcPeaks)
    [tempFc, tempTssc] = getFFromLc(lcPeaks(ii), initialPersistanceLength, tss);
    
    % check if this is the first slide
    if(ii == 1)
        % the startPoint is the first point above 0
        startPoint = find(F > 0, 1, 'first');
        
        % check if the initial part of the trace is messy
        if(startPoint > length(tempFc))
            startPoint = length(tempFc);
        end
        
    else
        % the next startPoint is the previous endPoint + binSize
        try
            tempTss = tss(slideTrace(ii - 1, 2):end);
        catch e
            disp('err');
        end
        
        if(isempty(tempTss))
            idxPeaks(ii) = 0;
            
            startPoint = slideTrace(ii - 1, 2);
        else
            rangeTss = find((tempTss - tempTss(1)) >= stepTss, 1, 'first');
            startPoint = slideTrace(ii - 1, 2) + rangeTss;
        end
        
    end
    
    % the endPoint is the contact point between the fit and the last part
    % of the F slide
    idxFc = find(tempFc >= maxF, 1, 'first');
    
    if(isempty(idxFc) || startPoint > idxFc)
        idxFc = startPoint;
        idxPeaks(ii) = 0;
    end
    
    currentF = F(startPoint:idxFc);
    [distValue, endPoint] = min(abs(currentF - tempFc(startPoint:idxFc)));
    endPoint = startPoint + endPoint - 1;
    
    ii
    % save slide
    slideTrace(ii, 1) = startPoint; % start point
    slideTrace(ii, 2) = endPoint; % end point
    
    % check if the slide is empty due noise
    if(endPoint - startPoint < 2)
        idxPeaks(ii) = 0;
    end
end
    
% clean up slides
lcPeaks = lcPeaks(idxPeaks);
slideTrace = slideTrace(idxPeaks, :);