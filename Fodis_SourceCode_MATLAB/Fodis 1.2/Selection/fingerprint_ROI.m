function varargout = fingerprint_ROI(varargin)
%Gui function to manually select regions in F-tss space where point of the
%races must fall into
%it uses brush command

% FINGERPRINT_ROI MATLAB code for fingerprint_ROI.fig
%      FINGERPRINT_ROI, by itself, creates a new FINGERPRINT_ROI or raises the existing
%      singleton*.
%
%      H = FINGERPRINT_ROI returns the handle to a new FINGERPRINT_ROI or the handle to
%      the existing singleton*.
%
%      FINGERPRINT_ROI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FINGERPRINT_ROI.M with the given input arguments.
%
%      FINGERPRINT_ROI('Property','Value',...) creates a new FINGERPRINT_ROI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before fingerprint_ROI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to fingerprint_ROI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help fingerprint_ROI

% Last Modified by GUIDE v2.5 20-Jun-2017 11:12:04

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @fingerprint_ROI_OpeningFcn, ...
                   'gui_OutputFcn',  @fingerprint_ROI_OutputFcn, ...
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


function fingerprint_ROI_OpeningFcn(hObject, eventdata, handles, varargin)
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
set(handles.slider_finger, 'SliderStep', [1/(nTraces-1) 1/(nTraces-1)]);
set(handles.slider_finger, 'Value', 1);

set(handles.textlimit_finger,'string',['/' num2str(positiveResult.nTraces)])


showTrace(handles)


function varargout = fingerprint_ROI_OutputFcn(hObject, eventdata, handles) 
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


function button_brush_Callback(hObject, eventdata, handles)

set(hObject,'BackgroundColor','white');

%variable containing the selected points forming the "roi"
global nsel xsel ysel

axes(handles.axes_finger)
hold on;
%selection tool: brush
[nsel_cell,xsel_cell,ysel_cell]=brush2;
if isempty(nsel)
    nsel=nsel_cell{2};  %2 because 2 is the number that automaically is asigned 
    xsel=xsel_cell{2};
    ysel=ysel_cell{2};
elseif (~isempty(nsel))
    nsel=[nsel; nsel_cell{3}]; 
    xsel=[xsel; xsel_cell{3}];
    ysel=[ysel; ysel_cell{3}];
end

set(hObject,'BackgroundColor',get(0,'DefaultUicontrolBackgroundColor'));

showTrace(handles)

function button_deletebrush_Callback(hObject, eventdata, handles)

global nsel xsel ysel
nsel=[];
xsel=[];
ysel=[];

showTrace(handles)

function edit_lag_finger_Callback(hObject, eventdata, handles)

function edit_lag_finger_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_threshold_finger_Callback(hObject, eventdata, handles)
plotScore(handles)

function edit_threshold_finger_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function button_computeSim_Callback(hObject, eventdata, handles)
global nsel xsel ysel
global data
global positiveResult
global mainHandles
global scores
global lags

nTraces = positiveResult.nTraces; 

%general score and lag for each trace an
scores=zeros(nTraces,1);
lags=zeros(nTraces,1);

h = waitbar(0, 'Please wait...');

%%%%%%%%%%%%%%set lag here
lag=round( str2double( get(handles.edit_lag_finger, 'string') ) );

for  ii=1:nTraces
    
    indexeffTrace=positiveResult.indexTrace(ii);       %Actual trace
    %Load Translation
    translateLc = data.translateLc(indexeffTrace);
    
    % Get trace
    [~,retractTipSampleSeparation,~,...
        retractVDeflection]= getTrace(indexeffTrace, data);
    
    flagFlip = get(mainHandles.checkboxFlipTraces, 'value');

    if flagFlip == 1;mirror=-1;else; mirror=1;end %flip the signale
    % get tss-F
    tss = retractTipSampleSeparation+translateLc;
    F = mirror*retractVDeflection;
    
    %transforms trace into a matrix  
    M=trace2matrix2(tss,F,data.scaleMaxTss,data.scaleMaxF);
    
    %we transform M into a column vector to be compared with nsel
    V=reshape(M,[],1);
    Vfind=find(V);
    
     
    lag_dim=lag*2+1;
    lag_partial=(-lag:lag);
    score_partial=zeros(lag_dim,1);
    
    for jj=-lag:lag
    %we find the superposition of the points
    Vfind_lag=Vfind + jj*data.scaleMaxF;
    intersection = intersect(nsel,Vfind_lag);
    score_partial(jj+lag+1) = size( intersection ,1);  
    end
    
    [max_score_partial, pos_max_score_partial] = max(score_partial);
    
    scores(ii)=max_score_partial;
    lags(ii)= lag_partial(pos_max_score_partial);
    
    waitbar(ii/nTraces);
    
end

delete(h);

plotScore(handles)

function button_update_finger_Callback(hObject, eventdata, handles)
global data
global positiveResult
global mainHandles
global nsel xsel ysel
global scores
global lags
global threshold

%positive result among current valid
positive_partial=find(scores>threshold);

%here positive among all traces
positiveResult.indexTrace=positiveResult.indexTrace(positive_partial);
positiveResult.nTraces=length(positiveResult.indexTrace);
nTraces = positiveResult.nTraces;

% %brute force translation (works only first time
% data.translateLc=data.translateLc+(lags*1e-9); 

%New translation
for kk=1:nTraces
    data.translateLc(positiveResult.indexTrace(kk))=data.translateLc(positiveResult.indexTrace(kk))+(lags(positive_partial(kk))*1e-9);   
end
 

%FdW needs update (red color)
changeupdatecolor(mainHandles,0) 


set(handles.textlimit_finger,'string',['/' num2str(positiveResult.nTraces)])
set(handles.slider_finger, 'value', 1);
set(handles.edit_finger, 'string', num2str(1));
set(handles.slider_finger, 'Max', nTraces);
set(handles.slider_finger, 'SliderStep', [1/(nTraces-1) 1/(nTraces-1)]);

showTrace(handles)

function showTrace(handles)
global data
global positiveResult
global mainHandles
global nsel xsel ysel

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
xdata = retractTipSampleSeparation+translateLc;
ydata = mirror*retractVDeflection;
    
axes(handles.axes_finger)
cla;
hold on;

%Plot grid for selection purposes
xg=1:data.scaleMaxTss;
yg=1:data.scaleMaxF;
[Xg,Yg]=meshgrid(xg,yg);
Xs=reshape(Xg,[],1);
Ys=reshape(Yg,[],1);
plot(Xs,Ys,'.w')
%%%
%plot selected points
plot(xsel,ysel,'.','MarkerSize',10, 'MarkerEdgeColor',[1,0.5,0.5]);


plot(xdata*1e9,ydata*1e12, 'b')
% set axis label
title(['Trace nr. ' num2str(indexTrace)])
xlim([0 data.scaleMaxTss]);   xlabel('tss (nm)');
ylim([0 data.scaleMaxF]); ylabel('F (pN)');
set(gca,'FontSize',7)

function plotScore(handles)
global nsel xsel ysel
global data
global positiveResult
global mainHandles
global scores
global lags
global threshold

nTraces = positiveResult.nTraces; 

figure;
hold on;
threshold=round( str2double( get(handles.edit_threshold_finger, 'string') ) );
plot(scores,'*');
plot([0 nTraces],[threshold threshold]);
title('Scores')
xlabel('Trace number');
ylim([0 max(scores)]); ylabel('Score');
hold off;
