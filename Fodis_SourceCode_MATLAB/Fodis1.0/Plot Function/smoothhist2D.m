function smoothhist2D(X, nTraces, nbins, outliercutoff, plottype, rangeTss, rangeF, marker, markerSize, flagPerPoints, ratioReference)
% SMOOTHHIST2D Plot a smoothed histogram of bivariate data.
%   SMOOTHHIST2D(X,LAMBDA,NBINS) plots a smoothed histogram of the bivariate
%   data in the N-by-2 matrix X.  Rows of X correspond to observations.  The
%   first column of X corresponds to the horizontal axis of the figure, the
%   second to the vertical. LAMBDA is a positive scalar smoothing parameter;
%   higher values lead to more smoothing, values close to zero lead to a plot
%   that is essentially just the raw data.  NBINS is a two-element vector
%   that determines the number of histogram bins in the horizontal and
%   vertical directions.
%
%   SMOOTHHIST2D(X,LAMBDA,NBINS,CUTOFF) plots outliers in the data as points
%   overlaid on the smoothed histogram.  Outliers are defined as points in
%   regions where the smoothed density is less than (100*CUTOFF)% of the
%   maximum density.
%
%   SMOOTHHIST2D(X,LAMBDA,NBINS,[],'surf') plots a smoothed histogram as a
%   surface plot.  SMOOTHHIST2D ignores the CUTOFF input in this case, and
%   the surface plot does not include outliers.
%
%   SMOOTHHIST2D(X,LAMBDA,NBINS,CUTOFF,'image') plots the histogram as an
%   image plot, the default.
%
%   Example:
%       X = [mvnrnd([0 5], [3 0; 0 3], 2000);
%            mvnrnd([0 8], [1 0; 0 5], 2000);
%            mvnrnd([3 5], [5 0; 0 1], 2000)];
%       smoothhist2D(X,5,[100, 100],.05);
%       smoothhist2D(X,5,[100, 100],[],'surf');
%
%   Reference:
%      Eilers, P.H.C. and Goeman, J.J (2004) "Enhancing scaterplots with
%      smoothed densities", Bioinformatics 20(5):623-628.

%   Copyright 2009 The MathWorks, Inc.
%   Revision: 1.0  Date: 2006/12/12
%
%   Requires MATLAB? R14.

% remove data
idx = or(X(:, 1) < rangeTss(1), X(:, 1) > rangeTss(2));
X(idx, :) = [];

idx = or(X(:, 2) < rangeF(1), X(:, 2) > rangeF(2));
X(idx, :) = [];

if nargin < 4 || isempty(outliercutoff), outliercutoff = .05; end
if nargin < 5, plottype = 'image'; end

minx = [rangeTss(1), rangeF(1)];
maxx = [rangeTss(2), rangeF(2)];
edges1 = linspace(minx(1), maxx(1), nbins(1)+1);
ctrs1 = edges1(1:end-1) + .5*diff(edges1);
edges1 = [-Inf edges1(2:end-1) Inf];
edges2 = linspace(minx(2), maxx(2), nbins(2)+1);
ctrs2 = edges2(1:end-1) + .5*diff(edges2);
edges2 = [-Inf edges2(2:end-1) Inf];

[n,p] = size(X);
bin = zeros(n,2);
% Reverse the columns of H to put the first column of X along the
% horizontal axis, the second along the vertical.
[dum,bin(:,2)] = histc(X(:,1),edges1);
[dum,bin(:,1)] = histc(X(:,2),edges2);
H = accumarray(bin,1,nbins([2 1])) * ratioReference / nTraces;

% Eiler's 1D smooth, twice
% G = smooth1D(H,0.5);
% F = smooth1D(G',0.5)';
% % An alternative, using filter2.  However, lambda means totally different
% % things in this case: for smooth1D, it is a smoothness penalty parameter,
% % while for filter2D, it is a window halfwidth
% F = filter2D(H,lambda);

F = H;
F(F == 0) = NaN;
relF = F;

% relF = F./max(F(:));
% if outliercutoff > 0
%     outliers = (relF(nbins(2)*(bin(:,2)-1)+bin(:,1)) < outliercutoff);
% end

% generate inverted jet colors
nc = 128;
colors = jet(nc);
sizeColors = size(colors);
[dummy, idx] = sort(1:sizeColors(1), 'descend');
colors = colors(idx, :, :);

% first pure red color
idxRed = find(colors(:, 1) == 1, 1, 'first');

% generate white to red colors
for ii = 1:(idxRed - 1)
    r = 1;
    g = 1 - (ii - 1) / (idxRed - 1);
    b = g;
    colors(ii, :, :) = [r, g, b];
end

colormap(colors);

switch plottype
case 'surf'
    surf(ctrs1,ctrs2,relF,'edgealpha',0);
case 'image'
    if(flagPerPoints == 1)
        % get nPts
        nPts = length(X(:, 1));

        ax = gca;

        hold on;
        h = waitbar(0, 'Please wait...');

        % initialize vector of colors
        vectorColor = zeros(1, nPts);

        % for each point to plot
        for ii = 1:nPts

            col = bin(ii, 1);
            row = bin(ii, 2);

            % get color
            iiColor = round(relF(col, row) * nc);
            if(iiColor < 1)
                iiColor = 1;
            end
            if(iiColor > nc)
                iiColor = nc;
            end
            vectorColor(ii) = iiColor;

        end

        for ii = 1:nc

            % get all points with the same color
            idx = vectorColor == ii;

            % check if there are some points to plot with the same color
            if(sum(idx(:)) > 0)
                % get x y
                x = X(idx, 1);
                y = X(idx, 2);

                % get color
                color = colors(ii, :, :);

                % plot
                plot(ax, x, y, marker, 'MarkerSize', markerSize, 'color', color);

            end

            if(mod(ii, round(0.1 * nc)) == 0)
                waitbar(ii/nc);
            end
        end

        delete(h);
    else
        imagesc(ctrs1, ctrs2, relF, [0, 1]);
        set(gca, 'YDir', 'normal')
    end
end

%-----------------------------------------------------------------------------
function Z = smooth1D(Y,lambda)
[m,n] = size(Y);
E = eye(m);
D1 = diff(E,1);
D2 = diff(D1,1);
P = lambda.^2 .* D2'*D2 + 2.*lambda .* D1'*D1;
Z = (E + P) \ Y;
% This is a better solution, but takes a bit longer for n and m large
% opts.RECT = true;
% D1 = [diff(E,1); zeros(1,n)];
% D2 = [diff(D1,1); zeros(1,n)];
% Z = linsolve([E; 2.*sqrt(lambda).*D1; lambda.*D2],[Y; zeros(2*m,n)],opts);


%-----------------------------------------------------------------------------
function Z = filter2D(Y,bw)
z = -1:(1/bw):1;
k = .75 * (1 - z.^2); % epanechnikov-like weights
k = k ./ sum(k);
Z = filter2(k'*k,Y);
