function plotWLCFit(selections, sizeMarker, flagFlip, persistenceLength,rgb)
% Plot WLCFit

% % get selections
% if(~isempty(selections))
%     selections = textscan(selections, '%s', 'delimiter', ',');
%     selections = selections{1};
%     selections = str2double(selections);
% else
%     return;
% end

% for each selection
spacing=10;
for ii = 1:1:length(selections)
    
    if ~isempty(rgb);
        color=rgb(ii,:);
        mark='none';
        line='-';
    else
        color=[0,0,0];
        mark='none';
        line='-';
    end

    % set tss
    tss = 0:0.1E-9:selections(ii) * 1E-9;
    
    % get F from Lc
    [Fc,tssc]=getFFromLc(selections(ii) * 1E-9, persistenceLength, tss);
    Fc = -Fc;
    if(flagFlip)
        Fc = -Fc;
    end

    % plot Fc
    
    if(~isempty(Fc))
        hold on;
        plot(tssc(1:spacing:end) * 1E9, Fc(1:spacing:end) * 1E12,...
            'Marker',mark,'markerSize', sizeMarker,...
            'LineStyle',line,'Linewidth',sizeMarker/2,'color',color);
    end
end
