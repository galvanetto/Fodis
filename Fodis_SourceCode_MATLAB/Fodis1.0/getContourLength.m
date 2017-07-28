function [Lc, Fc, LcHist, LcHistMax, xBinLcHist, LcHistVar, FcMax, FcProfile, LcMaxPts] = getContourLength(tss, F, tssMin, tssMax, FMin, FMax, LcMin, LcMax, maxTssOverLc, xBin, binSize, zerosTempMax, offset, xBinMax, thresholdHist, p)
% get contour length
% set threshold ratio
thresholdRatio = maxTssOverLc;

% detect tss between min and max value
idx = tss >= tssMin;
tss = tss(idx);
F = F(idx);

% detect F between min and max value
idx = and(F >= FMin, F <= FMax);
tss = tss(idx);
F = F(idx);

% get constants
kb = 1.3806488E-23; % (JK^-1)
T = 298; % (K)
% range for p from 0.3 - 0.45
alpha = kb*T/p;

% coefficients
a1 = 4;
a2 = (4 * F / (kb*T/p)) - 3;
a3 = 0;
a4 = -1;

% for each measure
bestLc = ones(1, length(F)) * NaN;
for ii = 1:1:length(F)
    
    % get solutions
    lambda = roots([a1 a2(ii) a3 a4]);
    l1 = lambda(1);
    l2 = lambda(2);
    l3 = lambda(3);
    
    % get real solutions
    bestL1 = NaN;
    bestL2 = NaN;
    bestL3 = NaN;
    
    if(imag(l1) == 0 && l1 > 0 && l1 < 1)
        bestL1 = l1;
    elseif(imag(l2) == 0 && l2 > 0 && l2 < 1)
        bestL2 = l2;
    elseif(imag(l3) == 0 && l3 > 0 && l3 < 1)
        bestL3 = l3;
    end
    
    % select solution with min value
    bestL = min([bestL1 bestL2 bestL3]);
    
    % check constraint about ratio
    if((tss(ii)/bestL) > thresholdRatio)
        bestL = NaN;
    end
    
    bestLc(ii) = tss(ii)/(1 - bestL);
    
end

% get histogram about F and Lc
Lc = bestLc;
idx = isnan(Lc);
Lc(idx) = [];
Fc = alpha * (((1 - (tss./Lc)).^-2)/4 + (tss./Lc) - 1/4);
F(idx) = [];

% threshold for Lc
idx = Lc >= LcMin;
Lc = Lc(idx);
Fc = Fc(idx);
F = F(idx);
idx = and(Lc >= LcMin, Lc <= LcMax);
Lc = Lc(idx);
Fc = Fc(idx);
F = F(idx);

% get FcProfile, LcHist and LcHistMax
[FcMax, FcProfile, xBinLcHist, LcHistVar, LcMaxPts] = getMaxLc(Lc, Fc, xBinMax, zerosTempMax, thresholdHist);

% get histogram
LcHist = hist(Lc, xBin);
LcHist(LcHist <= thresholdHist) = 0;

% get LcHistMax
LcHistMax = hist(LcMaxPts, xBin);
LcHistMax(LcHistMax > 1) = 1;

end