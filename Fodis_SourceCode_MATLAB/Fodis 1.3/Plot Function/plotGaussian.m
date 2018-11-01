function plotGaussian(xBin, maxHistValue)

global data
gaussianWindow=data.gaussianWindow;

% get colors
rgb = distinguishable_colors(length(gaussianWindow), [1 1 1; 0 0 0; 1 0 0; 0 0 1]);
% for each gaussian window
for ii = 1:1:length(gaussianWindow)
    
    % get points
    idx = (and(xBin >= gaussianWindow(ii).start, xBin <= gaussianWindow(ii).end));
    
    % check if there are some points to analyze
    if(sum(idx(:)) > 0)
        
        % get max value
        t = maxHistValue;
        t(idx == 0) = 0;
        
        % fit with gaussian
        selectedXBin = 1:1:length(xBin);
        selectedMaxHist = t;
        [sigma, mu, normFactor] = gaussfit(selectedXBin, selectedMaxHist);
        
        % get gaussian function
        gaussianFunction = (1 / (sqrt(2*pi) * sigma)) * exp(-((selectedXBin - mu).^2) / (2*(sigma^2)));
        if(normFactor > 1.5 || normFactor < 0.5)
            gaussianFunction = gaussianFunction * normFactor;
        end
        hold on;
        hbar=bar(xBin(idx) * 1E9, t(idx), 1, 'BaseValue', 0, 'FaceColor', rgb(ii, :, :), 'EdgeColor', [1 1 1]);
        set(hbar,'tag','colorhist')
        ha=area(xBin * 1E9, gaussianFunction, 1, 'BaseValue', 0, 'FaceColor', rgb(ii, :, :), 'EdgeColor', [1 1 1]);
        alpha(ha,0.3)
        
        hold on
        plot(xBin * 1E9, gaussianFunction, '--', 'color', rgb(ii, :, :), 'LineWidth', 1.5);
        text(0.73, 1 - 0.03 * ii, [sprintf('p=%.2f', sum(t(idx))) ...
            sprintf(' std=%.2f', sigma * (xBin(2) - xBin(1)) * 1E9) ...
            sprintf(' avg=%.2f', mu * (xBin(2) - xBin(1)) * 1E9)], ...
            'color', rgb(ii, :, :), 'Units', 'normalized');
        
    end
    
end