function changeupdatecolor(handles,on)

if on
    color=[0.94,0.94,0.94];         %Update color
    set(handles.update_settings,'BackgroundColor',[0.8,0.8,0.8])
else
    color=[0.925,0.812,0.812];   % Not update color  
    set(handles.update_settings,'BackgroundColor',[1,0,0])
    setappdata(handles.fig_FtW,'triggerLc',1);
end

    set(handles.uipanel6,'BackgroundColor',color)
    set(handles.text1,'BackgroundColor',color)
    set(handles.text2,'BackgroundColor',color)
    set(handles.text3,'BackgroundColor',color)
    set(handles.text4,'BackgroundColor',color)
    set(handles.text5,'BackgroundColor',color)
    set(handles.text6,'BackgroundColor',color)
    set(handles.text7,'BackgroundColor',color)
    set(handles.text8,'BackgroundColor',color)
    set(handles.text9,'BackgroundColor',color)
    set(handles.text10,'BackgroundColor',color)
    set(handles.text11,'BackgroundColor',color)
    set(handles.text12,'BackgroundColor',color)
    set(handles.text13,'BackgroundColor',color)
    set(handles.text14,'BackgroundColor',color)
    set(handles.text15,'BackgroundColor',color)
    set(handles.text16,'BackgroundColor',color)
    set(handles.text17,'BackgroundColor',color)
    set(handles.text18,'BackgroundColor',color)
    set(handles.text19,'BackgroundColor',color)
    set(handles.text20,'BackgroundColor',color)
    set(handles.text21,'BackgroundColor',color)
