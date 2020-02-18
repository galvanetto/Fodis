function plotLcVL(LcTraces,sizeMarker,yax)

LcTraces=str2double(strsplit(LcTraces,',')); 
rgb=distinguishable_colors(length(LcTraces) + 1, [1 1 1; 0 0 0; 1 0 0; [0 1 0]]);
for ii=1:length(LcTraces)
      plot([LcTraces(ii),LcTraces(ii)],yax,':','Linewidth',sizeMarker/3,'color',rgb(ii,:));
end