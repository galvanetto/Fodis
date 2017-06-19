function rangedeltaLc(handles,data,selected_traces,selected_lcDeltaLcROI,sizeMarker,indexSelected)

figure;
plot(selected_traces(:, 1) * 1E9, selected_traces(:, 2) * 1E12, '.', 'markerSize', sizeMarker, 'color', [1, 0, 0]);

xlim([data.scaleMinTss data.scaleMaxTss]);
% ylim([0, max(lcDeltaLc(:, 2)) * 1E9]);

title(['Selected traces ', num2str(indexSelected)]);
xlabel('tss (nm)');
ylabel('F (pN)');

% plot histogram
figure;
subplot(2, 1, 1);
plot(selected_lcDeltaLcROI(:, 1) * 1E9, selected_lcDeltaLcROI(:, 2) * 1E9, 'x', 'markerSize', sizeMarker, 'color', [0, 0, 0]);

xlim([data.scaleMinTss data.scaleMaxTss]);
ylim([data.scaleMinF data.scaleMaxF]);

title(['Lc-delta Lc, Selected traces ', num2str(indexSelected)]);
xlabel('Lc (nm)');
ylabel('Delta Lc (nm)');

subplot(2, 1, 2);
selectedDeltaLc = selected_lcDeltaLcROI(:, 2) * 1E9;
binSize = str2double(get(handles.editBinDeltaLc, 'string'));
edges = (min(selectedDeltaLc(:)) - 10 * binSize/2):binSize:(max(selectedDeltaLc(:) + 10 * binSize/2));
[n, xout] = hist(selectedDeltaLc(:), edges);

bar(xout, n, 1, 'BaseValue', 0, 'FaceColor', [0 0 0], 'EdgeColor', [1 1 1]);

% fit with gaussian
[sigma, mu, normFactor] = gaussfit(xout, n);
selectedXBin = min(xout(:)):0.1:max(xout(:));

% get gaussian function
gaussianFunction = (1 / (sqrt(2*pi) * sigma)) * exp(-((selectedXBin - mu).^2) / (2*(sigma^2)));
if(normFactor > 1.5 || normFactor < 0.5)
    gaussianFunction = gaussianFunction * normFactor;
end

hold on;
plot(selectedXBin, gaussianFunction, '--', 'color', [1 0 0], 'LineWidth', 2);

title(['Delta Lc histogram (std = ', num2str(sigma), ', mu = ', num2str(mu),')']);
xlabel('Delta Lc (nm)');
ylabel('p');

xlim([data.scaleMinF data.scaleMaxF]);
ylim([0, max(n(:))]);

