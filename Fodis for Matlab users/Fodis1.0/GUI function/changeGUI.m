function changeGUI(handles,indexView)

%Enable or disable button in the GUI

if strcmp(indexView,'Traces') ||...
        strcmp(indexView,'Contour length (Lc, Fc)') ||...
        strcmp(indexView,'Contour length histogram') ||...
        strcmp(indexView,'Delta Lc histograms') ||...
        strcmp(indexView,'Contour length variance (Lc, Var(max(Lc)))')||...
        strcmp(indexView,'Traces-Lc')
    
    set(handles.menu_path_analysis,'Enable','off')
    
elseif strcmp(indexView,'Global contour length histogram') ||...
        strcmp(indexView,'Global contour length histogram max')||...
        strcmp(indexView,'Global peaks')
    % set button
    set(handles.pushbutton_updategrouping,'BackgroundColor',[0.8,0.8,0.8])
    set(handles.menu_path_analysis,'Enable','on')
end
if strcmp(indexView,'Global contour length histogram max')
    set(handles.buttonGaussianWindow, 'enable', 'on');
    set(handles.buttonRemoveWin, 'enable', 'on');
else
    set(handles.buttonGaussianWindow, 'enable', 'off');
    set(handles.buttonRemoveWin, 'enable', 'off');
end

if    strcmp(indexView,'Superimpose traces')||...
        strcmp(indexView,'Superimpose Lc')||...
        (strcmp(indexView,'Global delta Lc histograms') && ...
        (strcmp(get(handles.menuLcDeltaLc, 'checked') , 'on')))
    
    set(handles.checkboxDensityPlot,'Enable','on')
    set(handles.editDensityPlot,'Enable','on')
    
    if get(handles.checkboxDensityPlot,'Value')
        set(handles.checkboxDensityPlotPerPoints,'Enable','on')
        set(handles.editRatioReference,'Enable','on')
    end
else
    set(handles.checkboxDensityPlot,'Enable','off')
    set(handles.editDensityPlot,'Enable','off')
    set(handles.checkboxDensityPlotPerPoints,'Enable','off')
    set(handles.editRatioReference,'Enable','off')
end

if (strcmp(indexView,'Global delta Lc histograms'))
    set(handles.menuDeltaLcHistogram,'Enable','on');
    set(handles.menuDeltaLcFc,'Enable','on');
    set(handles.menuLcDeltaLc,'Enable','on');
else
    set(handles.menuDeltaLcHistogram,'Enable','off');
    set(handles.menuDeltaLcFc,'Enable','off');
    set(handles.menuLcDeltaLc,'Enable','off');
    set(handles.buttonSelectDeltaLc,'Enable','off');
    set(handles.buttonClearSelected,'Enable','off');
end


    
    

