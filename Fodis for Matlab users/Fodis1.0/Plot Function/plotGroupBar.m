function plotGroupBar(handles,intervals)

indexView = getIndexView(handles);
if strcmp(indexView,'Global peaks')
    stack='top';
else
    stack='bottom';
end
%Remove old patch
l=findobj('tag','groupcolor');
delete(l);


%Plot new patch
y=get(handles.axesMain,'YLim');
rgb=distinguishable_colors(size(intervals,1));
if ~isempty(intervals)
    for ii=1:size(intervals,1)
        xi=intervals(ii,:);
        h=patch('XData',[xi fliplr(xi)],'YData',[y(1) y(1) y(2) y(2)],'FaceColor',rgb(ii,:),'FaceAlpha',0.15,'EdgeColor','none');
        set(h,'tag','groupcolor')
        uistack(h,stack);
    end
end

function [indexView] = getIndexView(handles)
% Get indexView
indexView = get(handles.popupmenuView, 'value');
stringView = get(handles.popupmenuView, 'string');
indexView = stringView{indexView};