function [bestP, bestPeaks] = fitPersistanceLength(tss, F, listP, tssMin, tssMax, FMin, FMax, LcMin, LcMax, maxTssOverLc, xBin, binSize, zerosTempMax, translateLc, xBinSizeMax, thresholdHist, initialPersistanceLength)
% Fit the given trace with variable persistance length

[lcPeaks, slideTrace] = getProfilePeaks(tss, F, tssMin, tssMax, FMin, FMax,...
    LcMin, LcMax, maxTssOverLc, xBin, binSize, zerosTempMax, translateLc,...
    xBinSizeMax, thresholdHist, initialPersistanceLength);

% to improve the performance
listLcPeaks = cell(1, length(listP));

for iiP = 1:length(listP)
    % get contours
    [~, ~, ~, ~, ~, ~, ~, ~,listLcPeaks{iiP}]= getContourLength(tss, F, tssMin, tssMax,...
        FMin, FMax, LcMin, LcMax, maxTssOverLc, xBin, binSize, zerosTempMax,...
        translateLc, xBinSizeMax, thresholdHist, listP(iiP));
end

% initialize varables
bestP = lcPeaks;

% for each stable peak
bestPeaks = lcPeaks;
for iiMax = 1:length(lcPeaks)
    
    % initialize variables to check best lsq
    bestCurrentLsq = Inf;
    bestCurrentP = 0;
    rangeSlide = slideTrace(iiMax, 1):slideTrace(iiMax, 2);
    
    FPeaks = F(rangeSlide);
    
    if(isempty(rangeSlide)); continue;end
    
    % get lcMax
    lcMax = lcPeaks(iiMax);
        
    % for each persistance length
    for iiP = 1:length(listP)
        
        % get lc peaks
        tempLcPeaks = listLcPeaks{iiP};
        
        [~, idxNearestPeak] = min(abs(tempLcPeaks - lcMax));
        
        tempLcPeaks = tempLcPeaks(idxNearestPeak);
        if(isempty(tempLcPeaks) == 0)
        
            % get tempFc tempTssc from lcMax and persistanceLength
            [tempFc, ~] = getFFromLc(tempLcPeaks, listP(iiP), tss);
            
            % check bad fit
            if(rangeSlide(1) > length(tempFc))
                continue;
            end
            
            if(rangeSlide(end) > length(tempFc))
                tempFc(length(tempFc) + 1:rangeSlide(end)) = tempFc(end);   
            end
            
            tempFc = tempFc(rangeSlide);
                        
            % get lsq
            tempLsq = sum((tempFc - FPeaks).^2);
            if(tempLsq < bestCurrentLsq)
                bestPeaks(iiMax) = tempLcPeaks;
                bestCurrentLsq = tempLsq;
                bestCurrentP = listP(iiP); 
            end

        end
    
    end
        
    % finalize lsq
    bestP(iiMax) = bestCurrentP;
    
end

end
