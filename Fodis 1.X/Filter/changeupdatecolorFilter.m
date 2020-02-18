function changeupdatecolorFilter(handles,on)

if on
    color=[0.94,0.94,0.94];         %Update color
    set(handles.compute_filter,'BackgroundColor',[0.8,0.8,0.8])
else
    color=[0.925,0.812,0.812];   % Not update color  
    set(handles.compute_filter,'BackgroundColor',[1,0,0])
end

