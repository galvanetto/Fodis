function [FcMax, FcProfile, xBinLcHistMax, LcHistVar, LcMax] = getMaxLc(Lc, Fc, xBinMax, xBin, zerosTempMax, thresholdNPoints)

maxDiff = 6E-12;

% get binSize
binSize = xBinMax(2) - xBinMax(1);

% get LcHist
LcHist = hist(Lc, xBinMax);

% for each bin
FcMax = zeros(1, length(xBinMax));
FcProfile = zeros(1, length(xBinMax));
toRemove = xBinMax == -Inf;
for ii = 1:1:length(xBinMax)
    
    % get Fc profile
    idxBin = and(Lc >= (xBinMax(ii) - binSize/2), Lc <= (xBinMax(ii) + binSize/2));
    tempFc = Fc(idxBin);
    [m, idxTemp] = max(tempFc);
    tempFc(idxTemp) = [];
    
    % check if the potential local maxima is invalid
    if(~isempty(tempFc) && ~isempty(m) && (min(abs(tempFc - m)) > maxDiff))
        idxBin = and(Lc >= (xBinMax(ii) - binSize * 0.8), Lc <= (xBinMax(ii) + binSize * 0.8));
        tempFc = Fc(idxBin);
        [m1, idxTemp1] = max(tempFc);
        tempFc(idxTemp1) = [];
        if (min(abs(tempFc - m1)) > maxDiff)
            toRemove(ii) = true;
        end
    end
    
    % set profile
    if(~isempty(m))
        FcProfile(ii) = m;
    else
        FcProfile(ii) = 0;
    end
    
end

% remove isolated points
FcProfile(LcHist <= thresholdNPoints) = 0;


%PROVA TOGLI IL RIMUOVI
toRemove = xBinMax == -Inf;


% get peaks Fc profile
[maxValue, idx] = findpeaks(FcProfile, 'MINPEAKDISTANCE', 1);
toRemove = toRemove(idx);
idx(toRemove) = [];
maxValue(toRemove) = [];


% for each local max
LcMax = zeros(1, length(idx));
for ii = 1:1:length(idx)
    % save FcMax
    FcMax(idx(ii)) = maxValue(ii);
    
    % save LcMax
    idxBin = and(Lc >= (xBinMax(idx(ii)) - binSize/2), Lc <= (xBinMax(idx(ii)) + binSize/2));
    idxLcMax = and(idxBin, Fc == FcMax(idx(ii)));
    noDuplicated = Lc(idxLcMax);
    noDuplicated = noDuplicated(1);
    LcMax(ii) = noDuplicated;
end

idxPeaks = idx;
% get max histogram
LcHistMax = zerosTempMax;
LcHistMax(idxPeaks) = 1;

% get histogram max
idx = find(LcHistMax == 1);

% for each idx
LcHistVar = zeros(1, length(idx));
xBinLcHistMax = LcHistVar;
for ii = 1:1:length(idx)
    
    % clean up Lc
    toVar = and(Lc >= (xBinMax(idx(ii)) - binSize/2), Lc <= (xBinMax(idx(ii)) + binSize/2));
    LcVar = Lc(toVar);
    LcVar(isnan(LcVar)) = [];
    LcHistVar(ii) = var(LcVar(:));
    xBinLcHistMax(ii) = xBinMax(idx(ii));
    
end
