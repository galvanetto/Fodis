function [Fc] = getFitTrace(tss, lcPeaks, slideTrace, persistenceLength, xBinMax)

% initialize fitTrace
fitTrace = zeros(1, length(tss));
Fc = zeros(1, length(xBinMax));
binSize = xBinMax(2) - xBinMax(1);

% for each peak
for ii = 1:length(lcPeaks)    
    
    % get tempFc tempTssc from lcMax and persistanceLength
    [tempFc,~] = getFFromLc(lcPeaks(ii), persistenceLength, tss);
    
    % build fitTrace
    if(ii == 1)
        % get rangeSlide
        rangeSlide = slideTrace(ii, 1):slideTrace(ii, 2);        
    else
        % get rangeSlide
        rangeSlide = slideTrace(ii - 1, 2):slideTrace(ii, 2);
    end
    
    fitTrace(rangeSlide) = tempFc(rangeSlide);
    
end

% for each bin
for ii = 1:length(xBinMax)
    maxValue = max(fitTrace(and(tss >= xBinMax(ii) - binSize/2, tss < xBinMax(ii) + binSize/2)));
    if(~isempty(maxValue))
        Fc(ii) = maxValue;
    end
end