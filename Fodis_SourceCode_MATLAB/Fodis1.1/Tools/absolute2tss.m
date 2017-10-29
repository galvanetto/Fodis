function varargout = absolute2tss(varargin)
%Gui function to manually select regions in F-tss space where point of the
%races must fall into
%it uses brush command

% ABSOLUTE2TSS MATLAB code for absolute2tss.fig
%      ABSOLUTE2TSS, by itself, creates a new ABSOLUTE2TSS or raises the existing
%      singleton*.
%
%      H = ABSOLUTE2TSS returns the handle to a new ABSOLUTE2TSS or the handle to
%      the existing singleton*.
%
%      ABSOLUTE2TSS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ABSOLUTE2TSS.M with the given input arguments.
%
%      ABSOLUTE2TSS('Property','Value',...) creates a new ABSOLUTE2TSS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before absolute2tss_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to absolute2tss_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help absolute2tss

% Last Modified by GUIDE v2.5 26-Oct-2017 16:51:06

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @absolute2tss_OpeningFcn, ...
                   'gui_OutputFcn',  @absolute2tss_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end


function absolute2tss_OpeningFcn(hObject, eventdata, handles, varargin)
global positiveResult
global mainHandles

% Choose default command line output 
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%Gui Setting
nTraces=positiveResult.nTraces;
set(handles.slider_finger, 'Min', 1);
set(handles.slider_finger, 'Max', nTraces);

if nTraces > 1
    set(handles.slider_finger, 'SliderStep', [1/(nTraces-1) 1/(nTraces-1)]);
else
    set(handles.slider_finger, 'SliderStep', [0.5 0.5]);    
end

set(handles.slider_finger, 'Value', 1);

set(handles.textlimit_finger,'string',['/' num2str(positiveResult.nTraces)])


showTrace(handles)


function varargout = absolute2tss_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

function slider_finger_Callback(hObject, eventdata, handles)
global data
global positiveResult
global mainHandles
global nsel xsel ysel
global scores
global lags
global threshold


indexTrace = get(hObject, 'Value');
if(indexTrace < 1);indexTrace = 1;end
if(indexTrace > positiveResult.nTraces)
    indexTrace = positiveResult.nTraces;
end

set(handles.edit_finger, 'string', num2str(indexTrace));
showTrace(handles)

function slider_finger_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function edit_finger_Callback(hObject, eventdata, handles)
global positiveResult

indexTrace = round(str2double(get(hObject, 'String')));
if(indexTrace < 1);indexTrace = 1;end
if(indexTrace > positiveResult.nTraces)
    indexTrace = positiveResult.nTraces;
end

set(handles.slider_finger, 'value', indexTrace);
set(handles.edit_finger, 'string', num2str(indexTrace));
showTrace(handles)

function edit_finger_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




function showTrace(handles)
global data
global positiveResult
global mainHandles


indexTrace = round(get(handles.slider_finger, 'value'));  %Slider Position
indexeffTrace=positiveResult.indexTrace(indexTrace);       %Actual trace
%Load Translation
translateLc = data.translateLc(indexeffTrace);
flagFlip = get(mainHandles.checkboxFlipTraces, 'value');

% Get trace
[extendTipSampleSeparation,retractTipSampleSeparation,extendVDeflection,...
    retractVDeflection]= getTrace(indexeffTrace, data);

if flagFlip == 1;mirror=-1;else; mirror=1;end %flip the signal
% get tss-F
xdata = retractTipSampleSeparation; %+translateLc;   no translation
ydata = mirror*retractVDeflection;
    
axes(handles.axes_finger)
cla;
hold on;

%MIRROR
if get(handles.mirrorF, 'Value')
    ydata=-ydata;
end

%ROTATION
R = get(handles.rotation, 'Value');
if R==2
    xdatat=xdata;
    ydatat=ydata;
    xdata=ydatat;
    ydata=-xdatat;
elseif R==3
    xdata=-xdata;
    ydata=-ydata;
elseif R==4
    xdatat=xdata;
    ydatat=ydata;
    xdata=-ydatat;
    ydata=xdatat;
end


%CORRECTION FACTOR  x axis
if get(handles.ignoreconversion, 'Value')==0
    xdata=xdata * str2double(get(handles.editmultiplier, 'string'));
end


%SENSITIVITY Y axis
if get(handles.ignoreSens, 'Value')==0
    ydata=ydata * str2double(get(handles.sensitivity, 'string')) *1e-9;
end

%SPRING Y axis
if get(handles.ignoreSpring, 'Value')==0
    ydata=ydata * str2double(get(handles.spring, 'string'));
end

%BASELINE SUB
if get(handles.ignoreBaseline, 'Value')==0
    
    mx=min(xdata);
    Mx=max(xdata);
    my=min(ydata);
    My=max(ydata);

    xmin_Mx= mx + ( (Mx-mx) * 0.01 * str2double(get(handles.xmin, 'string')));
    xmax_Mx= mx + ( (Mx-mx) * 0.01 * str2double(get(handles.xmax, 'string')));
    
    %indeces of the interval
    xtoaver=find(xdata>xmin_Mx & xdata<xmax_Mx);
    
    %mean of the interval
    yto0=mean(ydata(xtoaver));
    
    %bring to zero the baseline
    ydata=ydata-yto0;
    
    if get(handles.ignoreContact, 'Value')==1
        %for plot of the patch only, recalculate the limits
        mx=min(xdata);
        Mx=max(xdata);
        my=min(ydata);
        My=max(ydata);
        
        xmin_Mx= mx + ( (Mx-mx) * 0.01 * str2double(get(handles.xmin, 'string')));
        xmax_Mx= mx + ( (Mx-mx) * 0.01 * str2double(get(handles.xmax, 'string')));
        
        patch([xmin_Mx xmin_Mx xmax_Mx xmax_Mx], 20*[My my my My] , 'red', 'FaceAlpha',.5);
    end
    
end

%CONTACT POINT
if get(handles.ignoreContact, 'Value')==0
    
    overzero=find(ydata>0);
    
    if ~isempty(overzero)
        zero=xdata(overzero(1));
    else
        zero=mean(xdata);
    end
    
    xdata=xdata-zero;
    
    if get(handles.ignoreBaseline, 'Value')==0
        %for plot of the patch only, recalculate the limits
        mx=min(xdata);
        Mx=max(xdata);
        my=min(ydata);
        My=max(ydata);
        
        xmin_Mx= mx + ( (Mx-mx) * 0.01 * str2double(get(handles.xmin, 'string')));
        xmax_Mx= mx + ( (Mx-mx) * 0.01 * str2double(get(handles.xmax, 'string')));
        
        patch([xmin_Mx xmin_Mx xmax_Mx xmax_Mx], 20*[My my my My] , 'red', 'FaceAlpha',.5);
    end
     
    
end

%TSS
if get(handles.ignoretss, 'Value')==0
    S = str2double(get(handles.sensitivity2, 'string'));
    
    xdata=xdata -(S * ydata);
end


%PLOT IN ABSOLUTE S.I. quantity
plot(xdata,ydata, 'b')
% set axis label
title(['Trace nr. ' num2str(indexTrace)])
xlim([min(xdata)-abs(0.2*min(xdata)) max(xdata)+0.2*max(xdata)]);   xlabel('Distance (m)');
ylim([min(ydata)-abs(0.2*min(ydata)) max(ydata)+0.2*max(ydata)]); ylabel('Deflection (V or m or N)');
grid on;

% plot(xdata*1e9,ydata*1e12, 'b')
% % set axis label
% title(['Trace nr. ' num2str(indexTrace)])
% xlim([min(xdata*1e9)-abs(0.1*min(xdata*1e9)) max(xdata*1e9)+0.1*max(xdata*1e9)]);   xlabel('Distance (nm)');
% ylim([min(ydata*1e12)-abs(0.1*min(ydata*1e12)) max(ydata*1e12)+0.1*max(ydata*1e12)]); ylabel('Deflection (V or nm or pN)');
set(gca,'FontSize',7)




function mirrorF_Callback(hObject, eventdata, handles)
showTrace(handles)


function rotation_Callback(hObject, eventdata, handles)
showTrace(handles)




function rotation_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




function transformAll_Callback(hObject, eventdata, handles)
global data
global positiveResult
global mainHandles



nTraces = positiveResult.nTraces;

hh = waitbar(0, 'Please wait...');

%New assignation
for kk=1:nTraces
    
    waitbar(kk/nTraces);
    
    indexTrace = kk; 
    indexeffTrace=positiveResult.indexTrace(indexTrace);       %Actual trace
    %Load Translation
 
    flagFlip = get(mainHandles.checkboxFlipTraces, 'value');
    
    % Get trace
    [extendTipSampleSeparation,retractTipSampleSeparation,extendVDeflection,...
        retractVDeflection]= getTrace(indexeffTrace, data);
    
    if flagFlip == 1;mirror=-1;else; mirror=1;end %flip the signal
    % get tss-F
    xdata = retractTipSampleSeparation; %+translateLc;   no translation
    ydata = mirror*retractVDeflection;
    
    
    %MIRROR
    if get(handles.mirrorF, 'Value')
        ydata=-ydata;
    end
    
    %ROTATION
    R = get(handles.rotation, 'Value');
    if R==2
        xdatat=xdata;
        ydatat=ydata;
        xdata=ydatat;
        ydata=-xdatat;
    elseif R==3
        xdata=-xdata;
        ydata=-ydata;
    elseif R==4
        xdatat=xdata;
        ydatat=ydata;
        xdata=-ydatat;
        ydata=xdatat;
    end
    
    %CORRECTION FACTOR  x axis
    if get(handles.ignoreconversion, 'Value')==0
        xdata=xdata * str2double(get(handles.editmultiplier, 'string'));
    end
    
    
    %SENSITIVITY Y axis
    if get(handles.ignoreSens, 'Value')==0
        ydata=ydata * str2double(get(handles.sensitivity, 'string')) *1e-9;
    end
    
    %SPRING Y axis
    if get(handles.ignoreSpring, 'Value')==0
        ydata=ydata * str2double(get(handles.spring, 'string'));
    end
    
    %BASELINE SUB
    if get(handles.ignoreBaseline, 'Value')==0
        
        mx=min(xdata);
        Mx=max(xdata);
        my=min(ydata);
        My=max(ydata);
        
        xmin_Mx= mx + ( (Mx-mx) * 0.01 * str2double(get(handles.xmin, 'string')));
        xmax_Mx= mx + ( (Mx-mx) * 0.01 * str2double(get(handles.xmax, 'string')));
        
        %indeces of the interval
        xtoaver=find(xdata>xmin_Mx & xdata<xmax_Mx);
        
        %mean of the interval
        yto0=mean(ydata(xtoaver));
        
        %bring to zero the baseline
        ydata=ydata-yto0;
    end
        
    %CONTACT POINT
    if get(handles.ignoreContact, 'Value')==0
        
        overzero=find(ydata>0);
        
        if ~isempty(overzero)
            zero=xdata(overzero(1));
        else
            zero=mean(xdata);
        end
        
        xdata=xdata-zero;
    end
    
    %TSS
    if get(handles.ignoretss, 'Value')==0
        S = str2double(get(handles.sensitivity2, 'string'));
        
        xdata=xdata -(S * ydata);
    end
    
    
    
    
    
    
    retractTipSampleSeparation = cell2mat(data.tracesRetract(indexTrace, 1));
    data.tracesRetract(indexTrace, 1) = mat2cell(xdata, 1 );
    data.tracesRetract(indexTrace, 2) = mat2cell(mirror*ydata, 1 );
    
    
    
    
end
 
data.tracesRetractBackup=data.tracesRetract;

delete(hh);

%Translation put to zero
data.translateLc=0*data.translateLc;

%FdW needs update (red color)
changeupdatecolor(mainHandles,0) 


%MUST RESET ALL FIELDS
set(handles.mirrorF, 'Value',0);
set(handles.rotation, 'Value',1);


showTrace(handles)



function ignoreSens_Callback(hObject, eventdata, handles)
showTrace(handles)



function sensitivity_Callback(hObject, eventdata, handles)
set(handles.sensitivity2,'string', str2double(get(handles.sensitivity, 'string')) );
showTrace(handles)



function sensitivity_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function spring_Callback(hObject, eventdata, handles)
showTrace(handles)

function spring_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function ignoreSpring_Callback(hObject, eventdata, handles)
showTrace(handles)


function xmin_Callback(hObject, eventdata, handles)
showTrace(handles)

function xmin_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function xmax_Callback(hObject, eventdata, handles)
showTrace(handles)

function xmax_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function ignoreBaseline_Callback(hObject, eventdata, handles)
showTrace(handles)


function ignoreContact_Callback(hObject, eventdata, handles)
showTrace(handles)

function ignoretss_Callback(hObject, eventdata, handles)
showTrace(handles)

function sensitivity2_Callback(hObject, eventdata, handles)
set(handles.sensitivity,'string', str2double(get(handles.sensitivity2, 'string')) );
showTrace(handles)

function sensitivity2_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function ignoreconversion_Callback(hObject, eventdata, handles)
showTrace(handles)


function editmultiplier_Callback(hObject, eventdata, handles)



function editmultiplier_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
