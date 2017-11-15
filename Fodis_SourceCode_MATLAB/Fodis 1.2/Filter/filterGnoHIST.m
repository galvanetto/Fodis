function varargout = filterGnoHIST(varargin)
% FILTERGNOHIST MATLAB code for filterGnoHIST.fig
%      FILTERGNOHIST, by itself, creates a new FILTERGNOHIST or raises the existing
%      singleton*.
%
%      H = FILTERGNOHIST returns the handle to a new FILTERGNOHIST or the handle to
%      the existing singleton*.
%
%      FILTERGNOHIST('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FILTERGNOHIST.M with the given input arguments.
%
%      FILTERGNOHIST('Property','Value',...) creates a new FILTERGNOHIST or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before filterGnoHIST_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to filterGnoHIST_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help filterGnoHIST

% Last Modified by GUIDE v2.5 31-Aug-2017 12:26:35

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @filterGnoHIST_OpeningFcn, ...
                   'gui_OutputFcn',  @filterGnoHIST_OutputFcn, ...
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
% End initialization code - DO NOT EDIT


% --- Executes just before filterGnoHIST is made visible.
function filterGnoHIST_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to filterGnoHIST (see VARARGIN)
global data
global positiveResult
% Choose default command line output for automaticAlign
handles.output = hObject;
set(handles.slider_filterG, 'Value', 1);
set(handles.slider_filterG, 'Min', 1);
set(handles.slider_filterG, 'Max', positiveResult.nTraces);
set(handles.slider_filterG, 'SliderStep', [1 1]./(positiveResult.nTraces-1));

data.Filter.positive=zeros(1,data.nTraces);
data.Filter.positive(positiveResult.indexTrace)=1;

sortTraces(handles)
% Choose default command line output for filterGnoHIST
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);
% UIWAIT makes filterGnoHIST wait for user response (see UIRESUME)
waitfor(handles.figure_filter);


function varargout = filterGnoHIST_OutputFcn(hObject, eventdata, handles) 


function slider_filterG_Callback(hObject, eventdata, handles)
showTracesFilter(handles)
function slider_filterG_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function editLc0Range1_Callback(hObject, eventdata, handles)
showTracesFilter(handles)
changeupdatecolorFilter(handles,0)

function editLc0Range1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editLc1Range1_Callback(hObject, eventdata, handles)
showTracesFilter(handles)
changeupdatecolorFilter(handles,0)

function editLc1Range1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editLc0Range2_Callback(hObject, eventdata, handles)
showTracesFilter(handles)
changeupdatecolorFilter(handles,0)
function editLc0Range2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editLc1Range2_Callback(hObject, eventdata, handles)
showTracesFilter(handles)
changeupdatecolorFilter(handles,0)
function editLc1Range2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function pushbutton_drawROI_Callback(hObject, eventdata, handles)
global data

ax=handles.axes_filterG;
nrrect=size(data.Filter.rect,2);
h = imrect(ax);
position = wait(h);
data.Filter.rect{nrrect+1}=position;
showTracesFilter(handles)
changeupdatecolorFilter(handles,0)

function pushbutton_eraseROI_Callback(hObject, eventdata, handles)
global data

nrrect=size(data.Filter.rect,2);
if nrrect>=1
    data.Filter.rect(nrrect)=[];
    showTracesFilter(handles)
    changeupdatecolorFilter(handles,0)
end

% --- Executes on button press in pushbutton_drawROIex.
function pushbutton_drawROIex_Callback(hObject, eventdata, handles)
global data

ax=handles.axes_filterG;
nrrect=size(data.Filter.norect,2);
h = imrect(ax);
position = wait(h);
data.Filter.norect{nrrect+1}=position;
showTracesFilter(handles)
changeupdatecolorFilter(handles,0)


function pushbutton_eraseROIex_Callback(hObject, eventdata, handles)
global data

nrrect=size(data.Filter.norect,2);
if nrrect>=1
    data.Filter.norect(nrrect)=[];
    showTracesFilter(handles)
    changeupdatecolorFilter(handles,0)
end

function compute_filter_Callback(hObject, eventdata, handles)
sortTraces(handles)
changeupdatecolorFilter(handles,1)

function Update_traces_Callback(hObject, eventdata, handles)
global data
global positiveResult
global mainHandles

positiveResult.indexTrace=find(data.Filter.positive);
positiveResult.nTraces=length(positiveResult.indexTrace);

%FdW needs update (red color)
changeupdatecolor(mainHandles,0) 
close(handles.figure_filter) 


function sortTraces(handles)

global data
global positiveResult
global mainHandles

nTraces = positiveResult.nTraces;                          %Nr total traces
nrrect=size(data.Filter.rect,2);
nrrectno=size(data.Filter.norect,2);


% get Lc parameters
[tssMin, tssMax, FMin, FMax, xBin, binSize, ~, ~,...
    zerosTempMax, LcMin, LcMax, maxTssOverLc, xBinSizeMax, thresholdHist,...
    ~, ~, ~, ~, ~, persistenceLength] = getLcParameters(mainHandles);

%WaitBar
h = waitbar(0, 'Please wait');
set(h,'Name','Computing Filter')

for ii=1:nTraces
    
    indexeffTrace=positiveResult.indexTrace(ii);       %Actual trace

    
    [extendTipSampleSeparation, retractTipSampleSeparation, extendVDeflection,...
        retractVDeflection, ~]  = getTrace(indexeffTrace, data);
    translateLc = data.translateLc(indexeffTrace);
    
    % get tss F
    tss = retractTipSampleSeparation+translateLc;
    F = -retractVDeflection;
    


    for ll=1:nrrect
        pos=data.Filter.rect{ll};
        xv=[pos(1) pos(1)+pos(3) pos(1)+pos(3) pos(1)];
        yv=[pos(2) pos(2) pos(2)+pos(4) pos(2)+pos(4)];
        in = inpolygon(tss*1E9,F*1E12,xv,yv);
        if sum(in)==0
            data.Filter.positive(indexeffTrace)=0;
        end
    end
    for ll=1:nrrectno
        pos=data.Filter.norect{ll};
        xv=[pos(1) pos(1)+pos(3) pos(1)+pos(3) pos(1)];
        yv=[pos(2) pos(2) pos(2)+pos(4) pos(2)+pos(4)];
        in = inpolygon(tss*1E9,F*1E12,xv,yv);
        if ~(sum(in)==0)
            data.Filter.positive(indexeffTrace)=0;
        end
    end
    
     if(mod(ii, round(0.1 * nTraces)) == 0);waitbar(ii / nTraces);end
end

delete(h)

showTracesFilter(handles)



function showTracesFilter(handles)
global data
global positiveResult
global mainHandles

indexTrace = round(get(handles.slider_filterG, 'value'));    %Slider Position
indexeffTrace=positiveResult.indexTrace(indexTrace);       %Actual trace
flagFlip = get(mainHandles.checkboxFlipTraces, 'value');
nrrect=size(data.Filter.rect,2);
nrrectno=size(data.Filter.norect,2);

% get Lc parameters
[tssMin, tssMax, FMin, FMax, xBin, binSize, ~, ~,...
    zerosTempMax, LcMin, LcMax, maxTssOverLc, xBinSizeMax, thresholdHist,...
    ~, ~, ~, ~, ~, persistenceLength] = getLcParameters(mainHandles);

% Get trace
[~,retractTipSampleSeparation,~,...
    retractVDeflection]= getTrace(indexeffTrace, data);

if flagFlip == 1;mirror=-1;else mirror=1;end %flip the signale
translateLc = data.translateLc(indexeffTrace);


% get tss F
tss = retractTipSampleSeparation+translateLc;
F = mirror*retractVDeflection;


%% Plot1
%Plot trace and rect
axes(handles.axes_filterG)
cla;

plot(retractTipSampleSeparation*1E9,F*1E12,'k','linewidth',1.2);
hold on
for ii=1:nrrect
    pos=data.Filter.rect{ii};
    xv=[pos(1) pos(1)+pos(3) pos(1)+pos(3) pos(1)];
    yv=[pos(2) pos(2) pos(2)+pos(4) pos(2)+pos(4)];
    p=patch(xv,yv,'g');
    set(p,'FaceAlpha',0.3);
    in = inpolygon(tss*1E9,F*1E12,xv,yv) ;
    plot(tss(in)*1E9,F(in)*1E12,'g+','markersize',0.5)
end
for ii=1:nrrectno
    pos=data.Filter.norect{ii};
    xv=[pos(1) pos(1)+pos(3) pos(1)+pos(3) pos(1)];
    yv=[pos(2) pos(2) pos(2)+pos(4) pos(2)+pos(4)];
    p1=patch(xv,yv,'r');
    set(p1,'FaceAlpha',0.3);
    in = inpolygon(tss*1E9,F*1E12,xv,yv) ;
    plot(tss(in)*1E9,F(in)*1E12,'r+','markersize',0.5)
end
set(gca,'FontSize',7)

if data.Filter.positive(indexeffTrace)
    text(0,data.scaleMaxF-50,'Valid','Color','green')
else
    text(0,data.scaleMaxF-50,'Not Valid','Color','red')
end

% set axis label
title('Traces')
xlim([data.scaleMinTss data.scaleMaxTss]); xlabel('tss (nm)');
ylim([data.scaleMinF data.scaleMaxF]);     ylabel('F (pN)');


function figure_filter_CloseRequestFcn(hObject, eventdata, handles)

delete(hObject);


