function rangeFc(handles,data,selected_traces,selected_LcFcROI,sizeMarker,indexSelected)



% figure('Position',[100,100,400,300]);
% plot(selected_traces(:, 1) * 1E9, selected_traces(:, 2) * 1E12, '.', 'markerSize', sizeMarker, 'color', [1, 0, 0]);
% 
% xlim([data.scaleMinTss data.scaleMaxTss]);
% % ylim([0, max(lcDeltaLc(:, 2)) * 1E9]);
% 
% title(['Selected traces ', num2str(indexSelected)]);
% xlabel('tss (nm)');
% ylabel('F (pN)');

% plot histogram
figure('Position',[200,100,500,400]);
subplot(2, 1, 1);
plot(selected_LcFcROI(:, 1) * 1E9, selected_LcFcROI(:, 2) * 1E12, 'x', 'markerSize', sizeMarker, 'color', [0, 0, 0]);

xlim([data.scaleMinTss data.scaleMaxTss]);
ylim([data.scaleMinF data.scaleMaxF]);

title(['Lc-Force, Selected traces ', num2str(indexSelected)]);
xlabel('Lc (nm)');
ylabel('Force (pN)');

subplot(2, 1, 2);
selectedLcFc = selected_LcFcROI(:, 2) * 1E12;
binSize = str2double(get(handles.editBinDeltaLc, 'string'));
edges = (min(selectedLcFc(:)) - 10 * binSize/2):binSize:(max(selectedLcFc(:) + 10 * binSize/2));
[n, xout] = hist(selectedLcFc(:), edges);

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

title(['Force histogram (std = ', num2str(sigma), ', mu = ', num2str(mu),')']);
xlabel('Force (pN)');
ylabel('p');

xlim([data.scaleMinF data.scaleMaxF]);
ylim([0, max(n(:))]);

% plot Omega function (for heterogeneity) See Hinczewski et al.,Pnas, 2016 eq 3
figure('Position',[300,100,400,300]);

f=selected_LcFcROI(:, 2);
fmin=min(f);
fmax=max(f);

fbin= fmin: 6*(fmax-fmin)/length(f) :fmax;

for ii=1:length(fbin)
sigma(ii)=size( find(f>fbin(ii)), 1)/length(f);
end

%pulling velocity (m/s)
v=data.pullingspeed*1e-9;
%spring constant (N/m)
k=data.springk;

semilogy(fbin*1e12,-v*k*log(sigma)*1e12,'o');


title({['\Omega function (v=', num2str(v*1e9), ' nm/s, k=', num2str(k),'N/m)'];'(Hinczewski et al., PNAS, 2016)'});
xlabel('Force [pN]');
ylabel('\Omega r (F) [pN/s]');




