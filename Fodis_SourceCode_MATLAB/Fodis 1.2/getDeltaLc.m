function [deltaLc, deltaLcFc, lcDeltaLc] = getDeltaLc(startLcDeltaLc, lcMaxPts, FcMax, minDeltaLc, maxDeltaLc, xBinDeltaLc)
% Compute delta Lc

% remove peaks at Lc <= minDeltaLc or Lc >= maxDeltaLc
idx = lcMaxPts <= startLcDeltaLc;
lcMaxPts(idx) = [];
FcMax = FcMax(FcMax > 0);
FcMax(idx) = [];

% compute deltaLc
diffLc = diff([0, lcMaxPts]);

% get all points outside the range
idx = or(lcMaxPts <= minDeltaLc, lcMaxPts >= maxDeltaLc);

% remove all points outside the range
diffLc(idx) = [];
lcMaxPts(idx) = [];
FcMax(idx) = [];

% compute histogram
deltaLc = hist(diffLc, xBinDeltaLc);

% initialize deltaLcFc lcDeltaLc
deltaLcFc = zeros(length(lcMaxPts), 2);
lcDeltaLc = deltaLcFc;

% % for each peak
% for ii = 1:length(lcMaxPts)
    % set Fc
    deltaLcFc(:, 1) = diffLc;
    deltaLcFc(:, 2) = FcMax;
    
    % set Lc
    lcDeltaLc(:, 1) = diffLc;
    lcDeltaLc(:, 2) = lcMaxPts;
    
% end



%%
%SECOND OPTION
% Compute delta Lc

% % remove peaks at Lc <= minDeltaLc or Lc >= maxDeltaLc
% idx = lcMaxPts <= startLcDeltaLc;
% lcMaxPts(idx) = [];
% FcMax = FcMax(FcMax > 0);
% FcMax(idx) = [];
% 
% % compute deltaLc (first element is Delta between second and first peak)
% diffLc = diff(lcMaxPts);
% 
% % get all points outside the range
% idx = or(lcMaxPts <= minDeltaLc, lcMaxPts >= maxDeltaLc);
% 
% % remove all points outside the range
% diffLc(idx) = [];
% lcMaxPts(idx) = [];
% FcMax(idx) = [];
% 
% % compute histogram
% deltaLc = hist(diffLc, xBinDeltaLc);
% 
% % initialize deltaLcFc lcDeltaLc
% deltaLcFc = zeros(length(lcMaxPts)-1, 2);
% lcDeltaLc = deltaLcFc;
% 
% % % for each peak
% % for ii = 1:length(lcMaxPts)
%     % set Fc
%     deltaLcFc(:, 1) = diffLc;
%     deltaLcFc(:, 2) = FcMax(2:end);
%     
%     % set Lc
%     lcDeltaLc(:, 1) = diffLc;
%     lcDeltaLc(:, 2) = lcMaxPts(2:end);
%     
% % end
% %%