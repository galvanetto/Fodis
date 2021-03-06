function varargout = Fodis(varargin)
%Fodis M-file for Fodis.fig
%      Fodis, by itself, creates a new Fodis or raises the existing
%      singleton*.
%
%      H = Fodis returns the handle to a new Fodis or the handle to
%      the existing singleton*.
%
%      Fodis('Property','Value',...) creates a new Fodis using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to Fodis_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      Fodis('CALLBACK') and Fodis('CALLBACK',hObject,...) call the
%      local function named CALLBACK in Fodis.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Fodis

% Last Modified by GUIDE v2.5 13-Jun-2019 13:00:18

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Fodis_OpeningFcn, ...
                   'gui_OutputFcn',  @Fodis_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
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


% --- Executes just before Fodis is made visible.
function Fodis_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for Fodis
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
addpath(genpath('/home/aperissinotto/Documents/SISSA/Galva/Fodis'))
rmpath(genpath('/home/aperissinotto/Documents/SISSA/Galva/Fodis/Tracce prova'));
% UIWAIT makes Fodis wait for user response (see UIRESUME)
% uiwait(handles.fig_FtW);

                                         
    
%Define global variable for fingerprint_ROI (ROI points)
global nsel xsel ysel
nsel=[];
xsel=[];
ysel=[];

global data

data.folder=[];
data.basicFolder=[];
%spring const and pulling speed (nm/s)
data.springk=0.084;
data.pullingspeed=1000;
data.LcFcROI=[];

init(handles);

function init(handles)
% initialize GUI

global data

% clear data
data.tracesExtend = {};
data.tracesRetract = {};
data.tracesExtendBackup={};
data.tracesRetractBackup={};
data.nTraces = 0;
data.translateLc = [];
data.selectedTraces = [];
data.removeTraces = [];
data.removeTracesbackup=[];
data.saveOnScreen = [];
data.sessionFileName = '';
data.fileNames = {};
data.listLc={};
data.listFc={};
data.SGFilter=[];
data.position=[];

% clear temp data
setappdata(handles.axesMain, 'selectedLcDeltaLc', []);

axes(handles.axesMain);
cla;

% --- Outputs from this function are returned to the command line.
function varargout = Fodis_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function sliderTraces_Callback(hObject, eventdata, handles)
global positiveResult

% check value
indexTrace = round(get(hObject, 'Value'));
if(indexTrace < 1);indexTrace = 1;end
if(indexTrace > positiveResult.nTraces)
    indexTrace = positiveResult.nTraces;
end

% set value
set(handles.sliderTraces, 'value', indexTrace);
showTraces(handles);

function sliderTraces_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function editFrame_Callback(hObject, eventdata, handles)
global positiveResult

% check value
indexTrace = round(str2double(get(hObject, 'String')));
if(indexTrace < 1);indexTrace = 1;end
if(indexTrace > positiveResult.nTraces)
    indexTrace = positiveResult.nTraces;
end

% set value
set(handles.sliderTraces, 'value', indexTrace);
showTraces(handles);

function editFrame_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function buttonRuler_Callback(hObject, eventdata, handles)%#ok<DEFNU>
axes(handles.axesMain);
% draw a line
hnd = imline;
wait(hnd);
% get position
pos = hnd.getPosition();
set(handles.editRuler, 'string', num2str(abs(pos(1, 1) - pos(2, 1))));
delete(hnd);

function editRuler_Callback(hObject, eventdata, handles)  %#ok<DEFNU>
function editRuler_CreateFcn(hObject, ~, ~)               %#ok<DEFNU>

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function buttonGaussianWindow_Callback(hObject, eventdata, handles)

global data

%draw a line
axes(handles.axesMain);
hndLine = imline;
wait(hndLine);

%get position
pos = hndLine.getPosition;
pos=pos(:,1);
if(pos(1, 1) > pos(2, 1))
   pos=flipud(pos);
end

%set gaussian window
indexGaussian = length(data.gaussianWindow) + 1;
data.gaussianWindow(indexGaussian).start = pos(1, 1) * 1E-9;
data.gaussianWindow(indexGaussian).end = pos(2, 1) * 1E-9;

%delete line
delete(hndLine);

h=get(handles.axesMain,'Children');
hst=findobj(h,'tag','histmax');

%Plot histogram
binSize = str2double(get(handles.editBinSize, 'string')) * 1E-9;
LcMin = 0;
LcMax = str2double(get(handles.editLcMax, 'string')) * 1E-9;
xBin = (LcMin + (binSize/2)):binSize:LcMax;

plotGaussian(xBin, hst.YData);

function buttonRemoveWin_Callback(hObject, eventdata, handles)
global data

gaussianWindow=data.gaussianWindow;
if isempty(gaussianWindow);return;end

%draw a line
axes(handles.axesMain);
hndLine = imline;
wait(hndLine);

%get position
pos = hndLine.getPosition;
pos=pos(:,1)* 1E-9;
if(pos(1, 1) > pos(2, 1))
   pos=flipud(pos);
end
%find nearest curve
startend = struct2cell(data.gaussianWindow);
matstend=squeeze(cell2mat(startend));
dist=(matstend(1,:)-pos(1)).^2+(matstend(2,:)-pos(2)).^2;
[~,index]=min(dist);

data.gaussianWindow(index)=[];
%delete line
delete(hndLine);

h=get(handles.axesMain,'Children');
hst=findobj(h,'tag','histmax');

%Plot histogram
binSize = str2double(get(handles.editBinSize, 'string')) * 1E-9;
LcMin = 0;
LcMax = str2double(get(handles.editLcMax, 'string')) * 1E-9;
xBin = (LcMin + (binSize/2)):binSize:LcMax;
%Delete old gaussian and plot the new
hst2=findobj(h,'type','text');
hst3=findobj(h,'type','area');
hst4=findobj(h,'type','line');
hst5=findobj(h,'tag','colorhist');
delete(hst2);
delete(hst3);
delete(hst4);
delete(hst5);

plotGaussian(xBin, hst.YData);


function buttonSelectDeltaLc_Callback(~, ~, handles)

% create imreact
axes(handles.axesMain);
hndRect = imrect;
wait(hndRect);

% get position
pos = hndRect.getPosition();
xMin = pos(1);
yMin = pos(2);
width = pos(3);
height = pos(4);

% set range on x
LcMin = xMin * 1E-9;
LcMax = (xMin + width) * 1E-9;
% set range on y
DeltaLcMin = yMin * 1E-9;
DeltaLcMax = (yMin + height) * 1E-9;

% delete react
delete(hndRect);

% save data
setappdata(handles.fig_FtW, 'selectedLcDeltaLc', [LcMin, LcMax, DeltaLcMin, DeltaLcMax]);
showTraces(handles);


function buttonClearSelected_Callback(~, ~, handles)
% clear temp data
setappdata(handles.fig_FtW, 'selectedLcDeltaLc', []);
showTraces(handles);

function buttonselectLcFc_Callback(hObject, eventdata, handles)
% create imreact
axes(handles.axesMain);
hndRect = imrect;
wait(hndRect);

% get position
pos = hndRect.getPosition();
xMin = pos(1);
yMin = pos(2);
width = pos(3);
height = pos(4);

% set range on x
LcMin = xMin * 1E-9;
LcMax = (xMin + width) * 1E-9;
% set range on y
FMin = yMin * 1E-12;
FMax = (yMin + height) * 1E-12;

% delete react
delete(hndRect);

% save data
setappdata(handles.fig_FtW, 'selectedLcFc', [LcMin, LcMax, FMin, FMax]);
showTraces(handles);



function buttondeleteLcFc_Callback(hObject, eventdata, handles)
% clear temp data
setappdata(handles.fig_FtW, 'selectedLcFc', []);
showTraces(handles);

function checkboxDensityPlot_Callback(hObject, eventdata, handles)
on=get(hObject,'Value');
if on
set(handles.checkboxDensityPlotPerPoints,'Enable','on') 
set(handles.editRatioReference,'Enable','on') 
else
set(handles.checkboxDensityPlotPerPoints,'Enable','off') 
set(handles.editRatioReference,'Enable','of') 
end
 showTraces(handles)


function editDensityPlot_Callback(hObject, eventdata, handles) %#ok<DEFNU>
showTraces(handles)
 
function editDensityPlot_CreateFcn(hObject, eventdata, handles) %#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function checkboxDensityPlotPerPoints_Callback(hObject, eventdata, handles) %#ok<DEFNU>
showTraces(handles)


function editRatioReference_Callback(hObject, eventdata, handles) %#ok<DEFNU>
showTraces(handles)

function editRatioReference_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%% Lc Parameters

function editFMin_Callback(~,~,handles)%#ok<DEFNU>
changeupdatecolor(handles,0)

function editFMin_CreateFcn(hObject, ~, ~)%#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editFMax_Callback(~, ~, handles)%#ok<DEFNU>
changeupdatecolor(handles,0)

function editFMax_CreateFcn(hObject, ~, ~)%#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editBinSize_Callback(~, ~, handles)%#ok<DEFNU>
changeupdatecolor(handles,0)

function editBinSize_CreateFcn(hObject, ~, ~)%#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editBinSizeFcMax_Callback(~, ~, handles)%#ok<DEFNU>
changeupdatecolor(handles,0)

function editBinSizeFcMax_CreateFcn(hObject, ~, ~)%#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editTssMax_Callback(~, ~, handles)%#ok<DEFNU>
changeupdatecolor(handles,0)

function editTssMax_CreateFcn(hObject, ~, ~)%#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editBinDeltaLc_Callback(~, ~, handles)%#ok<DEFNU>
changeupdatecolor(handles,0)

function editBinDeltaLc_CreateFcn(hObject, ~, ~)%#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editStartLcDeltaLc_Callback(~, ~, handles)%#ok<DEFNU>
changeupdatecolor(handles,0)

function editStartLcDeltaLc_CreateFcn(hObject, ~, ~)%#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editMinP_Callback(~, ~, handles)%#ok<DEFNU>
changeupdatecolor(handles,0)

function editMinP_CreateFcn(hObject, ~, ~)%#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editMaxP_Callback(~, ~, handles)%#ok<DEFNU>
changeupdatecolor(handles,0)

function editMaxP_CreateFcn(hObject, ~, ~)%#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editBinP_Callback(~, ~, handles)%#ok<DEFNU>
changeupdatecolor(handles,0)

function editBinP_CreateFcn(hObject, ~, ~)%#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
%% Column2

function editRatio_Callback(~, ~, handles)%#ok<DEFNU>
changeupdatecolor(handles,0)

function editRatio_CreateFcn(hObject, ~, ~)%#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editBinSizeMax_Callback(~, ~, handles)%#ok<DEFNU>
changeupdatecolor(handles,0)

function editBinSizeMax_CreateFcn(hObject, ~, ~)%#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editThresholdNPoints_Callback(~, ~, handles)%#ok<DEFNU>
changeupdatecolor(handles,0)

function editThresholdNPoints_CreateFcn(hObject, ~, ~)%#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function ediMaxDiffForce_Callback(~, ~, handles)%#ok<DEFNU>
changeupdatecolor(handles,0)

function ediMaxDiffForce_CreateFcn(hObject, ~, ~)%#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editLcMax_Callback(~, ~, handles)%#ok<DEFNU>
changeupdatecolor(handles,0)

function editLcMax_CreateFcn(hObject, ~, ~)%#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editMinDeltaLc_Callback(~, ~, handles)%#ok<DEFNU>
changeupdatecolor(handles,0)

function editMinDeltaLc_CreateFcn(hObject, ~, ~)%#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editMaxDeltaLc_Callback(~, ~, handles)%#ok<DEFNU>
changeupdatecolor(handles,0)

function editMaxDeltaLc_CreateFcn(hObject, ~, ~)%#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editPersistenceLength_Callback(~, ~, handles)%#ok<DEFNU>
changeupdatecolor(handles,0)

function editPersistenceLength_CreateFcn(hObject, ~, ~)%#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editBinHistP_Callback(~, ~, handles)%#ok<DEFNU>
changeupdatecolor(handles,0)

function editBinHistP_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editBinFit_Callback(~, ~, handles) %#ok<DEFNU>
changeupdatecolor(handles,0)

function editBinFit_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% End Lc Parameters

function checkboxRemove_Callback(hObject, eventdata, handles)

global data
global positiveResult

on=get(handles.checkboxRemove, 'value');
% remove trace
indexTrace = round(get(handles.sliderTraces, 'value'));
indexeffTrace=positiveResult.indexTrace(indexTrace);       %Actual trace

data.removeTraces(indexeffTrace)=on;
data.TracesGroup(indexeffTrace)=~on;
showTraces(handles)

function editSelectedTraces_Callback(hObject, eventdata, handles) %#ok<DEFNU>

global data
global positiveResult

% check flags
nTraces = positiveResult.nTraces;
if(nTraces == 0);menuMarkAllValid_Callback(hObject, eventdata, handles);end
nTraces = positiveResult.nTraces;
if(nTraces <= 0);return;end

% get selections
selections = get(handles.editSelectedTraces, 'string');
if isempty(selections)
   data.removeTraces(positiveResult.indexTrace) = 1;  
   data.TracesGroup(positiveResult.indexTrace)=0;
   showTraces(handles);
   return
end

selections = textscan(selections, '%s', 'delimiter', ',');
selections = str2double(selections{1});


alltraces= 1:1:nTraces;
logsel=ismember(alltraces,selections);
logseleffok=positiveResult.indexTrace(logsel);
logseleffrem=positiveResult.indexTrace(~logsel);

data.removeTraces(logseleffok) = 0;  
data.removeTraces(logseleffrem) = 1;  
data.TracesGroup(logseleffok)=1;
data.TracesGroup(logseleffrem)=0;

showTraces(handles);

function editSelectedTraces_CreateFcn(hObject, eventdata, handles) %#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editOffset_Callback(hObject, eventdata, handles)

global data;

% set offset
newOffset = str2double(get(handles.editOffset, 'string'));
offset = newOffset - data.offset;
data.offset = newOffset;

% update offset
for ii = 1:1:length(data.translateLc)  
    data.translateLc(ii) = data.translateLc(ii) + offset * 1E-9;
end

%FdW needs update (red color)
changeupdatecolor(handles,0)

function editOffset_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function NrIntGroup_Callback(hObject, eventdata, handles) %#ok<DEFNU>

global data

grpintall=[];
grpstrn=get(hObject,'String');

if isempty(grpstrn) %check is not empty
    data.intervals=[];
    %Plot division bar for group
    plotGroupBar(handles,data.intervals)
    %plot update groups in red
    set(handles.pushbutton_updategrouping,'BackgroundColor',[1,0,0])
    return
end
grpstrngrp = textscan(grpstrn, '%s', 'delimiter', ',');
if isnan(str2double(grpstrngrp{1}))  % multiple value
    for jj=1:length(grpstrngrp{1})
        %Devide the range up and down limit
        grpintstr=textscan(grpstrngrp{1}{jj,1}, '%s', 'delimiter', '-');
        grpint=round(str2double(grpintstr{1}))';
        %Convert in double and save alltoghetr
        grpintall=cat(1,grpintall,grpint);
    end
else  %Single number
    nrIntGrp=str2double(grpstrn)+1;
    grpint=linspace(data.scaleMinTss,data.scaleMaxTss,nrIntGrp);
    grpintall=[(grpint(1:end-1)+0.01)',grpint(2:end)'];
end

if any(grpintall(1:(end-1),2)>grpintall(2:end,1)) ||...
        any(grpintall(:,2)<=grpintall(:,1))
    h=warndlg('Ranges must not intersect and with a length different than zero');
    uiwait(h)
    data.intervals=[];
    set(hObject,'String','')
    showTraces(handles);
    return;
end

data.intervals=grpintall;
%Plot division bar for group
plotGroupBar(handles,data.intervals)
%plot update groups in red
set(handles.pushbutton_updategrouping,'BackgroundColor',[1,0,0])

    
function NrIntGroup_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editGroups_Callback(hObject, eventdata, handles)
global data
global positiveResult
value=round(str2double(get(hObject,'String')));
indexTrace = round(get(handles.sliderTraces, 'value'));    %Slider Value
indexeffTrace=positiveResult.indexTrace(indexTrace);       %Actual trace
data.TracesGroup(indexeffTrace)=value;

if value==0;data.removeTraces(indexeffTrace)=1;
else data.removeTraces(indexeffTrace)=0;end

strnggrp=unique(nonzeros(data.TracesGroup));
strnggrp=sprintf('%.0f\n', strnggrp);
strnggrp=strnggrp(1:end-1);
set(handles.popupmenu_group,'string',strnggrp)

popupmenu_group_Callback(handles.popupmenu_group, eventdata, handles)
showTraces(handles)

function editGroups_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function checkbox_group_Callback(hObject, eventdata, handles)
global data

on=get(hObject,'Value');
strnggrp=unique(nonzeros(data.TracesGroup));
strnggrp=sprintf('%.0f\n', strnggrp);
strnggrp=strnggrp(1:end-1);

if on
    
    set(handles.popupmenu_group,'enable','on')
    set(handles.checkboxRemove,'enable','off')
    set(handles.editSelectedTraces,'enable','off')
    set(handles.NrIntGroup,'enable','off')
    set(handles.editGroups,'enable','off')
    set(handles.pushbutton_updategrouping,'enable','off')
    set(handles.popupmenu_group,'value',1)
    set(handles.popupmenu_group,'string',strnggrp)
    
%     pushbutton_updategrouping_Callback(handles.pushbutton_updategrouping,eventdata,handles)

    data.removeTracesbackup=data.removeTraces;
    popupmenu_group_Callback(handles.popupmenu_group,eventdata,handles)

else
    set(handles.popupmenu_group,'enable','off')
    set(handles.checkboxRemove,'enable','on')
    set(handles.editSelectedTraces,'enable','on')
    set(handles.NrIntGroup,'enable','on')
    set(handles.editGroups,'enable','on')
    set(handles.pushbutton_updategrouping,'enable','on')
    data.removeTraces=data.removeTracesbackup;
    showTraces(handles)
end

function popupmenu_group_Callback(hObject, eventdata, handles)
global data

indexView = get(hObject,'value');
stringView = get(hObject,'string');
if indexView>length(stringView);indexView=length(stringView);
elseif indexView<1;indexView=1;end
nrgroup = str2double(stringView(indexView,:));

grouptrace=data.TracesGroup==nrgroup;
data.removeTraces(grouptrace) = 0;  
data.removeTraces(~grouptrace)=1;
showTraces(handles)

function popupmenu_group_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pushbutton_updategrouping_Callback(hObject, eventdata, handles)

global data
global positiveResult

set(handles.popupmenuView,'value',12)
showTraces(handles)

indexTrace = round(get(handles.sliderTraces, 'value'));       %Slider Value 
indexeffTrace=positiveResult.indexTrace(indexTrace);          %Actual trace

if size(data.GMreduced,2)==0;warndlg('Select a Path Intervlal');return;end
TracesGroup=zeros(size(data.GMreduced,1),1);
%Traces Group
gpU=rows2DifferentSingleElements(data.GMreduced);
UniqueU=unique(data.GMreduced,'rows');
GPuniqueU=rows2DifferentSingleElements(UniqueU);

for kk=1:size(GPuniqueU,1)
    sequenza=find(gpU==GPuniqueU(kk));    
    C{kk}=sequenza;
end
for mm=1:length(C)
    list=C{mm};
    TracesGroup(list)=mm;
end

Selected=find(~data.removeTraces);
SelinValid=ismember(find(~data.removeTraces),positiveResult.indexTrace);
data.TracesGroup=zeros(length(positiveResult.indexTrace),1);
data.TracesGroup(Selected(SelinValid))=TracesGroup;
set(handles.editGroups,'String',num2str(data.TracesGroup(indexeffTrace)));


function editTraceMaxTss_Callback(hObject, eventdata, handles)
editTraceMinTss_Callback(hObject, eventdata, handles)
function editTraceMaxTss_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editTraceMinTss_Callback(hObject, eventdata, handles)
global data
data.scaleMinTss = str2double(get(handles.editTraceMinTss, 'string'));
data.scaleMaxTss = str2double(get(handles.editTraceMaxTss, 'string'));
set(handles.axesMain,'xlim',[data.scaleMinTss, data.scaleMaxTss])

function editTraceMinTss_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editTraceMinF_Callback(hObject, eventdata, handles)
editTraceMaxF_Callback(hObject, eventdata, handles)


function editTraceMinF_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editTraceMaxF_Callback(hObject, eventdata, handles)
global data
data.scaleMaxF = str2double(get(handles.editTraceMaxF, 'string'));
data.scaleMinF = str2double(get(handles.editTraceMinF, 'string'));
set(handles.axesMain,'ylim',[data.scaleMinF, data.scaleMaxF])

function editTraceMaxF_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function update_settings_Callback(hObject, eventdata, handles)
showTraces(handles)

function checkboxFlipTraces_Callback(hObject, eventdata, handles)
showTraces(handles);

function checkboxGrid_Callback(hObject, eventdata, handles)

on=get(hObject,'value');
h = findobj(handles.fig_FtW,'type','axis');
if on;grid on;else grid off;end


function editSizeMarker_Callback(hObject, eventdata, handles)
showTraces(handles)

function editSizeMarker_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editLcTraces_Callback(hObject, eventdata, handles)
showTraces(handles)

function editLcTraces_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function EditLcSaved_Callback(hObject, eventdata, handles)

global data
global positiveResult

indexTrace = round(get(handles.sliderTraces, 'value'));    %Slider Value
indexeffTrace=positiveResult.indexTrace(indexTrace);       %Actual trace

oldselectionLc=round(data.listLc{indexeffTrace});
oldselectionFc=data.listFc{indexeffTrace};

newselectionLc=get(hObject,'string');

% get selections
if ~isempty(newselectionLc)
newselectionLc = textscan(newselectionLc, '%s', 'delimiter', ',');
newselectionLc = round(str2double(newselectionLc{1}))';
else
data.listLc{indexeffTrace}=[];
data.listFc{indexeffTrace}=[];
showTraces(handles);
return
end

ordold=ismember(oldselectionLc,newselectionLc);
ordnew=ismember(newselectionLc,oldselectionLc);
Lciter=oldselectionLc(ordold);
Fciter=oldselectionFc(ordold);

Lcnew=cat(2,Lciter,newselectionLc(~ordnew));
Fcnew=cat(2,Fciter,repmat(50E-12,1,length(newselectionLc(~ordnew))));

[data.listLc{indexeffTrace},I]=sort(Lcnew,'ascend');
data.listFc{indexeffTrace}=Fcnew(I);
setappdata(handles.fig_FtW,'triggerLc2',1)

showTraces(handles)

function EditLcSaved_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function popupmenuView_Callback(hObject, eventdata, handles)
showTraces(handles);

function popupmenuView_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function SGL_fil_Callback(hObject, eventdata, handles)
global data
global positiveResult

on=get(hObject,'Value');
k=str2double(get(handles.SG_k,'String'));
f=str2double(get(handles.SG_f,'String'));
 
nTraces = positiveResult.nTraces;                          %Nr total traces
indexTrace = min( round(get(handles.sliderTraces, 'value')), nTraces);    %Slider Position
indexeffTrace=positiveResult.indexTrace(indexTrace);       %Actual trace

if on
    if k>=f; warndlg('k must be < f'); set(hObject,'value',0);return
    elseif mod(f,2)==0; warndlg('f must be odd');set(hObject,'value',0); return
    else   
        data.SGFilter(indexeffTrace,1)=1;
        data.tracesRetract{indexeffTrace,2}=sgolayfilt(data.tracesRetractBackup{indexeffTrace, 2},k,f);       
    end
else
    data.SGFilter(indexeffTrace,1)=0;
    data.tracesRetract{indexeffTrace,2}=data.tracesRetractBackup{indexeffTrace, 2};
end

changeupdatecolor(handles,0)

function update_smooth_Callback(hObject, eventdata, handles)
global data
global positiveResult

on=get(handles.SGL_fil,'Value');
k=str2double(get(handles.SG_k,'String'));
f=str2double(get(handles.SG_f,'String'));
 
Selected=find(~data.removeTraces);
SelinValid=ismember(find(~data.removeTraces),positiveResult.indexTrace);
Selected=Selected(SelinValid);

if on
    if k>=f; warndlg('k must be < f'); set(hObject,'value',0);return
    elseif mod(f,2)==0; warndlg('f must be odd');set(hObject,'value',0); return
    else   
        data.SGFilter(Selected,1)=1;

        for ii=1:length(Selected)
            
            data.tracesRetract{Selected(ii),2}=sgolayfilt(data.tracesRetractBackup{Selected(ii), 2},k,f);    
        
        end
    end
else
    
    data.SGFilter(Selected,1)=0; 
    for ii=1:length(Selected)
        data.tracesRetract{Selected(ii),2}=data.tracesRetractBackup{Selected(ii), 2};
    end    
end

changeupdatecolor(handles,0)


function SG_k_Callback(hObject, eventdata, handles)
SGL_fil_Callback(handles.SGL_fil, eventdata, handles)

function SG_k_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function SG_f_Callback(hObject, eventdata, handles)
SGL_fil_Callback(handles.SGL_fil, eventdata, handles)

function SG_f_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function menu_FilterTraces_Callback(hObject, eventdata, handles)

global data
global positiveResult
global mainHandles

mainHandles=handles;

filterG;


set(handles.sliderTraces, 'value',1)
showTraces(handles);


function menu_FilterTraces_noHIST_Callback(hObject, eventdata, handles)
global data
global positiveResult
global mainHandles

mainHandles=handles;

filterGnoHIST;


set(handles.sliderTraces, 'value',1)
showTraces(handles);


function menu_zero_align_Callback(hObject, eventdata, handles)

global data

nTraces=data.nTraces;

try

for ii = 1:1:nTraces
    
    data.translateLc(ii);
    
    [~,retractTipSampleSeparation,...
        ~,retractVDeflection,~]= getTrace(ii, data);
    
    % get tss F
    tss = retractTipSampleSeparation;
    F = -retractVDeflection;
    
    % Reference to align to zero
    x1=tss;
    F1=F;
    x1 = x1((F1<(-50*1e-12) & F1>(-500*1e-12)));                   %condition
    
    
    if isempty(x1)
        overzero=find(F1>0);
        
        if isempty(overzero)
            zero=mean(tss);                        %if no zero is found, zero is the average value
        else
            zero=tss(overzero(1));                 %zero to first positive value
        end
                
    else 
        zero=mean(x1);                             %ideal zero
    end

    data.tracesRetract{ii,1}=data.tracesRetract{ii,1}-zero;
end

catch ME
    
    disp(ME);
    
    d = dialog('Position',[300 300 400 200],'Name','Error when Importing Traces');

    txt = uicontrol('Parent',d,...
               'Style','text',...
               'Position',[20 80 360 100],...
               'String','The Alingment is not working, maybe your data cannot be aligned this way. Please check the User Guide or go to  https://github.com/nicolagalvanetto/Fodis/issues');

    btn = uicontrol('Parent',d,...
               'Position',[150 20 70 25],...
               'String','Close',...
               'Callback','delete(gcf)');
    
    beep
    
end

data.translateLc=zeros(data.nTraces,1);
showTraces(handles);


function menu_negpos_align_Callback(hObject, eventdata, handles)

global data

nTraces=data.nTraces;

try

for ii = 1:1:nTraces
    
    data.translateLc(ii);
    
    [~,retractTipSampleSeparation,...
        ~,retractVDeflection,~]= getTrace(ii, data);
    
    % get tss F
    tss = retractTipSampleSeparation;
    F = -retractVDeflection;
    
    % Reference to align to zero
    x1=tss;
    F1=F;
    
    overzero=find(F1>0);
    
    if isempty(overzero)
        zero=mean(tss);                        %if no zero is found, zero is the average value
    else
        zero=tss(overzero(1));                 %zero to first positive value
    end
    
    data.tracesRetract{ii,1}=data.tracesRetract{ii,1}-zero;
end

catch ME
    
    disp(ME);
    
    d = dialog('Position',[300 300 400 200],'Name','Error when Importing Traces');

    txt = uicontrol('Parent',d,...
               'Style','text',...
               'Position',[20 80 360 100],...
               'String','The Alingment is not working, maybe your data cannot be aligned this way. Please check the User Guide or go to  https://github.com/nicolagalvanetto/Fodis/issues');

    btn = uicontrol('Parent',d,...
               'Position',[150 20 70 25],...
               'String','Close',...
               'Callback','delete(gcf)');
    
    beep
    delete(h);
end


data.translateLc=zeros(data.nTraces,1);
showTraces(handles);

function menu_align_max_Callback(hObject, eventdata, handles)
%make the minimum F value to zero

global data

nTraces=data.nTraces;

try

for ii = 1:1:nTraces
    
    data.translateLc(ii);
    
    [~,retractTipSampleSeparation,...
        ~,retractVDeflection,~]= getTrace(ii, data);
    
    % get tss F
    tss = retractTipSampleSeparation;
    F = -retractVDeflection;
    
    % Reference to align to zero
    x1=tss;
    F1=F;
    
    
    
    [~, ImaxF]=max(F1);
    
    zero=tss(ImaxF); 
        
    data.tracesRetract{ii,1}=data.tracesRetract{ii,1}-zero;
end

catch ME
    
    disp(ME);
    
    d = dialog('Position',[300 300 400 200],'Name','Error when Importing Traces');

    txt = uicontrol('Parent',d,...
               'Style','text',...
               'Position',[20 80 360 100],...
               'String','The Alingment is not working, maybe your data cannot be aligned this way. Please check the User Guide or go to  https://github.com/nicolagalvanetto/Fodis/issues');

    btn = uicontrol('Parent',d,...
               'Position',[150 20 70 25],...
               'String','Close',...
               'Callback','delete(gcf)');
    
    beep
    delete(h);
end


data.translateLc=zeros(data.nTraces,1);
showTraces(handles);

function menuManualAlign_Callback(hObject, eventdata, handles)

global positiveResult
global mainHandles

mainHandles = handles;

% check flags
nTraces = positiveResult.nTraces;
if(nTraces == 0)
    menuMarkAllValid_Callback(hObject, eventdata, handles);
end
if(nTraces <= 0);return;end

set(handles.sliderTraces, 'value', 1);
manualAlign;

% --------------------------------------------------------------------
function automatic_align_Callback(hObject, eventdata, handles)

global positiveResult
global mainHandles;

mainHandles = handles;

nTraces = positiveResult.nTraces;
if(nTraces == 0);menuMarkAllValid_Callback(hObject, eventdata, handles);end
nTraces = positiveResult.nTraces;
if(nTraces <= 0);return;end

set(handles.sliderTraces, 'value', 1);

showTraces(handles)
automaticAlign

dd = dialog('Position',[300 300 400 200],'Name','Warning: reference-free alignment');

    txt = uicontrol('Parent',dd,...
               'Style','text',...
               'Position',[20 80 360 100],...
               'String','The reference-free alingment may lead to inapproriate results if applied to heterogeneous datasets: Please use it only with homogeneous dasets.');

    btn = uicontrol('Parent',dd,...
               'Position',[150 20 70 25],...
               'String','Close',...
               'Callback','delete(gcf)');

function menuMarkAllValid_Callback(hObject, eventdata, handles)

global data
global positiveResult

set(handles.editOffset, 'string', '0');
editOffset_Callback(handles.editOffset, eventdata, handles)

positiveResult.indexTrace=1:1:data.nTraces;
positiveResult.nTraces = data.nTraces;

showTraces(handles);


function menuallSel_Callback(hObject, eventdata, handles)

global data
global positiveResult

data.removeTraces(positiveResult.indexTrace) = 0;    
showTraces(handles)


function menuSwitchValidNonValid_Callback(hObject, eventdata, handles)

global positiveResult
global data

if positiveResult.nTraces==data.nTraces
    warndlg('All traces are valid!')
    return
end

alltrace=1:1:data.nTraces;
inverse=~ismember(alltrace,positiveResult.indexTrace);

positiveResult.indexTrace=alltrace(inverse);
positiveResult.nTraces=length(alltrace(inverse));
set(handles.sliderTraces, 'value',1)

showTraces(handles);

function menuSwapSelNonSel_Callback(hObject, eventdata, handles)

global data
data.removeTraces=~data.removeTraces;

showTraces(handles)

function menuNSLikeNV_Callback(hObject, eventdata, handles)

global positiveResult
global data

NotSelected=find(data.removeTraces);
NotSelecedInValid=ismember(positiveResult.indexTrace,NotSelected);

positiveResult.indexTrace(NotSelecedInValid)=[];
positiveResult.nTraces=length(positiveResult.indexTrace);
set(handles.sliderTraces, 'value',1)
showTraces(handles)

function menuClearFiltering_Callback(hObject, eventdata, handles)
global data
global positiveResult

positiveResult.nTraces=data.nTraces;
positiveResult.nTraces=1:1:data.nTraces;

function menuToolsExportPlot_Callback(hObject, eventdata, handles)

hn=figure;
copyobj(handles.axesMain,hn);
set(gca,'position',[0.1300 0.1100 0.7750 0.8150]);




function auto_multiGauss_Callback(hObject, eventdata, handles)

value=get(hObject,'Checked');
if strcmp(value,'on')
    set(hObject,'Checked','off')
else
    set(hObject,'Checked','on')
end
showTraces(handles);

function menuDeltaLcHistogram_Callback(hObject,~, handles)      %#ok<DEFNU>
resetMenuDeltaHistograms(handles, hObject)

function menuDeltaLcFc_Callback(hObject,~, handles)             %#ok<DEFNU>
resetMenuDeltaHistograms(handles, hObject)

function menuLcDeltaLc_Callback(hObject,~, handles)             %#ok<DEFNU>
resetMenuDeltaHistograms(handles, hObject)

function resetMenuDeltaHistograms(handles, hObject)
% Reset menuDeltaLcHistograms
set(handles.menuDeltaLcHistogram, 'checked', 'off');
set(handles.menuDeltaLcFc, 'checked', 'off');
set(handles.menuLcDeltaLc, 'checked', 'off');

% check current hObject
set(hObject, 'checked', 'on');
showTraces(handles);


function menuExtractPlot_Callback(hObject, eventdata, handles)

function menuFileOpenSample_Callback(hObject, eventdata, handles)
global mainHandles

mainHandles=handles;
% initialize GUI
% init(handles);

try

[tracesExtend,tracesRetract]=OpenSampleGui;
clear -global temp

catch ME
    disp(ME);
    
    d = dialog('Position',[300 300 400 200],'Name','Error when Opening Data');
    txt = uicontrol('Parent',d,...
        'Style','text',...
        'HorizontalAlignment','left',...
        'Position',[20 80 400 100],...
        'String',['There is a problem with the files or with the folder. ' newline...
        'Please check the User Guide or go to ' newline...
        'https://github.com/nicolagalvanetto/Fodis/issues ' newline...
        'or send us an email ' newline...
        'fodis.help@gmail.com ']);
    btn = uicontrol('Parent',d,...
        'Position',[150 20 70 25],...
        'String','Close',...
        'Callback','delete(gcf)');
    beep
    
    beep
    delete(h);
end


% update traces if there is any
if size(tracesExtend,1)>=1
    updateTraces(handles, hObject, eventdata, '', tracesExtend, tracesRetract);
    showTraces(handles)
    find_trace_Callback(handles.find_trace, eventdata, handles);

end

function menuLoadSession_Callback(hObject, eventdata, handles)

global data
global positiveResult
global mainHandles

basicfold=data.basicFolder;
if isempty(basicfold);basicfold='.'; end
f=filesep;

[filename, pathname] = uigetfile({[basicfold f '*.afm']}, 'Load session');

if (filename == 0);return;end
data.basicFolder=pathname;

% initialize
init(handles);
% create waitbar
h = waitbar(0.5, 'Please wait...');
% load session
load(fullfile(pathname, filename), '-MAT');

setParams(handles, params);


delete(h)

set(handles.sliderTraces, 'Value', 1);
set(handles.sliderTraces, 'Enable', 'on');
set(handles.sliderTraces, 'Min', 1);
set(handles.sliderTraces, 'Max', data.nTraces);
set(handles.sliderTraces, 'SliderStep', [1/data.nTraces 1/data.nTraces]);
set(handles.sliderTraces, 'Value', 1);

showTraces(handles);


function menuFileSave_Callback(hObject, eventdata, handles)

global data
global positiveResult
global mainHandles

mainHandles=handles;

basicfold=data.basicFolder;
if isempty(basicfold);basicfold='.'; end

% open save session
[filename, pathname] = uiputfile({'*.afm'}, 'Save session', basicfold);

if (filename == 0);return;end
data.basicFolder=pathname;

% create waitbar
h = waitbar(0.5, 'Please wait...');

% get params
params = getParams(handles);
% save session
save(fullfile(pathname, filename), 'data','mainHandles', 'positiveResult', 'params','mainHandles', '-v7.3');
%delete waitbar
waitbar(1);
delete(h);


function menuImportTraces_Callback(hObject, eventdata, handles)
global data

basicfold=data.basicFolder;
f=filesep;

if isempty(basicfold);basicfold='.'; end

% get folder
[inputFileName, pathname] = uigetfile([basicfold f '*.txt'], 'Import traces', 'MultiSelect', 'on');
% if the user chooses "Cancel"
if ~iscell(inputFileName) && length(inputFileName) == 1 && (inputFileName == 0)
    return;
end
data.basicFolder=pathname;
% if the user chosses just one file create a cell with the name, otherwise
% the cell is created by uigetfile
if(~iscell(inputFileName))
    temp = inputFileName;
    inputFileName = {};
    inputFileName{1, 1} = temp;
end

try 

% for each inputFileName
for iiName = 1:size(inputFileName, 2)
    
    jj = 1;

    % get filename
    filename = inputFileName{iiName};
    filename = fullfile(pathname, filename);
    
    h = waitbar(0, 'Please wait, we are reading...'); 

    % load traces
    datatt = importdata(filename);
    
    
    
    %Check if is wave or not
    if isstruct(datatt); traces = datatt.data;
    else traces=datatt;  end
    
    tracesRetract = {};
    for ii = 1:2:size(traces,2);
        
        waitbar(ii/size(traces,2));
        
        % X-DATA analysis
        trace = traces(:, ii + 1)';
        
        % Clean the Data
        % check 0
        idxRemove = (trace == 0);
        % flip idxRemove
        idxRemove = idxRemove(end:-1:1);
        % find first point that it is not 0
        tempIdx = find(idxRemove == false, 1, 'first');
        % clear idxRemove
        idxRemove(:) = false;
        
        % set idxRemove
        if ~isempty(tempIdx)
            idxRemove((end - tempIdx + 1):end) = true;
        end
        
        % remove 0
        trace(idxRemove) = [];
        % Save X in tracesRetract
        tracesRetract{jj, 1} = trace;
        tracesExtend{jj, 1} = [];
        % Y-DATA analysis
        trace = traces(:, ii)';
       
        % remove 0
        trace(idxRemove) = [];
        % Change sign
        trace = -trace;
        tracesRetract{jj, 2} = trace;
        tracesExtend{jj, 2} = [];

        jj = jj + 1;
        
      
    end

    updateTraces(handles, hObject, eventdata, pathname, tracesExtend, tracesRetract);
    
    delete(h);
    
end

catch ME
    
    disp(ME);
    
    d = dialog('Position',[300 300 400 200],'Name','Error when Opening Data');
    txt = uicontrol('Parent',d,...
        'Style','text',...
        'HorizontalAlignment','left',...
        'Position',[20 80 400 100],...
        'String',['There is a problem with the files or with the folder. ' newline...
        'Please check the User Guide or go to ' newline...
        'https://github.com/nicolagalvanetto/Fodis/issues ' newline...
        'or send us an email ' newline...
        'fodis.help@gmail.com ']);
    btn = uicontrol('Parent',d,...
        'Position',[150 20 70 25],...
        'String','Close',...
        'Callback','delete(gcf)');
    beep
    
    beep
    delete(h);
end


% show traces
showTraces(handles);

function menuImportRows_Callback(hObject, eventdata, handles)
    global data

basicfold=data.basicFolder;
f=filesep;

if isempty(basicfold);basicfold='.'; end

% get folder
[inputFileName, pathname] = uigetfile([basicfold f '*.txt'], 'Import traces', 'MultiSelect', 'on');
% if the user chooses "Cancel"
if ~iscell(inputFileName) && length(inputFileName) == 1 && (inputFileName == 0)
    return;
end
data.basicFolder=pathname;
% if the user chosses just one file create a cell with the name, otherwise
% the cell is created by uigetfile
if(~iscell(inputFileName))
    temp = inputFileName;
    inputFileName = {};
    inputFileName{1, 1} = temp;
end



% for each inputFileName
for iiName = 1:size(inputFileName, 2)
    
    jj = 1;

    % get filename
    filename = inputFileName{iiName};
    filename = fullfile(pathname, filename);
    
    h = waitbar(0.5, 'Please wait, we are reading...'); 

    % load traces
    traces = dlmread(filename, ' ')';
    
            
    tracesRetract = {};
    for ii = 1:2:size(traces,2)
        
        
        
        % X-DATA analysis
        trace = traces(:, ii + 1)';
        
        % Clean the Data
        % check 0
        idxRemove = (trace == 0);
        % flip idxRemove
        idxRemove = idxRemove(end:-1:1);
        % find first point that it is not 0
        tempIdx = find(idxRemove == false, 1, 'first');
        % clear idxRemove
        idxRemove(:) = false;
        
        % set idxRemove
        if ~isempty(tempIdx)
            idxRemove((end - tempIdx + 1):end) = true;
        end
        
        % remove 0
        trace(idxRemove) = [];
        % Save X in tracesRetract
        tracesRetract{jj, 1} = trace;
        tracesExtend{jj, 1} = [];
        % Y-DATA analysis
        trace = traces(:, ii)';
       
        % remove 0
        trace(idxRemove) = [];
        
        tracesRetract{jj, 2} = -trace;
        tracesExtend{jj, 2} = [];

        jj = jj + 1;
        
      
    end

    updateTraces(handles, hObject, eventdata, pathname, tracesExtend, tracesRetract);
    
    delete(h);
    
end


% show traces
showTraces(handles);

% --------------------------------------------------------------------
function menuClearAll_Callback(hObject, eventdata, handles)
init(handles);

function menuExportTraces_Callback(hObject, eventdata, handles)

global data
global positiveResult

tempData = [];

%Add Trace
indexCount = 1;
for ii = 1:positiveResult.nTraces
    
    iieffTrace=positiveResult.indexTrace(ii);       %Actual trace
    % check if traces must be removed
    if(data.removeTraces(iieffTrace) == 1);continue;end
    
    tempData.tracesRetract{indexCount, 1} = data.tracesRetract{iieffTrace,1} + data.translateLc(iieffTrace);
    tempData.tracesRetract{indexCount, 2} = data.tracesRetract{iieffTrace,2};
    
    indexCount = indexCount + 1;
end

tempData.nTraces = indexCount - 1;
exportTraces(tempData);


function menuRemoveDuplicates_Callback(hObject, eventdata, handles)



function menuCorr2Valid_Callback(hObject, eventdata, handles)
global mainHandles

mainHandles=handles;

corr2selection;

function select_points_ClickedCallback(~, ~, handles)           %#ok<DEFNU>

global data
global positiveResult

indexTrace = round(get(handles.sliderTraces, 'value'));       %Slider Value 
indexeffTrace=positiveResult.indexTrace(indexTrace);          %Actual trace

persistentlenght=str2double(get(handles.editPersistenceLength,'String'))*1E-9;
axes(handles.axesMain)

dcm_obj = datacursormode(handles.fig_FtW);
set(dcm_obj,'DisplayStyle','datatip',...
    'SnapToDataVertex','off','Enable','on')

disp('Click line to display a data tip, then press Return.')
% Wait while the user does this.
pause 
c_info = getCursorInfo(dcm_obj);
pos_info=c_info.Position;
x=pos_info(1);y=pos_info(2);

tss=x*1E-9;
F=y*1E-12;



if ~isempty(x)
    disp('Point selected, WLC generated')
    [Lc]=tracepoint2FcLc(tss,F,persistentlenght);
    data.listLc{indexeffTrace}=cat(2,data.listLc{indexeffTrace},Lc*1E9);
    data.listFc{indexeffTrace}=cat(2,data.listFc{indexeffTrace},F);
    [data.listLc{indexeffTrace},I] = sort(data.listLc{indexeffTrace},'Ascend');
    data.listFc{indexeffTrace}= data.listFc{indexeffTrace}(I);
    setappdata(handles.fig_FtW,'triggerLc2',1)
    showTraces(handles)
end

function removepts_ClickedCallback(hObject, eventdata, handles)



global data
global positiveResult

indexTrace = round(get(handles.sliderTraces, 'value'));
indexeffTrace=positiveResult.indexTrace(indexTrace);          %Actual trace

data.listLc{indexeffTrace}=[];
data.listFc{indexeffTrace}=[];
showTraces(handles)



function showTraces(handles)
global data
global positiveResult

% update index trace and nTraces
nTraces = positiveResult.nTraces;                          %Nr total traces
indexTrace = min( round(get(handles.sliderTraces, 'value')), nTraces);    %Slider Position
indexeffTrace=positiveResult.indexTrace(indexTrace);       %Actual trace

%Load Translation
translateLc = data.translateLc(indexeffTrace);

% get size marker
sizeMarker = str2double (get(handles.editSizeMarker, 'string')) * 3;
% get flag flip
flagFlip = get(handles.checkboxFlipTraces, 'value');

% get colors
rgb = distinguishable_colors(nTraces, [1 1 1; 0 0 0; 1 0 0]);

% get Lc parameters
[tssMin,tssMax,FMin,FMax,xBin,binSize,histValue,maxHistValue,zerosTempMax,...
    LcMin,LcMax,maxTssOverLc,xBinSizeMax,thresholdHist,xBinFcMax,...
    xBinDeltaLc, minDeltaLc, maxDeltaLc, startLcDeltaLc, persistenceLength]...
    = getLcParameters(handles);
  
% Set GUI values
set(handles.textFrameRate, 'String', ['/' num2str(nTraces)]);
set(handles.editFrame, 'String', num2str(indexTrace));  

set(handles.sliderTraces, 'Value', indexTrace);
set(handles.sliderTraces, 'Max', nTraces);
set(handles.sliderTraces, 'SliderStep', [1 1] / nTraces);
set(handles.sliderTraces, 'Value', indexTrace);
set(handles.SGL_fil,'Value',data.SGFilter(indexeffTrace));

[extendTipSampleSeparation,retractTipSampleSeparation,extendVDeflection,...
    retractVDeflection]= getTrace(indexeffTrace, data);

if flagFlip == 1;mirror=-1;else mirror=1;end %flip the signale

temp_e = mirror*extendVDeflection;
temp_r = mirror*retractVDeflection;

% get tss F
tss = retractTipSampleSeparation+translateLc;
F = -retractVDeflection;


% get contour lenght
[Lc, Fc, LcHist, LcHistMax, xBinLcHist, LcHistVar, FcMax, FcProfile, LcMaxPts]...
    = getContourLength(tss, F, tssMin, tssMax, FMin, FMax, LcMin, LcMax,...
    maxTssOverLc, xBin, binSize, zerosTempMax,0, xBinSizeMax,...
    thresholdHist, persistenceLength);

%List LC editable
LcTraces=data.listLc{indexeffTrace};
AutoLC=LcMaxPts;


choice='NN';

if getappdata(handles.fig_FtW,'triggerLc') && ...
        getappdata(handles.fig_FtW,'triggerLc2')
    choice = questdlg('This choice will reset your Lc chose for analysis. Would you like to recalculate the WLC curve with the new settings?', ...
        'Remove LC selected','Yes Please','No Thanks','No Thanks');
    backupLC= data.listLc{indexeffTrace};
    backupFC= data.listFc{indexeffTrace};
elseif getappdata(handles.fig_FtW,'triggerLc')
    data.listLc=cell(data.nTraces,1);
    data.listFc=cell(data.nTraces,1);
    data.listLc{indexeffTrace}=AutoLC*1E9;
    data.listFc{indexeffTrace}=FcMax(FcMax>0);
    setappdata(handles.fig_FtW,'triggerLc',getappdata(handles.fig_FtW,'triggerLc2'))
end



if strcmp(choice,'Yes Please')
    data.listLc=cell(data.nTraces,1);
    data.listFc=cell(data.nTraces,1);
    data.listLc{indexeffTrace}=AutoLC*1E9;
    data.listFc{indexeffTrace}=FcMax(FcMax>0);
    setappdata(handles.fig_FtW,'triggerLc2',0)
    setappdata(handles.fig_FtW,'triggerLc',0)
elseif strcmp(choice,'No Thanks')
    data.listLc{indexeffTrace}=backupLC;
    data.listFc{indexeffTrace}=backupFC;
    setappdata(handles.fig_FtW,'triggerLc',0)
end

if isempty(LcTraces)
    data.listLc{indexeffTrace}=AutoLC*1E9;
    data.listFc{indexeffTrace}=FcMax(FcMax>0);
    setappdata(handles.fig_FtW,'triggerLc',0)
end

allLcString = sprintf('%.0f,' , data.listLc{indexeffTrace});  %string conversion
allLcString = allLcString(1:end-1); %remove the comma

LcMaxPts=data.listLc{indexeffTrace}*1E-9;
FcMax=data.listFc{indexeffTrace};
% get LcHistMax
LcHistMax = hist(LcMaxPts, xBin);
LcHistMax(LcHistMax > 1) = 1;
set(handles.EditLcSaved, 'string',allLcString)

%Get info on popupmenu
indexView = getIndexView(handles);


if strcmp(indexView, 'Global contour length histogram max')...
        || strcmp(indexView, 'Global contour length histogram') ...
        || strcmp(indexView, 'Global peaks') 
else
    % clear screen
    axes(handles.axesMain)
    legend off
    cla;
end


switch(indexView)
%%
    case 'Traces'
        
        %PLOT EXTEND
        if(~isempty(extendTipSampleSeparation))
            plot((extendTipSampleSeparation + translateLc) * 1E9, temp_e * 1E12, 'red');
            hold on;
        end
        %PLOT RETRACT
        h=plot((retractTipSampleSeparation  + translateLc) * 1E9, temp_r * 1E12,'b');
        set(h,'Tag','lineprinc')
        
        %Plot WLC chosen
        LcTraces=str2double(strsplit(get(handles.editLcTraces, 'string'),',')); 
        plotWLCFit(LcTraces, sizeMarker, flagFlip, persistenceLength,[]);
        
        %PLOT INFO
        box on;
        %title(['File: ' fileName ' [' data.sessionFileName ']']);
        xlabel('tss (nm)');
        ylabel('F (pN)');
        xlim([data.scaleMinTss data.scaleMaxTss]);
        ylim([data.scaleMinF data.scaleMaxF]);
        
        

        
        
%%        
    case 'Traces-Lc'
        
        %plot Traces
        h=plot((retractTipSampleSeparation  + translateLc) * 1E9, temp_r * 1E12, 'blue');
        set(h,'Tag','lineprinc')
        selections = LcMaxPts * 1E9;
        
        % get colors
        rgb = distinguishable_colors(length(selections) + 1, [1 1 1; 0 0 0; 1 0 0; [0 1 0]]);
        
        % for each selection
        plotWLCFit(selections, sizeMarker, flagFlip, persistenceLength,rgb);
               
        %Plot WLC manually chosen
        LcTraces=str2double(strsplit(get(handles.editLcTraces, 'string'),',')); 
        plotWLCFit(LcTraces, sizeMarker, flagFlip, persistenceLength,[]);
        
        % set up trace
        %         title(['File: ' fileName ' [' data.sessionFileName ']']);
        xlim([data.scaleMinTss data.scaleMaxTss]);  xlabel('tss (nm)');
        ylim([data.scaleMinF data.scaleMaxF]);      ylabel('F (pN)');
        
        hold on;plot(xlim, [0 0],'k:');
        hold on;plot([0 0],ylim, 'k:');
        
        
        
    
        
                
        %%
    case 'Contour length (Lc, Fc)'
        
        FcMax=FcMax(FcMax > 0);
        
        hold on;
        plot(Lc* 1E9, Fc* 1E12, '.', 'MarkerSize', sizeMarker, 'color', [0 0 0]);
        plot(LcMaxPts * 1E9, FcMax * 1E12, 'o', 'MarkerSize', sizeMarker * 3, 'color', [1 0 0]);
        plot(xBinSizeMax * 1E9, FcProfile * 1E12, 'color', [0, 1, 1]);
        
        %Plot Lc of WLC chosen
        %get and convert in double value the Lc specified 
        yax=get(handles.axesMain,'ylim');
        plotLcVL(get(handles.editLcTraces,'string'),sizeMarker,yax)
        
        title(['Lc histogram'  ' [' data.sessionFileName ']']);
        xlabel('Lc (nm)');
        ylabel('Fc (pN)');
        xlim([data.scaleMinTss data.scaleMaxTss]);
        ylim([data.scaleMinF data.scaleMaxF]);
%%        
    case 'Contour length histogram'
        % Lc histogram
        
        bar(xBin*1E9, LcHist,1,'BaseValue', 0, 'FaceColor', [0 0 0], 'EdgeColor', [0.8 .8 .8]);
        hold on
        
        bar(xBin*1E9, (LcHistMax),'FaceColor', [1 0 0], 'EdgeColor',  [0.8 0 0]);
        
        xlim([data.scaleMinTss data.scaleMaxTss]);
        ylim([0,max(LcHist(:))]);
        hold on;
        plot(xlim, [0 0],'k:');
        hold on;
        plot([0 0],ylim, 'k:');
        title(['Lc histogram'   ' [' data.sessionFileName ']']);
        xlabel('Lc (nm)');
        ylabel('counting');
%%        
    case 'Delta Lc histograms'
        
        % get deltaLc histograms
        [deltaLc, deltaLcFc, lcDeltaLc] = getDeltaLc(startLcDeltaLc, LcMaxPts, FcMax, minDeltaLc, maxDeltaLc, xBinDeltaLc);
        
        if(strcmp(get(handles.menuDeltaLcHistogram, 'checked') , 'on'))
            
            bar(xBinDeltaLc * 1E9, deltaLc,1,'FaceColor',[0 0 0],'EdgeColor',[0 0 0],'LineWidth',sizeMarker);
            title(['Delta Lc histogram' ' [' data.sessionFileName ']']);
            xlabel('Delta Lc (nm)'); xlim([data.scaleMinTss data.scaleMaxTss]);
            ylabel('p');             ylim([0, max(deltaLc(:))]);
            
        elseif(strcmp(get(handles.menuDeltaLcFc, 'checked') , 'on'))
            
            plot(deltaLcFc(:, 1) * 1E9, deltaLcFc(:, 2) * 1E12, 'x', 'markerSize', sizeMarker, 'color', [0, 0, 0]);
            title(['Delta Lc-Fc [' data.sessionFileName ']']);
            xlabel('Delta Lc (nm)'); xlim([data.scaleMinTss data.scaleMaxTss]);
            ylabel('Fc (pN)');       ylim([data.scaleMinF data.scaleMaxF]);
            
        elseif(strcmp(get(handles.menuLcDeltaLc, 'checked') , 'on'))
 
            plot(lcDeltaLc(:, 2) * 1E9, lcDeltaLc(:, 1) * 1E9, 'x', 'markerSize', sizeMarker, 'color', [0, 0, 0]);
            title(['Lc-delta Lc [' data.sessionFileName ']']);
            xlabel('Lc (nm)');       xlim([data.scaleMinTss data.scaleMaxTss]);
            ylabel('Delta Lc (nm)'); ylim([0, max(lcDeltaLc(:, 1)) * 1E9]);
   
        end
%%        
    case 'Contour length variance (Lc, Var(max(Lc)))'
        
        % Lc variance
        stem(xBinLcHist*1E9, LcHistVar, 'color', [0 0 0]);
        
        title(['Lc variance' ' [' data.sessionFileName ']']);
        xlabel('Lc (nm)'); xlim([data.scaleMinTss data.scaleMaxTss]);
        ylabel('variance'); ylim([0 10 * 1E-18]);
%%        
    case 'Global contour length histogram'
        
        % initialize max Fc
        FcMax = cell(1,length(nonzeros(data.removeTraces(positiveResult.indexTrace))));
        LcMaxPts= cell(1,length(nonzeros(data.removeTraces(positiveResult.indexTrace))));
        iisave=1;
        h = waitbar(0, 'Please wait...');
        
        for ii=1:1:nTraces
            
            iieffTrace=positiveResult.indexTrace(ii);       %Actual trace
            translateLc = data.translateLc(iieffTrace);
            % check if traces must be removed
            if(data.removeTraces(iieffTrace) == 1);continue;end
            
            % get trace
            [~,retractTipSampleSeparation,...
                ~,retractVDeflection,~]...
                = getTrace(iieffTrace, data);
            
            % get tss F
            tempTss = retractTipSampleSeparation+ translateLc;
            tempF = -retractVDeflection;
            
            % get contour lenght
              [~,~,tempLcHist,~,~,~, FcMax{iisave},~,LcMaxPts{iisave}]...
                  = getContourLength(tempTss,tempF, tssMin, tssMax, FMin,...
                  FMax, LcMin, LcMax,maxTssOverLc, xBin, binSize,...
                  zerosTempMax, 0,xBinSizeMax, thresholdHist, persistenceLength);
              
              histValue = histValue + tempLcHist;

              % Manual selection
            if ~isempty(data.listLc{iieffTrace})
                LcMaxPts{iisave}=data.listLc{iieffTrace}*1E-9;
                FcMax{iisave}=data.listFc{iieffTrace};
            end

            % check waitbar
            if(mod(ii, round(0.1 * nTraces)) == 0); waitbar(ii/nTraces); end
            iisave=iisave+1;
        end
        
        delete(h);
        
        % normalize histograms
        histValue = histValue / max(histValue(:));
        
        cla;
        
        % plot histogram
        bar(xBin * 1E9, histValue, 1, 'BaseValue', 0, 'FaceColor', [0 0 0], 'EdgeColor', [1 1 1]);
        
        title(['Lc histogram' ' [' data.sessionFileName ']']);
        xlabel('Lc (nm)');  xlim([data.scaleMinTss data.scaleMaxTss]);
        ylabel('Counting'); ylim([0 max(histValue(:))]);
        
        %Plot division bar for group
        NrIntGroup_Callback(handles.NrIntGroup,[], handles)       
        %find GP reduced to path plot
        data.GMreduced=Lc2GlobRed(LcMaxPts,iisave-1,data.intervals);
%%        
    case 'Global contour length histogram max'
               
        iisave=1;

        % initialize max Fc
        LcMaxTot=[];
        FcMaxTot=[];
        FcMax = cell(1,length(nonzeros(data.removeTraces(positiveResult.indexTrace))));
        LcMaxPts= cell(1,length(nonzeros(data.removeTraces(positiveResult.indexTrace))));
        h = waitbar(0, 'Please wait...');
        
        % for each trace
        for ii = 1:1:nTraces
                        
            iieffTrace=positiveResult.indexTrace(ii);       %Current trace
            translateLc = data.translateLc(iieffTrace);
            % check if traces must be removed
            if(data.removeTraces(iieffTrace) == 1);continue;end
            
            %get traces
            [extendTipSampleSeparation,retractTipSampleSeparation,...
                extendVDeflection,retractVDeflection,fileName]=getTrace(iieffTrace, data);
            
            % get tss F
            tempTss = retractTipSampleSeparation + translateLc;
            tempF = -retractVDeflection;
            
            % get contour lenght
            [~,~,~,tempLcHistMax,~,~, FcMax{iisave},~,LcMaxPts{iisave}] =...
                getContourLength(tempTss, tempF, tssMin, tssMax, FMin,...
                FMax, LcMin, LcMax, maxTssOverLc, xBin, binSize,...
                zerosTempMax, translateLc, xBinSizeMax, thresholdHist,...
                persistenceLength);
            
            % Manual selection
            if ~isempty(data.listLc{iieffTrace})
                LcMaxPts{iisave}=data.listLc{iieffTrace}*1E-9;
                FcMax{iisave}=data.listFc{iieffTrace};
                % get LcHistMax
                tempLcHistMax = hist(LcMaxPts{iisave}, xBin);
                tempLcHistMax(tempLcHistMax > 1) = 1;
            end
            
            LcMaxTot=[LcMaxTot,LcMaxPts{iisave}];
            FcMaxTot=[FcMaxTot,FcMax{iisave}];
            % get peaks
            maxHistValue = maxHistValue + tempLcHistMax;
            
            % check ii
            if(mod(ii, round(0.1*nTraces))==0);waitbar(ii/nTraces);end
            iisave=iisave+1;
        end
        
        delete(h)
        % normalize histograms
        nrseltrace=sum(~cellfun(@isempty,FcMax));
        maxHistValue = maxHistValue/nrseltrace;
        
        % clear screen
        axes(handles.axesMain)
        legend off
        cla;
        
        % plot histogram
        hmax=bar(xBin * 1E9, maxHistValue, 1, 'BaseValue', 0, 'FaceColor', [0 0 0], 'EdgeColor', [0.8 0.8 0.8]);
        set(hmax,'tag','histmax');
        title(['Lc histogram max' ' [' data.sessionFileName ']']);
        xlabel('Lc (nm)'); xlim([data.scaleMinTss data.scaleMaxTss]);
        ylabel('p');       ylim([0 max(maxHistValue)]);
        
        if strcmp(get(handles.auto_multiGauss,'checked'),'on')
            
            hw = waitbar(0, 'Please wait...');
            
            LMP=LcMaxTot'*1e9;
            
             %We need to reduce the noise in LMP taking out a constant
            %distribution of points along lc
            
            %need to find a better formula for the step: depending on the
            %number ot traces and the extension of Lc
            
            
            stepSize=40/nTraces;  %good parameter to remove point in Lc
            steps=min(LMP):stepSize:max(LMP);
            nsteps=size(steps,2);
            
            for kk=1:nsteps
                minM(:,kk)=abs(LMP-steps(kk));
            end
            for kk=1:nsteps
                [~,minP(kk)]=min(minM(:,kk));
            end
            LMPextend=LMP;
            for kk=1:nsteps
                LMPextend(minP(kk))=-1000;  %for each step, we remove one Lc
            end
            LMPreduced=LMP(LMPextend>0);
            
            if(size(LMPreduced,1) < 0.1*size(LMP,1))
                LMPreduced=LMP;
            end
           
            
            %find the best number od Gaussinas minimizing AIC parameters
            for jj=1:25
                try
                    gmSet{jj} = fitgmdist(LMPreduced,jj,'Options',statset('MaxIter',100));
                    AICset(jj)=gmSet{jj}.AIC;
                    [~, MSGID] = lastwarn();
                    warning('off', MSGID)
                catch
                    AICset(jj)=NaN;
                end
                waitbar(jj/15);
            end;
            delete(hw);
            
            
            [~,minAIC]=min(AICset);
            
            
            gm=gmSet{min(minAIC)};
            xgauss=data.scaleMinTss:0.01:data.scaleMaxTss;
            areatot=(binSize*1E9)*sum(nonzeros(maxHistValue));
            hold on
            
            %plot area and peaks of the distribution
            
            for ll=1:minAIC
                ygauss(ll,:) = 0.85*gaussian1D(xgauss, gm.mu(ll), sqrt(gm.Sigma(:,:,ll)),areatot*gm.ComponentProportion(ll));
                plot(xgauss,ygauss(ll,:),'LineWidth',2)
            end
            h=area(xgauss,sum(ygauss),'EdgeColor', 'none');
            data.MultyGauss=[xgauss; sum(ygauss)]';
            alpha(h,0.2)  
            
            
            %probability of each peak
            prob_peaks=[];
            for ll=1:minAIC
                prob_peaks(ll)= gm.ComponentProportion(ll)* length(LMP)/nTraces;
            end
            
            
            
            %plot legend
            ColOrd = get(gca,'ColorOrder');
            ColOrdextend=vertcat(ColOrd,ColOrd,ColOrd,ColOrd,ColOrd,ColOrd,ColOrd,ColOrd);
            for ll=1:minAIC
                 text(0.02, 1 - 0.03 * ll, [sprintf('p=%.2f',prob_peaks(ll) ) ...
            sprintf(' Lc=%.2f', gm.mu(ll) ) ...
            sprintf( ' std=%.2f',  sqrt(gm.Sigma(:,:,ll)) )], ...
              'color', ColOrdextend(ll,:),'Units', 'normalized');
                               
            end
        end
        
        %Plot division bar for group
        NrIntGroup_Callback(handles.NrIntGroup,[], handles)
        %find GP reduced to path plot
        data.GMreduced=Lc2GlobRed(LcMaxPts,iisave-1,data.intervals);
        
        % Plot histogram
        plotGaussian(xBin, maxHistValue);
        %%
    case 'Global contour length - Force plot'
                
        %Preallocate Data
        LcFc = [];
        
               
        % get selectedLcFc
        selectedLcFc = getappdata(handles.fig_FtW, 'selectedLcFc');
        
        if(~isempty(selectedLcFc))  
            selected_LcFc=[];
            selected_LcFcROI=[];
            selected_traces = [];
            indexSelected = 0;
            selected_LcMin = selectedLcFc(1);
            selected_LcMax = selectedLcFc(2);
            selected_FMin = selectedLcFc(3);
            selected_FMax = selectedLcFc(4);
        end
        
        h = waitbar(0, 'Please wait...');
        
        
        data.ExcelExport.LC={};
        data.ExcelExport.FC={};
        data.ExcelExport.Slope={};
        
        % for each trace
        for ii = 1:1:nTraces
                        
            iieffTrace=positiveResult.indexTrace(ii);       %Actual trace
            translateLc = data.translateLc(iieffTrace);
            % check if traces must be removed
            if(data.removeTraces(iieffTrace) == 1);continue;end
                            
            [extendTipSampleSeparation,retractTipSampleSeparation,...
                extendVDeflection,retractVDeflection,fileName]...
                = getTrace(iieffTrace, data);
            
            % get tss F
            tempTss = retractTipSampleSeparation + translateLc;
            tempF = -retractVDeflection;
            
            % get contour lenght
            [~, ~,~, ~, ~, ~, FcMax, ~, LcMaxPts] =...
                getContourLength(tempTss, tempF, tssMin, tssMax, FMin,FMax,...
                LcMin, LcMax, maxTssOverLc, xBin, binSize,zerosTempMax,...
                translateLc, xBinSizeMax, thresholdHist, persistenceLength);
            
            %Manual selection
            if ~isempty(data.listLc{iieffTrace})
                LcMaxPts=data.listLc{iieffTrace}*1E-9;
                FcMax=data.listFc{iieffTrace};
            end
            
            %calculate Loading rate before rupture of every peak:
            % calculate the slope of the peak first
            
            FcMaxEFF=FcMax(FcMax>0);
            SlopePeak=[];
            try
                for jjj=1:length(FcMaxEFF)
                    [~, position]=min(abs(tempF-FcMaxEFF(jjj)));
                    F20=tempF(position-20:position)';
                    tss20=tempTss(position-20:position)';
                    
                    tss20X = [ones(length(tss20),1) tss20];
                    b = tss20X\F20;
                    
                    SlopePeak(jjj)=b(2);
                                       
                end
                
                
                
            catch e
            end
              
                      
            data.ExcelExport.LC{iieffTrace,1}=LcMaxPts;
            data.ExcelExport.FC{iieffTrace,1}=FcMax(FcMax>0);
            data.ExcelExport.Slope{iieffTrace,1}=SlopePeak;

            [tempDeltaLc, tempDeltaLcFc, tempLcDeltaLc] =getDeltaLc...
                (startLcDeltaLc, LcMaxPts, FcMax, minDeltaLc, maxDeltaLc, xBinDeltaLc);
            
            if(isempty(LcFc))
                LcFc = [tempLcDeltaLc(:, 2), tempDeltaLcFc(:, 2)];
            else
                inputData = [tempLcDeltaLc(:, 2), tempDeltaLcFc(:, 2)];
                LcFc = cat(1, LcFc, inputData);
            end
            
            if(~isempty(selectedLcFc))
                
                % check lc
                current_lc = tempLcDeltaLc(:, 2);
                idx1 = and(current_lc >= selected_LcMin, current_lc <= selected_LcMax);
                
                % check FLc
                current_FLc = tempDeltaLcFc(:, 2);
                idx2 = and(current_FLc >= selected_FMin, current_FLc <= selected_FMax);
                
                % finalize idx
                idx = and(idx1, idx2);
                
                % check if there is at least one selected point in the
                % current trace
                if(sum(idx(:)) > 0)
                    
                    selected_LcFc = cat(1, selected_LcFc, [current_lc, current_FLc]);
                    selected_traces = cat(1, selected_traces, [tempTss', tempF']);
                    selected_LcFcROI = cat(1, selected_LcFcROI, [current_lc(idx), current_FLc(idx)]);
         
                    indexSelected = indexSelected + 1;
                end
            end

            % update waitbar
            if(mod(ii, round(0.1 * nTraces)) == 0);waitbar(ii/nTraces);end
        end
        
        delete(h);
        
%         % enable botton        
%             set(handles.buttonSelectLcFc,'Enable','on');
%             set(handles.buttondeleteLcFc,'Enable','on');
        % plot histogram
            data.LcFc=LcFc;
            plot(LcFc(:,1)* 1E9,LcFc(:,2)* 1E12,'x', 'markerSize', sizeMarker);
            title(['Lc - Force' ' [' data.sessionFileName ']']);
            xlabel('Lc (nm)');        xlim([data.scaleMinTss data.scaleMaxTss]);
            ylabel('Fc (pN)');       ylim([data.scaleMinF data.scaleMaxF]);
            
            if(~isempty(selectedLcFc))
                hold on
                plot(selected_LcFc(:, 1) * 1E9, selected_LcFc(:, 2) * 1E12, 'x', 'markerSize', sizeMarker, 'color', [1, 0, 0]);
                %subplot details Lc - Delta Lc - Force
                rangeFc(handles,data,selected_traces,selected_LcFcROI,sizeMarker,indexSelected);
                data.LcFcROI=selected_LcFcROI;
                
            end
            
        NrIntGroup_Callback(handles.NrIntGroup,[], handles)
        hold off
        
%%
    case 'Global delta Lc histograms'
                
        %Preallocate Data
        deltaLc = [];
        deltaLcFc = [];
        lcDeltaLc = [];

        % get selectedLcDeltaLc
        selectedLcDeltaLc = getappdata(handles.fig_FtW, 'selectedLcDeltaLc');
        
        if(~isempty(selectedLcDeltaLc))  
            selected_lcDeltaLc=[];
            selected_lcDeltaLcROI=[];
            selected_traces = [];
            indexSelected = 0;
            selected_LcMin = selectedLcDeltaLc(1);
            selected_LcMax = selectedLcDeltaLc(2);
            selected_DeltaLcMin = selectedLcDeltaLc(3);
            selected_DeltaLcMax = selectedLcDeltaLc(4);
        end
        
        h = waitbar(0, 'Please wait...');

        % for each trace
        for ii = 1:1:nTraces
                        
            iieffTrace=positiveResult.indexTrace(ii);       %Actual trace
            translateLc = data.translateLc(iieffTrace);
            % check if traces must be removed
            if(data.removeTraces(iieffTrace) == 1);continue;end
                            
            [extendTipSampleSeparation,retractTipSampleSeparation,...
                extendVDeflection,retractVDeflection,fileName]...
                = getTrace(iieffTrace, data);
            
            % get tss F
            tempTss = retractTipSampleSeparation + translateLc;
            tempF = -retractVDeflection;
            
            % get contour lenght
            [~, ~,~, ~, ~, ~, FcMax, ~, LcMaxPts] =...
                getContourLength(tempTss, tempF, tssMin, tssMax, FMin,FMax,...
                LcMin, LcMax, maxTssOverLc, xBin, binSize,zerosTempMax,...
                translateLc, xBinSizeMax, thresholdHist, persistenceLength);
            
            %Manual selection
            if ~isempty(data.listLc{iieffTrace})
                LcMaxPts=data.listLc{iieffTrace}*1E-9;
                FcMax=data.listFc{iieffTrace};
            end

            [tempDeltaLc, tempDeltaLcFc, tempLcDeltaLc] =getDeltaLc...
                (startLcDeltaLc, LcMaxPts, FcMax, minDeltaLc, maxDeltaLc, xBinDeltaLc);
            
            if(isempty(deltaLc))
                deltaLc = tempDeltaLc;
                deltaLcFc = [tempDeltaLcFc(:, 1), tempDeltaLcFc(:, 2)];
                lcDeltaLc = [tempLcDeltaLc(:, 2), tempLcDeltaLc(:, 1)];
                LcFc = [tempLcDeltaLc(:, 2), tempDeltaLcFc(:, 2)];
            else
                deltaLc = deltaLc + tempDeltaLc;
                inputData = [tempDeltaLcFc(:, 1), tempDeltaLcFc(:, 2)];
                deltaLcFc = cat(1, deltaLcFc, inputData);

                inputData = [tempLcDeltaLc(:, 2), tempLcDeltaLc(:, 1)];
                lcDeltaLc = cat(1, lcDeltaLc, inputData);
                
                inputData = [tempLcDeltaLc(:, 2), tempDeltaLcFc(:, 2)];
                LcFc = cat(1, LcFc, inputData);
            end
            
            if(~isempty(selectedLcDeltaLc))
                
                % check lc
                current_lc = tempLcDeltaLc(:, 2);
                idx1 = and(current_lc >= selected_LcMin, current_lc <= selected_LcMax);
                
                % checl deltaLc
                current_deltaLc = tempLcDeltaLc(:, 1);
                idx2 = and(current_deltaLc >= selected_DeltaLcMin, current_deltaLc <= selected_DeltaLcMax);
                
                % finalize idx
                idx = and(idx1, idx2);
                
                % check if there is at least one selected point in the
                % current trace
                if(sum(idx(:)) > 0)
                    
                    selected_lcDeltaLc = cat(1, selected_lcDeltaLc, [current_lc, current_deltaLc]);
                    selected_traces = cat(1, selected_traces, [tempTss', tempF']);
                    selected_lcDeltaLcROI = cat(1, selected_lcDeltaLcROI, [current_lc(idx), current_deltaLc(idx)]);
         
                    indexSelected = indexSelected + 1;
                end
            end

            % update waitbar
            if(mod(ii, round(0.1 * nTraces)) == 0);waitbar(ii/nTraces);end
        end
        
        delete(h);
        
        % Sort plot based on the right click menu
        if(strcmp(get(handles.menuDeltaLcHistogram, 'checked') , 'on'))
            % plot histogram
            bar(xBinDeltaLc * 1E9, deltaLc, 1, 'BaseValue', 0,...
                'FaceColor', [0 0 0], 'EdgeColor', [1 1 1]);
            
            title(['Delta Lc histogram' ' [' data.sessionFileName ']']);
            xlabel('Delta Lc (nm)'); xlim([data.scaleMinTss data.scaleMaxTss]);
            ylabel('p');             ylim([0, max(deltaLc(:))]);
            
        elseif(strcmp(get(handles.menuDeltaLcFc, 'checked') , 'on'))
            plot(deltaLcFc(:, 1) * 1E9, deltaLcFc(:, 2) * 1E12, 'x',...
                'markerSize', sizeMarker, 'color', [0, 0, 0]);
            
            title(['Delta Lc-Fc [' data.sessionFileName ']']);
            xlabel('Delta Lc (nm)'); xlim([data.scaleMinTss data.scaleMaxTss]);
            ylabel('Fc (pN)');       ylim([data.scaleMinF data.scaleMaxF]);
            
        elseif(strcmp(get(handles.menuLcDeltaLc, 'checked') , 'on'))
            plot(lcDeltaLc(:, 1) * 1E9, lcDeltaLc(:, 2) * 1E9, 'x',...
                'markerSize', sizeMarker, 'color', [0, 0, 0]);
            
            if(get(handles.checkboxDensityPlot, 'value') == 1)
                %Get data from gui
                res = str2double(get(handles.editDensityPlot, 'string'));
                ratioReference = str2double(get(handles.editRatioReference, 'string'));
                flagPerPoints = get(handles.checkboxDensityPlotPerPoints, 'value');
                
                cla;
                smoothhist2D(lcDeltaLc .* 1E9, (nTraces - 1) / 8,...
                    [res, res], [], 'image', [data.scaleMinTss data.scaleMaxTss],...
                    [data.scaleMinF data.scaleMaxF], 'x', sizeMarker,...
                    flagPerPoints, ratioReference); 
            end

            title(['Lc-delta Lc [' data.sessionFileName ']']);
            xlabel('Lc (nm)');        xlim([data.scaleMinTss data.scaleMaxTss]);
            ylabel('Delta Lc (nm)');  ylim([data.scaleMinF data.scaleMaxF]);
            if(~isempty(selectedLcDeltaLc))
                hold on
                plot(selected_lcDeltaLc(:, 1) * 1E9, selected_lcDeltaLc(:, 2) * 1E9, 'x', 'markerSize', sizeMarker, 'color', [1, 0, 0]);
                %subplot details Lc - Delta Lc - Force
                rangedeltaLc(handles,data,selected_traces,selected_lcDeltaLcROI,sizeMarker,indexSelected)
            end
        end
        
%%
    case 'Global persistance length-Lc histogram'
        % Fit the traces with variable persistance lengths
        
       data.ExcelExport.p={};
        data.ExcelExport.LCwithfree_p={};
        data.ExcelExport.FC={};
        
        
        % Fit the traces with variable persistance lengths
        
        minP = str2double(get(handles.editMinP, 'string')) * 1E-9;
        maxP = str2double(get(handles.editMaxP, 'string')) * 1E-9;
        binP = str2double(get(handles.editBinP, 'string')) * 1E-9;
        listP = minP:binP:maxP;
        % Initialize variables
        bestP = [];
        bestLcPeaks = [];
        hold on
        h = waitbar(0, 'Please wait...');
        
        % for each trace
        for ii = 1:nTraces
           
            iieffTrace=positiveResult.indexTrace(ii);       %Actual trace
            translateLc = data.translateLc(iieffTrace);
            % check if traces must be removed
            if(data.removeTraces(iieffTrace) == 1); continue;end
            
            % get trace
            [extendTipSampleSeparation, retractTipSampleSeparation,...
                extendVDeflection, retractVDeflection, fileName]  =...
                getTrace(iieffTrace, data);
            
            % get tss F
            tempTss = retractTipSampleSeparation + translateLc;
            tempF = -retractVDeflection;
            
            
            % get contour lenght (just need for FcMax (they should correspond in terms of number of peaks)
            [~, ~,~, ~, ~, ~, FcMax, ~,~] =...
                getContourLength(tempTss, tempF, tssMin, tssMax, FMin,FMax,...
                LcMin, LcMax, maxTssOverLc, xBin, binSize,zerosTempMax,...
                translateLc, xBinSizeMax, thresholdHist, persistenceLength);
            
            
            % get best fit with variable persistance length
            [currentBestP, currentBestLcPeaks] = ...
                fitPersistanceLength(tempTss, tempF, listP,...
                tssMin, tssMax, FMin, FMax, LcMin, LcMax, maxTssOverLc,...
                xBin, binSize, zerosTempMax, translateLc, xBinSizeMax,...
                thresholdHist, persistenceLength);
            
            % save best fit
            bestP = [bestP, currentBestP];
            bestLcPeaks = [bestLcPeaks, currentBestLcPeaks];
            
            
            data.ExcelExport.LCwithfree_p{iieffTrace,1}=currentBestLcPeaks;
            data.ExcelExport.FC{iieffTrace,1}=FcMax(FcMax>0);
            data.ExcelExport.p{iieffTrace,1}=currentBestP;
            
            
            
            if(mod(ii, round(0.1 * nTraces)) == 0);waitbar(ii/nTraces);end
        end
        delete(h);
        plot(bestLcPeaks*1E9, bestP*1E9, 'x', 'color', [0, 0, 0])
               
        % set up trace
        title(['File: '' [' data.sessionFileName ']']);
        xlabel('lc (nm)');
        ylabel('persistance length (nm)');
        xlim([data.scaleMinTss data.scaleMaxTss]);
        ylim([0, maxP * 1E9]);
             
        
%%        
    case 'Global peaks'
        
        iisave=1;
        LcMaxPts = cell(1,length(nonzeros(data.removeTraces(positiveResult.indexTrace))));
        globalMatrix = zeros(nTraces, length(xBin));

        h = waitbar(0, 'Please wait');
        
        for ii = 1:1:nTraces
            
            iieffTrace=positiveResult.indexTrace(ii);       %Actual trace
            translateLc = data.translateLc(iieffTrace);
            % check if traces must be removed
            if(data.removeTraces(iieffTrace) == 1);continue;end
            
            % get trace
            [extendTipSampleSeparation,retractTipSampleSeparation,...
                extendVDeflection,retractVDeflection,fileName]...
                = getTrace(iieffTrace, data);
            
            % get tss F
            tempTss = retractTipSampleSeparation + translateLc;
            tempF = -retractVDeflection;
            
            % get contour lenght
            [~,~,~,tempLcHistMax,~,~,~,~,LcMaxPts{iisave}]...
                = getContourLength(tempTss, tempF, tssMin, tssMax,...
                FMin, FMax, LcMin, LcMax, maxTssOverLc, xBin, binSize,...
                zerosTempMax, translateLc, xBinSizeMax, thresholdHist,...
                persistenceLength);
            
            % Manual selection
            if ~isempty(data.listLc{iieffTrace})
                LcMaxPts{iisave}=data.listLc{iieffTrace}*1E-9;
                % get LcHistMax
                tempLcHistMax = hist(LcMaxPts{iisave}, xBin);
                tempLcHistMax(tempLcHistMax > 1) = 1;
            end
                        
            globalMatrix(iisave, :) = tempLcHistMax(:);                    % set globalMatrix
            
            % update waitbar
            if(mod(ii, round(0.1 * nTraces)) == 0);waitbar(ii / nTraces);end
            iisave=iisave+1;
        end
        
        delete(h);
        cla;
        hold on;
        imagesc(xBin*1E9,0.5:1:nTraces-0.5,globalMatrix)
        cmap =[1 1 1;0 0 0];
        colormap(cmap)
        
        title(['Global peaks' ' [' data.sessionFileName ']']);
        xlabel('Lc (nm)'); xlim([data.scaleMinTss data.scaleMaxTss]);
        ylabel('traces');  ylim([0 iisave-1]);
        
        %Plot division bar for group
        NrIntGroup_Callback(handles.NrIntGroup,[], handles)   
        %find GP reduced to path plot
        data.GMreduced=Lc2GlobRed(LcMaxPts,iisave-1,data.intervals);
        
%%        
    case 'Superimpose traces'
        
        % get flag flip
        flagFlip = get(handles.checkboxFlipTraces, 'value');
        histData = [];
        
        for ii = 1:1:nTraces
                        
            iieffTrace=positiveResult.indexTrace(ii);       %Actual trace
            translateLc = data.translateLc(iieffTrace);
            % check if traces must be removed
            if(data.removeTraces(iieffTrace) == 1);continue;end
            
            [extendTipSampleSeparation,retractTipSampleSeparation,...
                extendVDeflection,retractVDeflection,fileName]  = getTrace(iieffTrace, data);
            
            if flagFlip;retractVDeflection=-retractVDeflection;end
            inputData = [((retractTipSampleSeparation + translateLc) * 1E9)', retractVDeflection' * 1E12];
            histData = cat(1, histData, inputData);
            
            hold on
             %%Superimpose traces plot
            plot((retractTipSampleSeparation + translateLc) * 1E9, retractVDeflection * 1E12,...
                '.',  'MarkerSize', sizeMarker, 'color', 'k');
             
             %plot((retractTipSampleSeparation + translateLc) * 1E9, retractVDeflection * 1E12, 'color', 'k');
            
        end
        
        %Axes limits and title
        title(['Superimpose of ' num2str(nTraces) ' traces'...
            ' [' data.sessionFileName ']']);
        xlim([data.scaleMinTss data.scaleMaxTss]); xlabel('tss (nm)');
        ylim([data.scaleMinF data.scaleMaxF]);     ylabel('F (pN)');
        %Plot 0 axes
        hold on; plot(xlim, [0 0],'k:');
        hold on; plot([0 0], ylim, 'k:');
        
        if(get(handles.checkboxDensityPlot, 'value') == 1)
            
            %Get data from GUI
            res = str2double(get(handles.editDensityPlot, 'string'));
            ratioReference = str2double(get(handles.editRatioReference, 'string'));
            flagPerPoints = get(handles.checkboxDensityPlotPerPoints, 'value');
            
            %Density Plot
            cla;
            smoothhist2D(histData, nTraces, [res, res], [],...
                'image', [data.scaleMinTss data.scaleMaxTss],...
                [data.scaleMinF data.scaleMaxF], '.',sizeMarker,...
                flagPerPoints, ratioReference);
            %Axes
            title(['Density plot of ', num2str(nTraces), ' traces']);
            xlim([data.scaleMinTss data.scaleMaxTss]); xlabel('tss (nm)');
            ylim([data.scaleMinF data.scaleMaxF]);     ylabel('F (pN)');
            
        end
        
        %Plot WLC chosen
        LcTraces=str2double(strsplit(get(handles.editLcTraces, 'string'),',')); 
        plotWLCFit(LcTraces, sizeMarker, flagFlip, persistenceLength,[]);%%        
        
    case 'Superimpose Lc'
                    
        histData = [];
        
        for ii = 1:1:nTraces
            
            iieffTrace=positiveResult.indexTrace(ii);       %Actual trace
            translateLc = data.translateLc(iieffTrace);
            % check if traces must be removed
            if(data.removeTraces(iieffTrace) == 1);continue;end
            
            [extendTipSampleSeparation,retractTipSampleSeparation,...
                extendVDeflection,retractVDeflection,fileName]= getTrace(iieffTrace, data);
            
            % get tss F
            tempTss = retractTipSampleSeparation + translateLc;
            tempF = -retractVDeflection;
            
            % get contour lenght
            [Lc,Fc,~,~] = getContourLength(tempTss,...
                tempF, tssMin, tssMax, FMin, FMax, LcMin, LcMax,...
                maxTssOverLc, xBin, binSize, zerosTempMax, translateLc,...
                xBinSizeMax, thresholdHist, persistenceLength);
                        
            inputData = [(Lc* 1E9)', Fc' * 1E12];
            histData = cat(1, histData, inputData);
            
            % Superimpose Lc Plot
            hold on
            plot(Lc * 1E9, Fc * 1E12, '.', 'MarkerSize', sizeMarker, 'color', 'k');
            
        end
        
        %Axes limits and title
        title(['Superimpose of ' num2str(nTraces) ' Lc histograms'...
            ' [' data.sessionFileName ']']);
        xlim([data.scaleMinTss data.scaleMaxTss]); xlabel('Lc (nm)');
        ylim([FMin * 1E12 FMax * 1E12]);           ylabel('F (pN)');
        % Plot 0 Axes
        hold on; plot(xlim, [0 0],'k:');
        hold on; plot([0 0], ylim, 'k:');
                
        if get(handles.checkboxDensityPlot,'value')
            
            res = str2double(get(handles.editDensityPlot, 'string'));
            ratioReference = str2double(get(handles.editRatioReference, 'string'));
            flagPerPoints = get(handles.checkboxDensityPlotPerPoints, 'value');
            % Density Plot            
            cla;
            smoothhist2D(histData, (nTraces), [res, res], [],...
                'image', [data.scaleMinTss data.scaleMaxTss],...
                [FMin * 1E12 FMax * 1E12], '.', sizeMarker,...
                flagPerPoints, ratioReference);
            
            title(['Density plot of ', num2str(nTraces), ' traces']);
            xlim([data.scaleMinTss data.scaleMaxTss]); xlabel('Lc (nm)');
            ylim([FMin * 1E12 FMax * 1E12]);           ylabel('F (pN)');
            
        end
        
        %Plot Lc of WLC chosen
        %get and convert in double value the Lc specified
        yax=get(handles.axesMain,'ylim');
        plotLcVL(get(handles.editLcTraces,'string'),sizeMarker,yax)
        
%%        
    case 'Traces-Fit with fixed persistance length'       
        
        % get peaks profile
        [lcPeaks, slideTrace] = getProfilePeaks(tss, F, tssMin, tssMax,...
            FMin, FMax, LcMin, LcMax, maxTssOverLc, xBin, binSize,...
            zerosTempMax, translateLc, xBinSizeMax, thresholdHist, persistenceLength);
        
        % get fitTrace
        xBinFit = tssMin:str2double(get(handles.editBinFit, 'string')) * 1E-9:tssMax;
        [fitTrace] = getFitTrace(tss, lcPeaks, slideTrace, persistenceLength, xBinFit);
        
        % get colors
        rgb = distinguishable_colors(length(lcPeaks) + 1, [1 1 1; 0 0 0; 1 0 0; [0 1 0]]);
        
        %plot traces
        plot(tss * 1E9, F * 1E12, 'color', [0, 0, 1]);
        hold on
       
        % for each peak
        for ii = 1:length(lcPeaks)
            % plot range
            rangeSlide = slideTrace(ii, 1):slideTrace(ii, 2);
            plot(tss(rangeSlide) * 1E9, F(rangeSlide) * 1E12, 'color', rgb(ii, :, :));
        end
        
        % plot fit
        plot(xBinFit * 1E9, fitTrace * 1E12, 'color', [0, 0, 0]);

        title(['File: [' data.sessionFileName ']']);
        xlim([data.scaleMinTss data.scaleMaxTss]); xlabel('tss (nm)');
        ylim([data.scaleMinF data.scaleMaxF]);     ylabel('F (pN)');
        
        
    case 'Dynamic persistance length'
        minP = str2double(get(handles.editMinP, 'string')) * 1E-9;
        maxP = str2double(get(handles.editMaxP, 'string')) * 1E-9;
        binP = str2double(get(handles.editBinP, 'string')) * 1E-9;
        
        
        
        listP = minP:binP:maxP;
        
        % initialize legend
        textLegend = {};
        textColor = {};
        indexLegend = 1;
        
        % get tss F
        tss = retractTipSampleSeparation + translateLc;
        F = -retractVDeflection;
        
        % get best fit with variable persistance length
        [bestP, bestPeaks] = fitPersistanceLength(tss, F, listP, tssMin,...
            tssMax, FMin, FMax, LcMin, LcMax, maxTssOverLc, xBin, binSize,...
            zerosTempMax, translateLc, xBinSizeMax, thresholdHist, persistenceLength);
        
        % get colors
        rgb = distinguishable_colors(length(bestPeaks) + 1, [1 1 1; 0 0 0; 1 0 0; [0 1 0]]);
        
        % plot trace
        plot(tss * 1E9, F * 1E12, 'blue');
        hold on

        % set legend
        textLegend{indexLegend} = 'trace';
        textColor{indexLegend} = rgb(1, :, :);
        indexLegend = indexLegend + 1;
        

        % plot best fit
        for ii = 1:length(bestP)
            % get F from Lc
            [Fc, tssc] = getFFromLc(bestPeaks(ii), bestP(ii), tss);
            Fc = -Fc;
            if(flagFlip);Fc = -Fc; end
            
            plot(tssc * 1E9, Fc * 1E12, '.', 'color', rgb(ii, :, :));
            
            % set legend
            textLegend{indexLegend} = ['lc = ', num2str(bestPeaks(ii) * 1E9), ' p = ', num2str(bestP(ii) * 1E9)];
            textColor{indexLegend} = rgb(ii, :, :);
            indexLegend = indexLegend + 1;
            
        end

        plot(xlim, [0 0],'k:');
        plot([0 0],ylim, 'k:');

        % set up trace
        title(['File: ' ' [' data.sessionFileName ']']);
        xlabel('tss (nm)'); xlim([data.scaleMinTss data.scaleMaxTss]);
        ylabel('F (pN)');   ylim([data.scaleMinF data.scaleMaxF]);
        
        
        % Plot Legend
        legend on
        hLegend = legend(textLegend);
        hKids = get(hLegend, 'Children');
        hText = hKids(strcmp(get(hKids, 'Type'), 'text'));
        hText = flipud(hText);
        set(hText, {'Color'}, textColor');
            
        
end



%Enable and disable GUI appeareance
changeGUI(handles,indexView)
changeupdatecolor(handles,1)

% set remove checkbox
set(handles.checkboxRemove, 'value', data.removeTraces(indexeffTrace));
set(handles.editGroups,'String',num2str(data.TracesGroup(indexeffTrace)));

% plot valid trace

TraceRemoved=data.removeTraces(positiveResult.indexTrace); 

stringSelectedTraces =1:1:positiveResult.nTraces;
stringSelectedTraces=stringSelectedTraces(~(TraceRemoved));
allOneString = sprintf('%.0f,' , stringSelectedTraces);  %string conversion
allOneString = allOneString(1:end-1); %remove the comma
% show selection
set(handles.editSelectedTraces, 'string', allOneString);
% show details selected and valid
set(handles.textSelected, 'string', ['Traces Selected     '...
    num2str(sum(~(TraceRemoved))) '/' num2str(positiveResult.nTraces)]);
set(handles.textValid, 'string', ['Traces Valid            '...
    num2str(positiveResult.nTraces) '/' num2str(data.nTraces)]);
%enable grid and box
if(get(handles.checkboxGrid, 'value') == 1);grid on;
else grid off; end


box on


function [indexView] = getIndexView(handles)
% Get indexView
indexView = get(handles.popupmenuView, 'value');
stringView = get(handles.popupmenuView, 'string');
indexView = stringView{indexView};


function updateTraces(handles, hObject, eventdata, folder, tracesExtend, tracesRetract,fileNames)

global data
% data.fileNames = mergeFileNames(data.fileNames, fileNames);

% General
data.tracesExtend = mergeTraces(data.tracesExtend, tracesExtend);
data.tracesRetract = mergeTraces(data.tracesRetract, tracesRetract);
%set backup to restore
data.tracesExtendBackup=mergeTraces(data.tracesExtendBackup, tracesExtend);
data.tracesRetractBackup=mergeTraces(data.tracesRetractBackup, tracesRetract);

data.scaleMinTss = str2double(get(handles.editTraceMinTss, 'string'));
data.scaleMaxTss = str2double(get(handles.editTraceMaxTss, 'string'));
data.scaleMinF = str2double(get(handles.editTraceMinF, 'string'));
data.scaleMaxF = str2double(get(handles.editTraceMaxF, 'string'));
data.nTraces = size(data.tracesRetract, 1);
data.translateLc((end + 1):data.nTraces) = 0;

% WLC
data.listLc=cell(data.nTraces,1);
data.listFc=cell(data.nTraces,1);
data.ExcelExport.LC=cell(data.nTraces,1);
data.ExcelExport.FC=cell(data.nTraces,1);
data.ExcelExport.Slope=cell(data.nTraces,1);
data.ExcelExport.p=cell(data.nTraces,1);
data.ExcelExport.LCwithfree_p=cell(data.nTraces,1);

setappdata(handles.fig_FtW,'triggerLc',0)
setappdata(handles.fig_FtW,'triggerLc2',0)
setappdata(handles.axesMain, 'selectedLcDeltaLc', []);

% Grouping
data.intervals=[];
data.TracesGroup=ones(data.nTraces,1);
data.SGFilter=zeros(data.nTraces,1);


data.removeTraces((end + 1):data.nTraces) = 0;
data.saveOnScreen((end + 1):data.nTraces) = 0;
data.Reference=1;
data.CurrAlgnTr=1;
data.offset = 0;                            % Set global offset 
data.sessionFileName = folder;              % Set Name of the file

%Filtering
data.Filter.rect=[];
data.Filter.norect=[];

%Gaussian
data.gaussianWindow=[];

%Gui Setting
set(handles.sliderTraces, 'Value', 1);
set(handles.sliderTraces, 'Enable', 'on');
set(handles.sliderTraces, 'Min', 1);
set(handles.sliderTraces, 'Max', data.nTraces);
set(handles.sliderTraces, 'SliderStep', [1/data.nTraces 1/data.nTraces]);
set(handles.sliderTraces, 'Value', 1);

% mark all valid
menuMarkAllValid_Callback(hObject, eventdata, handles);


function [TracesMerged] = mergeTraces(traces1, traces2)

sizetr1=size(traces1,1);
sizetr2=size(traces2,1);
TracesMerged=cell(sizetr1+sizetr2,2);

if sizetr1>=1
    TracesMerged(1:sizetr1,1)=traces1(:,1);
    TracesMerged(1:sizetr1,2)=traces1(:,2);
    TracesMerged(sizetr1+1:(sizetr1+sizetr2),1)=traces2(:,1);
    TracesMerged(sizetr1+1:(sizetr1+sizetr2),2)=traces2(:,2);
else
    TracesMerged(:,1)=traces2(:,1);
    TracesMerged(:,2)=traces2(:,2);
end


function [fileNames1] = mergeFileNames(fileNames1, fileNames2)
% Merge fileNames
if(isempty(fileNames1));fileNames1 = {};end
size1 = size(fileNames1, 2);
% for each new fileName
for ii = 1:size(fileNames2, 2) %add fileName  
    fileNames1{size1 + ii} = fileNames2{ii};
end

function [U]=rows2DifferentSingleElements(M)
U=[];
for ll=1:size(M,1)
    U(ll,1)=row2UniqueNum(M(ll,:));
end

function [a]=row2UniqueNum(A)

lungh=size(A,2);
a=10^lungh;
for jj=0:lungh-1
    a = a + A(lungh-jj)*10^(jj);
end

function Untitled_2_Callback(~, ~,~)                            %#ok<DEFNU>
function menuFile_Callback(~, ~,~)                              %#ok<DEFNU>
function menuFilter_Callback(~, ~,~)                            %#ok<DEFNU>
function menuAlign_Callback(~, ~,~)                             %#ok<DEFNU>
function menuSuperimposeMain_Callback(~, ~,~)                   %#ok<DEFNU>
function menu_path_analysis_Callback(~, ~, ~)                   %#ok<DEFNU>
function menuselection_Callback(~,~, ~)                         %#ok<DEFNU>
function contextAxesMain_Callback(~,~, ~)                       %#ok<DEFNU>





% --------------------------------------------------------------------
function density_path_Callback(hObject, eventdata, handles)
global data
densityPathPlot(data.GMreduced);



% --------------------------------------------------------------------
function info_Callback(hObject, eventdata, handles)



% --------------------------------------------------------------------
function contributors_Callback(hObject, eventdata, handles)
Contributors;




% --------------------------------------------------------------------
function finger_ROI_Callback(hObject, eventdata, handles)
global mainHandles;

mainHandles = handles;

fingerprint_ROI;



% --------------------------------------------------------------------
function gethelp_Callback(hObject, eventdata, handles)
get_help_here;





% --------------------------------------------------------------------
function Heterogeneity_Callback(hObject, eventdata, handles)

set(handles.popupmenuView,'value',10);
showTraces(handles);
heterogeneity;




% --------------------------------------------------------------------
function absolute2tss_Callback(hObject, eventdata, handles)
global mainHandles;

mainHandles = handles;

absolute2tss;



function find_trace_Callback(hObject, eventdata, handles)
global data
global positiveResult

% update index trace and nTraces
nTraces = positiveResult.nTraces;                          %Nr total traces
indexTrace = min( round(get(handles.sliderTraces, 'value')), nTraces);    %Slider Position
indexeffTrace=positiveResult.indexTrace(indexTrace);       %Actual trace

%Load Translation
translateLc = data.translateLc(indexeffTrace);

% get size marker
sizeMarker = str2double (get(handles.editSizeMarker, 'string')) * 3;
% get flag flip
flagFlip = get(handles.checkboxFlipTraces, 'value');

  
% Set GUI values
set(handles.textFrameRate, 'String', ['/' num2str(nTraces)]);
set(handles.editFrame, 'String', num2str(indexTrace));  

set(handles.sliderTraces, 'Value', indexTrace);
set(handles.sliderTraces, 'Max', nTraces);
set(handles.sliderTraces, 'SliderStep', [1 1] / nTraces);
set(handles.sliderTraces, 'Value', indexTrace);

[extendTipSampleSeparation,retractTipSampleSeparation,extendVDeflection,...
    retractVDeflection]= getTrace(indexeffTrace, data);

if flagFlip == 1;mirror=-1;else mirror=1;end %flip the signale


% get tss F
tss = retractTipSampleSeparation+translateLc;
F = -retractVDeflection;

set(handles.editTraceMinTss,'string', (min(tss)*1e9) );
set(handles.editTraceMaxTss,'string', (max(tss)*1e9));
set(handles.editTraceMinF,'string', (min(F)*1e12));
set(handles.editTraceMaxF,'string', (max(F)*1e12));

editTraceMinTss_Callback(hObject, eventdata, handles);
editTraceMaxF_Callback(hObject, eventdata, handles);

if ( abs(min(tss)*1e9) > 2000 | abs(max(tss)*1e9) > 2000 | abs(min(F)*1e12) > 2000 | abs(max(F)*1e12) > 2000 )
    Mess = msgbox({['Your trace is very large or far from the origin.'];['There may be a problem with data dimensions, baseline subtraction or TSS transformation.'...
       ];['--------------------'];['Please go to Tools>Pre-Processing  and try to adjust the trace.']...
       ;['You may check the Units and the Metric Prefix of the imported files.']});
    
    
end


function path_plot_Callback(hObject, eventdata, handles)
global data

if size(data.GMreduced,2)==0;warndlg('Select a Path Intervlal');return;end

pushbutton_updategrouping_Callback(handles.pushbutton_updategrouping, eventdata, handles)
parameters_path;


function combo_path_plot_Callback(hObject, eventdata, handles)

global data
global positiveResult

if size(data.GMreduced,2)==0;warndlg('Select a Path Intervlal');return;end

sizeMarker = str2double (get(handles.editSizeMarker, 'string'));
[TracesGroup]=combo_path_plot(data.GMreduced,sizeMarker);

Selected=find(~data.removeTraces);
SelectedInVald=ismember(find(~data.removeTraces),positiveResult.indexTrace);
data.TracesGroup(Selected(SelectedInVald))=TracesGroup;

function thomaplot_Callback(hObject, eventdata, handles)

global data

if size(data.GMreduced,2)==0;warndlg('Select a Path Intervlal');return;end
pushbutton_updategrouping_Callback(handles.pushbutton_updategrouping, eventdata, handles)

set(handles.popupmenuView,'value',10)                                      %Move to GLobal Force Plot
showTraces(handles)

parameters_thoma;



function pushbutton_intervals_Callback(hObject, eventdata, handles)
%set string for grouping

global data

set(handles.popupmenuView,'value',9)
if strcmp(get(handles.auto_multiGauss,'checked'),'off')
    set(handles.auto_multiGauss,'checked','on');
end
showTraces(handles)

try
    x=data.MultyGauss(:,1);
    y=data.MultyGauss(:,2);
    
    %find maxima and minima to find the intervals (sum a parabola to find
    %minima also in the extremes
    
    [pksM,locsM]=findpeaks(y);
    
    parabola=x.*(x-2*(x(locsM(1))))*-1e-6;
    
    
    [pksm,locsm]=findpeaks(-y+parabola);
    
    data.IntervalExteremes=round(x(locsm));
    data.IntervalExteremes(data.IntervalExteremes<0)=0;
    stringGroup=[];
    for i=1:length(data.IntervalExteremes)-1
        
        
        stringGroup=[stringGroup num2str(data.IntervalExteremes(i)) '-' num2str(data.IntervalExteremes(i+1)) ','];
        
        
    end
    
    set(handles.NrIntGroup,'string',stringGroup(1:end-1))
    NrIntGroup_Callback(handles.NrIntGroup,eventdata, handles)
    
catch e
    Mess = msgbox({['The automatic interval failed'];['There may be a problem with the extremes.']});
end


function menu_exportExcel_Callback(hObject, eventdata, handles)

global data
global positiveResult

try
    
    [FileName,PathName,FilterIndex] = uiputfile('.xls','Save Excel','ExportedData');%Set path
    
    if isequal(FileName,0) || isequal(PathName,0)                              % if the user chooses "Cancel"
        return
    end
    
    fullPath=fullfile(PathName,FileName);
    
    set(handles.popupmenuView,'value',10)                                      %Move to GLobal Force Plot
    showTraces(handles)
    
    hh = waitbar(0, 'Please wait, we are writing...');
    
    
    selections = get(handles.editSelectedTraces, 'string');           %to see the numbers of selected
    if isempty(selections)
        data.removeTraces(positiveResult.indexTrace) = 1;
        data.TracesGroup(positiveResult.indexTrace)=0;
        showTraces(handles);
        return
    end
    
    selections = textscan(selections, '%s', 'delimiter', ',');
    selections = str2double(selections{1});
    True_selections=find(~cellfun('isempty', data.ExcelExport.FC));   %to see the numbers in the valid
    
    numTraces = length(selections);                                          %Nr total traces
    
    Alphabet = {'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'...
        ,'AA','AB','AC','AD','AE','AF','AG','AH','AI','AJ','AK','AL','AM','AN','AO','AP','AQ','AR','AS','AT','AU','AV','AW','AX','AY','AZ'...
        ,'BA','BB','BC','BD','BE','BF','BG','BH','BI','BJ','BK','BL','BM','BN','BO','BP','BQ','BR','BS','BT','BU','BV','BW','BX','BY','BZ'};
    
    xlswrite(fullPath,{'Trace num.'},'A1:A1')
    xlswrite(fullPath,{'Peaks Lc (m)'},'B1:B1')
    
    for ii=1:numTraces
        xlswrite(fullPath,selections(ii),['A' num2str(ii+1) ':A' num2str(ii+1)])
        sizeLC=length(data.ExcelExport.LC{True_selections(ii)});
        xlswrite(fullPath,data.ExcelExport.LC{True_selections(ii)},['B' num2str(ii+1) ':' Alphabet{sizeLC+1} num2str(ii+1)])
        waitbar(ii/(3*numTraces));
    end
    
    xlswrite(fullPath,{'Trace num.'},['A' num2str(numTraces+3) ':A' num2str(numTraces+3)])
    xlswrite(fullPath,{'Peak Force (N)'},['B' num2str(numTraces+3) ':B' num2str(numTraces+3)])
    
    for ii=1:numTraces
        xlswrite(fullPath,selections(ii),['A' num2str(numTraces+ii+3) ':A' num2str(numTraces+ii+3)])
        sizeFC=length(data.ExcelExport.FC{True_selections(ii)});
        xlswrite(fullPath,data.ExcelExport.FC{True_selections(ii)},['B' num2str(numTraces+ii+3) ':' Alphabet{sizeFC+1} num2str(numTraces+ii+3)])
        waitbar((ii+numTraces)/(3*numTraces));
    end
    
    xlswrite(fullPath,{'Trace num.'},['A' num2str(2*numTraces+5) ':A' num2str(2*numTraces+5)])
    xlswrite(fullPath,{'Slope at the end of the peak (nN/nm)'},['B' num2str(2*numTraces+5) ':B' num2str(2*numTraces+5)])
    
    for ii=1:numTraces
        xlswrite(fullPath,selections(ii),['A' num2str(2*numTraces+ii+5) ':A' num2str(2*numTraces+ii+5)])
        sizeSlope=length(data.ExcelExport.Slope{True_selections(ii)});
        xlswrite(fullPath,data.ExcelExport.Slope{True_selections(ii)},['B' num2str(2*numTraces+ii+5) ':' Alphabet{sizeSlope+1} num2str(2*numTraces+ii+5)])
        waitbar((ii+2*numTraces)/(3*numTraces));
    end
    
    delete(hh);
    
catch e
    Mess = msgbox({['Your system seems to have some problems with the Excel export'];...
        ['-----------------------------------------'];['We suggest to use:  Tools > Export Peak Info (comma separated values .txt)']});
end

disp('Done')


function menu_exportcsv_Callback(hObject, eventdata, handles)
global data
global positiveResult


[filename, pathname] = uiputfile({'*.txt'}, 'Export traces');

if (filename == 0);return;end

fid = fopen(fullfile(pathname, filename), 'w');

set(handles.popupmenuView,'value',10)                                      %Move to GLobal Force Plot
showTraces(handles)

hh = waitbar(0, 'Please wait, we are writing...');

selections = get(handles.editSelectedTraces, 'string');           %to see the numbers of selected
if isempty(selections)
   data.removeTraces(positiveResult.indexTrace) = 1;  
   data.TracesGroup(positiveResult.indexTrace)=0;
   showTraces(handles);
   return
end

selections = textscan(selections, '%s', 'delimiter', ',');
selections = str2double(selections{1});
True_selections=find(~cellfun('isempty', data.ExcelExport.FC));   %to see the numbers in the valid




numTraces = length(selections);                                          %Nr total traces

fprintf(fid, 'Trace num.,Peaks Lc (m)\n');

for ii=1:numTraces
    
    values_comma=strjoin(arrayfun(@(x) num2str(x),data.ExcelExport.LC{True_selections(ii)},'UniformOutput',false),',');
    values_complete=strcat(num2str(selections(ii)),',',values_comma,'\n');
    fprintf(fid, values_complete);
    waitbar(ii/(3*numTraces));
end

fprintf(fid, '\nTrace num.,Peak Force (N)\n');

for ii=1:numTraces
    
    values_comma=strjoin(arrayfun(@(x) num2str(x),data.ExcelExport.FC{True_selections(ii)},'UniformOutput',false),',');
    values_complete=strcat(num2str(selections(ii)),',',values_comma,'\n');
    fprintf(fid, values_complete);
    waitbar((ii+numTraces)/(3*numTraces));
end

fprintf(fid, '\nTrace num.,Slope at the end of the peak (nN/nm)\n');

for ii=1:numTraces
    
    values_comma=strjoin(arrayfun(@(x) num2str(x),data.ExcelExport.Slope{True_selections(ii)},'UniformOutput',false),',');
    values_complete=strcat(num2str(selections(ii)),',',values_comma,'\n');
    fprintf(fid, values_complete);
    waitbar((ii+2*numTraces)/(3*numTraces));
end


fclose(fid);
delete(hh);

disp('Done')

function menu_exportcsv_free_p_Callback(hObject, eventdata, handles)


global data
global positiveResult


[filename, pathname] = uiputfile({'*.txt'}, 'Export traces');

if (filename == 0);return;end

fid = fopen(fullfile(pathname, filename), 'w');

set(handles.popupmenuView,'value',16)                                      %Move to GLobal Force Plot
showTraces(handles)

hh = waitbar(0, 'Please wait, we are writing...');

selections = get(handles.editSelectedTraces, 'string');           %to see the numbers of selected
if isempty(selections)
   data.removeTraces(positiveResult.indexTrace) = 1;  
   data.TracesGroup(positiveResult.indexTrace)=0;
   showTraces(handles);
   return
end

selections = textscan(selections, '%s', 'delimiter', ',');
selections = str2double(selections{1});
True_selections=find(~cellfun('isempty', data.ExcelExport.FC));   %to see the numbers in the valid




numTraces = length(selections);                                          %Nr total traces

fprintf(fid, 'Trace num.,Peaks Lc with free p (m)\n');

for ii=1:numTraces
    
    values_comma=strjoin(arrayfun(@(x) num2str(x),data.ExcelExport.LCwithfree_p{True_selections(ii)},'UniformOutput',false),',');
    values_complete=strcat(num2str(selections(ii)),',',values_comma,'\n');
    fprintf(fid, values_complete);
    waitbar(ii/(3*numTraces));
end

fprintf(fid, '\nTrace num.,Peak Force (N)\n');

for ii=1:numTraces
    
    values_comma=strjoin(arrayfun(@(x) num2str(x),data.ExcelExport.FC{True_selections(ii)},'UniformOutput',false),',');
    values_complete=strcat(num2str(selections(ii)),',',values_comma,'\n');
    fprintf(fid, values_complete);
    waitbar((ii+numTraces)/(3*numTraces));
end

fprintf(fid, '\nTrace num.,p - Persistence length (nm)\n');

for ii=1:numTraces
    
    values_comma=strjoin(arrayfun(@(x) num2str(x),data.ExcelExport.p{True_selections(ii)}*1e9,'UniformOutput',false),',');
    values_complete=strcat(num2str(selections(ii)),',',values_comma,'\n');
    fprintf(fid, values_complete);
    waitbar((ii+2*numTraces)/(3*numTraces));
end


fclose(fid);
delete(hh);

disp('Done')



function menu_membrane_Callback(hObject, eventdata, handles)




function break_memb_Callback(hObject, eventdata, handles)


global data
global positiveResult

nTraces = positiveResult.nTraces;

% get flag flip
flagFlip = get(handles.checkboxFlipTraces, 'value');
histData = [];

position_value=[];
force_value_with_zero=[];
force_value=[];



hhh=waitbar(0);

for ii = 1:1:nTraces
    
    iieffTrace=positiveResult.indexTrace(ii);       %Actual trace
    translateLc = data.translateLc(iieffTrace);
    % check if traces must be removed
    if(data.removeTraces(iieffTrace) == 1);continue;end
    
    [~,retractTipSampleSeparation,...
        ~,retractVDeflection,~]  = getTrace(iieffTrace, data);
    
    if flagFlip;retractVDeflection=-retractVDeflection;end
    inputData = [((retractTipSampleSeparation + translateLc) * 1E9)', retractVDeflection' * 1E12];
    histData = cat(1, histData, inputData);
    
    
    peak_prominence= str2double(get(handles.editThresholdNPoints, 'string')) * 1e-10;
  
          
    [pks,locs, w, prominence] = findpeaks(retractVDeflection ,'MinPeakDistance',100,'MinPeakProminence',peak_prominence); 
    
    if ~isempty(pks)
       [M, I] = max(pks);
        force_value= cat(1,force_value , pks(I));
        force_value_with_zero= cat(1,force_value_with_zero , pks(I));
        position_value= cat(1, position_value, (retractTipSampleSeparation(locs(I)) + translateLc));
    else
        force_value_with_zero= cat(1,force_value_with_zero , 0);
        
    end
       
    
    waitbar(ii/nTraces);
    
    
end

delete(hhh);

figure;
hold on;
try
    ax = gca;
    c = ax.Color;
    ax.Color = 'black';
    pointsize = 50;
    scatter(data.position(:,1),data.position(:,2), pointsize, force_value_with_zero, 'filled','square');
    colormap bone;
catch e
end


pause(0.5);


figure;


plot(position_value * 1E9, force_value * 1E12,'+');

xlabel('tss (nm)');
ylabel('F (pN)');
xlim([data.scaleMinTss data.scaleMaxTss]);
ylim([data.scaleMinF data.scaleMaxF]);

pause(0.5);


data.force_value_membrane=[];
data.position_value_membrane=[];

data.force_value_membrane=force_value;
data.position_value_membrane=position_value;
parameters_membrane;

function export_break_Callback(hObject, eventdata, handles)
break_memb_Callback(hObject, eventdata, handles);

global data
global positiveResult

position_force=[ data.position_value_membrane data.force_value_membrane];

export_txt_break(position_force)



function export_xy_superimpose_Callback(hObject, eventdata, handles)
global data
global positiveResult

tempData = [];

%Add Trace
indexCount = 1;
for ii = 1:positiveResult.nTraces
    
    iieffTrace=positiveResult.indexTrace(ii);       %Actual trace
    % check if traces must be removed
    if(data.removeTraces(iieffTrace) == 1);continue;end
    
    tempData.tracesRetract{indexCount, 1} = data.tracesRetract{iieffTrace,1} + data.translateLc(iieffTrace);
    tempData.tracesRetract{indexCount, 2} = data.tracesRetract{iieffTrace,2};
    
    indexCount = indexCount + 1;
end

tempData.nTraces = indexCount - 1;
export_Traces_append(tempData);
