function varargout = manualAlign(varargin)
% MANUALALIGN MATLAB code for manualAlign.fig
%      MANUALALIGN, by itself, creates a new MANUALALIGN or raises the existing
%      singleton*.
%
%      H = MANUALALIGN returns the handle to a new MANUALALIGN or the handle to
%      the existing singleton*.
%
%      MANUALALIGN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MANUALALIGN.M with the given input arguments.
%
%      MANUALALIGN('Property','Value',...) creates a new MANUALALIGN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before manualAlign_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to manualAlign_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help manualAlign

% Last Modified by GUIDE v2.5 28-Nov-2016 11:04:24

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @manualAlign_OpeningFcn, ...
                   'gui_OutputFcn',  @manualAlign_OutputFcn, ...
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


% --- Executes just before manualAlign is made visible.
function manualAlign_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to manualAlign (see VARARGIN)
global positiveResult
global data
% Choose default command line output for manualAlign
handles.output = hObject;

% set slider traces
set(handles.sliderTraces, 'Value', 1);
set(handles.sliderTraces, 'Min', 1);
set(handles.sliderTraces, 'Max', positiveResult.nTraces);
set(handles.sliderTraces, 'SliderStep', [1 1] / (positiveResult.nTraces - 1));
actualTrace=find(positiveResult.indexTrace==data.CurrAlgnTr);
if ~isempty(actualTrace);set(handles.sliderTraces, 'Value', actualTrace);
else set(handles.sliderTraces, 'Value', 1);end

% get params
[minTranslation,maxTranslation,binTranslation] = getParams(handles);

% set slider translation
set(handles.sliderTranslation, 'Value', 0);
set(handles.sliderTranslation, 'Min', minTranslation);
set(handles.sliderTranslation, 'Max', maxTranslation);
set(handles.sliderTranslation, 'SliderStep', [1 1] / length(binTranslation));

set(handles.editOffset,'string',num2str(data.offset));
set(handles.editReference,'string',num2str(data.Reference));

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes manualAlign wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% set(gcf, 'renderer', 'ZBuffer');


function downFcn(hObject, eventdata)
% down mouse function

global globalHandles
global mainHandles
global positiveResult
global lock
global startX
global indexeffTrace

if(lock == 0)

    % set lock
    lock = 1;
    
    % get position
    pos = get(globalHandles.axesMain, 'CurrentPoint');
    startX = pos(1);
    
    % get index trace
    indexTrace = round(get(globalHandles.sliderTraces, 'value'));
    indexeffTrace=positiveResult.indexTrace(indexTrace);          %Actual Trace

    %Change Update color in FaceTheWind main function because it need update
    changeupdatecolor(mainHandles,0)
end


function motionFcn(hObject, eventdata)
% motion mouse function

global data
global globalHandles
global lock
global lockMotion
global startX
global indexeffTrace

% check locks
if(lock ~= 0 && lockMotion == 0)

    % set lock motion
    lockMotion = 1;
        
    % set translation
    pos = get(globalHandles.axesMain, 'CurrentPoint');
    translate = pos(1) - startX;
    data.translateLc(indexeffTrace) = translate * 1E-9;

    % show traces
    showTraces(globalHandles);
    lockMotion = 0;

end


function upFcn(hObject, eventdata)
% up mouse function

global data
global globalHandles
global lock
global startX
global endX
global indexeffTrace

% check lock
if(lock ~= 0)
    
    % set translation
    pos = get(globalHandles.axesMain, 'CurrentPoint');
    endX=pos(1);
   
    translate = endX - startX;
    data.translateLc(indexeffTrace) = translate * 1E-9;
    
    if endX==startX
        data.translateLc(indexeffTrace)=data.offset* 1E-9;
    end

    % show traces
    showTraces(globalHandles);

    % clear locks
    lock = 0;
    
end


function [minTranslation, maxTranslation, binTranslation] = getParams(handles)

% Get parameters

maxTranslation = 150;
minTranslation = -150;
bin = str2double(get(handles.editBinTranslation, 'string'));
binTranslation = minTranslation:bin:maxTranslation;

function showTraces(handles)

global data
global mainHandles
global positiveResult

if(positiveResult.nTraces <= 0);return;end
[minTranslation,maxTranslation,~] = getParams(handles);

% get flag flip
flagFlip = get(mainHandles.checkboxFlipTraces, 'value');
% get size marker
sizeMarker = str2double(get(handles.editSizeMarker, 'string')) * 3;
% get index view   (Lc or Force)
indexView = get(handles.popupIndexView, 'value');
% get current index (trace to show)
indexTrace = round(get(handles.sliderTraces, 'value'));       %Index Slider
indexeffTrace=positiveResult.indexTrace(indexTrace);          %Actual Trace

% get translate
translate = data.translateLc(indexeffTrace);
%get reference index
indexReference=str2double(get(handles.editReference, 'string'));
data.Reference=indexReference;
data.CurrAlgnTr=indexeffTrace;

% set frame translation
if (translate*1E9<=maxTranslation) && (translate*1E9>=minTranslation)
    set(handles.sliderTranslation, 'value', translate * 1E9);
elseif (translate*1E9<=minTranslation);set(handles.sliderTranslation,'value',minTranslation);
elseif (translate*1E9>=maxTranslation);set(handles.sliderTranslation,'value',maxTranslation);
end
set(handles.textFrame, 'string', ['Frame ' num2str(indexTrace) '/' num2str(positiveResult.nTraces)]);
set(handles.textTranslation, 'string', ['Translate ' num2str(translate * 1E9) ' (nm)']);
% set remove checkbox
set(handles.checkboxRemove, 'value', data.removeTraces(indexeffTrace));
% set save on
set(handles.checkboxSaveOnScreen, 'value', data.saveOnScreen(indexeffTrace));
% set text for slider
nValid=sum(~data.removeTraces);
set(handles.textEditManualSelected, 'string', ['selected manually '...
    num2str(nValid) '/' num2str(positiveResult.nTraces)]);

% check grid
if(get(handles.checkboxGrid, 'value') == 1);grid on;
else grid off; end

cla;
hold on
% set colors
colorReference = [0, 0.8, 0.8];
colorValid = [1, 0.5, 0.5];
colorCurrent = [0.9, 0.9, 0];

% get Lc parameters
[tssMin, tssMax, FMin, FMax, xBin, binSize, ~, ~,zerosTempMax, LcMin,...
    LcMax, maxTssOverLc, windowAvgLc, thresholdHist,~, ~, ~, ~, ~,...
    persistenceLength] = getLcParameters(mainHandles);

% plot current trace
alltrace=1:1:positiveResult.nTraces;
iieffTrace=positiveResult.indexTrace(alltrace);

% get Translate
translate = data.translateLc(iieffTrace);

refcond=find(alltrace==indexReference & ~(alltrace==indexTrace));
valcond=find(data.saveOnScreen(iieffTrace)==1 & ~(alltrace==indexTrace) & indexTrace~=indexReference);
currentcond=find(alltrace==indexTrace);

LcTracestoView=str2double(strsplit(get(handles.edit_Lctoview, 'string'),',')); 
rgb=distinguishable_colors(length(LcTracestoView) + 1, [1 1 1; 0 0 0; 1 0 0; [0 1 0]]);

switch indexView
    case 1
        %Plot KEEPONSCREEN (valid)
        for ll=1:length(valcond)
            [~, tss, ~, F, ~]= getTrace(iieffTrace(valcond(ll)), data); %get traces
            if flagFlip == 1;F_temp = -F;else F_temp = F;end      %Flip
            %Plot
            plot((tss + translate(valcond(ll))) * 1E9, F_temp * 1E12, 'o',...
                'MarkerSize', sizeMarker, 'color', colorValid);
        end
        %Plot REFERENCE
        if ~isempty(refcond)
            [~, tss, ~, F, ~]= getTrace(iieffTrace(refcond), data);    % get traces
            if flagFlip == 1;F_temp = -F;else F_temp = F;end      %Flip
            %Plot
            plot((tss + translate(refcond)) * 1E9, F_temp * 1E12, 'o',...
                'MarkerSize', sizeMarker, 'color', colorReference);
        end
        %Plot CURRENT
        [~, tss, ~, F, ~]= getTrace(iieffTrace(currentcond), data);    % get traces
        if flagFlip == 1;F_temp = -F;else F_temp = F;end          %Flip
        %Plot
        plot((tss + translate(currentcond)) * 1E9, F_temp * 1E12, 'o',...
            'MarkerSize', sizeMarker, 'color', colorCurrent);
        
        plotWLCFit(LcTracestoView, sizeMarker/5, flagFlip, persistenceLength,rgb)
    case 2
        %Plot KEEPONSCREEN (valid)
        for ll=1:length(valcond)
            [~, tss, ~, F, ~]= getTrace(iieffTrace(valcond(ll)), data); %get traces
            [Lc_temp,Fc_temp,~,~,~,~]=getContourLength((tss + translate(valcond(ll))), -F,...
                tssMin, tssMax, FMin,FMax, LcMin, LcMax, maxTssOverLc, xBin,...
                binSize, zerosTempMax,0, windowAvgLc, thresholdHist, persistenceLength);
            %Plot
            plot(Lc_temp * 1E9, Fc_temp * 1E12, 'o',...
                'MarkerSize', sizeMarker, 'color', colorValid);
        end
        
        %Plot REFERENCE
        if ~isempty(refcond)
            [~, tss, ~, F, ~]= getTrace(iieffTrace(refcond), data);    % get traces
            [Lc_temp,Fc_temp,~,~,~,~]=getContourLength((tss + translate(refcond)), -F,...
                tssMin, tssMax, FMin,FMax, LcMin, LcMax, maxTssOverLc, xBin,...
                binSize, zerosTempMax,0, windowAvgLc, thresholdHist, persistenceLength);
            %Plot
            plot(Lc_temp * 1E9, Fc_temp * 1E12, 'o',...
                'MarkerSize', sizeMarker, 'color', colorReference);
        end
        %Plot CURRENT
        [~, tss, ~, F, ~]= getTrace(iieffTrace(currentcond), data);    % get traces
        [Lc_temp,Fc_temp,~,~,~,~]=getContourLength((tss + translate(currentcond)), -F,...
            tssMin, tssMax, FMin,FMax, LcMin, LcMax, maxTssOverLc, xBin,...
            binSize, zerosTempMax,0, windowAvgLc, thresholdHist, persistenceLength);
        %Plot
        plot(Lc_temp * 1E9, Fc_temp * 1E12, 'o',...
            'MarkerSize', sizeMarker, 'color', colorCurrent);
        
        yax=get(handles.axesMain,'ylim');
        plotLcVL(get(handles.edit_Lctoview,'string'),sizeMarker/3,yax)
        
end

TraceRemoved=data.removeTraces(positiveResult.indexTrace);
% plot valid trace
stringSelectedTraces =1:1:positiveResult.nTraces;
stringSelectedTraces=stringSelectedTraces(~TraceRemoved);
allOneString = sprintf('%.0f,' , stringSelectedTraces);  %string conversion
allOneString = allOneString(1:end-1); %remove the comma
% show selection
set(handles.editSelectedTraces, 'string', allOneString);

if indexView==1
    % set axis label
    title('Traces')
    xlim([data.scaleMinTss data.scaleMaxTss]); xlabel('tss (nm)');
    ylim([data.scaleMinF data.scaleMaxF]);     ylabel('F (pN)');
else
    % set axis label
    title('Lc')
    xlim([data.scaleMinTss data.scaleMaxTss]); xlabel('Lc (nm)');
    ylim([data.scaleMinF data.scaleMaxF]);     ylabel('F (pN)');
end
plot(xlim, [0 0],'k:');
plot([0 0],ylim, 'k:');
set(gca, 'xtickmode', 'auto');
set(gca, 'ytickmode', 'auto');


% --- Outputs from this function are returned to the command line.
function varargout = manualAlign_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
global positiveResult
global globalHandles;

if(positiveResult.nTraces <= 0);return;end
globalHandles = handles;

axes(handles.axesMain);
hndFigure = get(handles.axesMain, 'parent');
set(hndFigure, 'WindowButtonUpFcn', [], 'WindowButtonMotionFcn', [], 'WindowButtonDownFcn', []);
showTraces(handles);
 
set(gcf, 'KeyPressFcn', @keypress_callback);
checkboxMouseAligned_Callback(handles.checkboxMouseAligned, eventdata, handles)


function keypress_callback(hObject, eventdata)

global globalHandles
global positiveResult
global mainHandles
global data

handles = globalHandles;
nTraces = positiveResult.nTraces;

% get current index
indexTrace = round(get(handles.sliderTraces, 'value'));       %Index Slider
indexeffTrace=positiveResult.indexTrace(indexTrace);          %Actual Trace
set(handles.sliderTraces, 'value', indexTrace);

modifier = eventdata.Modifier;
key = eventdata.Key;

if(strcmp(modifier, key) ~= 1);return;end

switch(key)
    case 'leftarrow' %Move Frame Left
        if(indexTrace > 1)
            set(handles.sliderTraces, 'value', indexTrace - 1);
            sliderTraces_Callback(handles.sliderTraces, eventdata, handles);
        end       
    case 'rightarrow' %Move Frame Right
        if(indexTrace < nTraces)
            set(handles.sliderTraces, 'value', indexTrace + 1);
            sliderTraces_Callback(handles.sliderTraces, eventdata, handles);
        end        
    case 'uparrow' %Move Translation Right
        [minTranslation,maxTranslation,~] = getParams(handles);
        % get translate
        translate = 1E9*data.translateLc(indexeffTrace);
        bintranslation=str2double(get(handles.editBinTranslation,'String'));
        data.translateLc(indexeffTrace) = (translate+bintranslation) * 1E-9;
        if ((translate+bintranslation)<=maxTranslation) &&...
                ((translate+bintranslation)>=minTranslation)
            set(handles.sliderTranslation, 'value',(translate+bintranslation) * 1E-9);
        end
        %Change Update color in FaceTheWind main function because it need update
        changeupdatecolor(mainHandles,0)
        showTraces(handles)
    case 'downarrow' %Move Translation left
        [minTranslation,maxTranslation,~] = getParams(handles);
        translate = 1E9*data.translateLc(indexeffTrace);
        bintranslation=str2double(get(handles.editBinTranslation,'String'));
        data.translateLc(indexeffTrace) = (translate-bintranslation) * 1E-9;
        if ((translate-bintranslation)<=maxTranslation) && ...
                ((translate-bintranslation)>=minTranslation)
            set(handles.sliderTranslation, 'value',(translate-bintranslation) * 1E-9);
        end
        %Change Update color in FaceTheWind main function because it need update
        changeupdatecolor(mainHandles,0)
        showTraces(handles)        
    case 'r'
        if(get(handles.checkboxRemove, 'value') == 0)
            set(handles.checkboxRemove, 'value', 1);
        else
            set(handles.checkboxRemove, 'value', 0);
        end
        checkboxRemove_Callback(handles.checkboxRemove, eventdata, handles);       
    case 's'
        if(get(handles.checkboxSaveOnScreen, 'value') == 0)
            set(handles.checkboxSaveOnScreen, 'value', 1);
        else
            set(handles.checkboxSaveOnScreen, 'value', 0);
        end
        checkboxSaveOnScreen_Callback(handles.checkboxSaveOnScreen, eventdata, handles);       
    case 'g'
        if(get(handles.checkboxGrid, 'value') == 0)
            set(handles.checkboxGrid, 'value', 1);
        else
            set(handles.checkboxGrid, 'value', 0);
        end
        checkboxGrid_Callback(handles.checkboxGrid, eventdata, handles);      
end


function sliderTraces_Callback(hObject, eventdata, handles)

global data
global positiveResult

% get current index
indexTrace = round(get(handles.sliderTraces, 'value'));       %Index Slider
indexeffTrace=positiveResult.indexTrace(indexTrace);          %Actual Trace

[minTranslation,maxTranslation,~] = getParams(handles);
% get translate
translate = data.translateLc(indexeffTrace);
% set slider translation
if ((translate)<=maxTranslation) && ((translate)>=minTranslation)
    set(handles.sliderTranslation, 'value', translate * 1E9);
end

showTraces(handles);

function sliderTraces_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function sliderTranslation_Callback(hObject, eventdata, handles)

global data
global positiveResult

indexTrace = round(get(handles.sliderTraces, 'value'));       %Index Slider
indexeffTrace=positiveResult.indexTrace(indexTrace);          %Actual Trace

translate = get(handles.sliderTranslation, 'value');
data.translateLc(indexeffTrace) = translate * 1E-9;

showTraces(handles);

function sliderTranslation_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

%% VIEW

function checkboxGrid_Callback(hObject, eventdata, handles)
showTraces(handles);


function popupIndexView_Callback(hObject, eventdata, handles)

showTraces(handles);

function popupIndexView_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editSizeMarker_Callback(hObject, eventdata, handles)
showTraces(handles);

function editSizeMarker_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_Lctoview_Callback(hObject, eventdata, handles)
showTraces(handles)
function edit_Lctoview_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% SELECT

function checkboxRemove_Callback(hObject, eventdata, handles)

global data;
global positiveResult

% remove trace
indexTrace = round(get(handles.sliderTraces, 'value'));        %Index Slider
indexeffTrace=positiveResult.indexTrace(indexTrace);           %Actual trace

data.removeTraces(indexeffTrace) = get(handles.checkboxRemove, 'value');

if(get(handles.checkboxRemove, 'value') == 1)
    set(handles.checkboxSaveOnScreen, 'value', 0);
    data.saveOnScreen(indexeffTrace) = 0;
end

showTraces(handles);

function editSelectedTraces_Callback(hObject, eventdata, handles)

global data
global positiveResult
global mainHandles

% get removed traces and convert in vector
selections = get(handles.editSelectedTraces, 'string');
selections = textscan(selections, '%s', 'delimiter', ',');
selections = selections{1};
selections = str2double(selections);
% connect checkbox remove with list
alltraces= 1:1:positiveResult.nTraces;
logsel=ismember(alltraces,selections);
logseleffok=positiveResult.indexTrace(logsel);
logseleffrem=positiveResult.indexTrace(~logsel);

data.removeTraces(logseleffok) = 0;  
data.removeTraces(logseleffrem) = 1;  
 
%FdW needs update (red color)
changeupdatecolor(mainHandles,0)           
set(mainHandles.editSelectedTraces, 'string', get(handles.editSelectedTraces, 'string'));

showTraces(handles);

function editSelectedTraces_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%% ALIGN

function editReference_Callback(hObject, eventdata, handles)

global data;
data.indexReference = str2double(get(handles.editReference, 'string'));
showTraces(handles);

function editReference_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editBinTranslation_Callback(hObject, eventdata, handles)
set(handles.sliderTranslation, 'value', 0);
showTraces(handles);

function editBinTranslation_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editOffset_Callback(hObject, eventdata, handles)

global data;
global mainHandles

% set offset
newOffset = str2double(get(handles.editOffset, 'string'));
offset = newOffset - data.offset;
data.offset = newOffset;

% update offset
for ii = 1:1:length(data.translateLc)  
    data.translateLc(ii) = data.translateLc(ii) + offset * 1E-9;
end

%FdW needs update (red color)
changeupdatecolor(mainHandles,0)             
set(mainHandles.editOffset, 'string', get(handles.editOffset, 'string'));

showTraces(handles);

function editOffset_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function checkboxSaveOnScreen_Callback(hObject, eventdata, handles)

global data
global positiveResult

% remove trace
indexTrace = round(get(handles.sliderTraces, 'value'));
indexeffTrace=positiveResult.indexTrace(indexTrace);          %Actual trace

data.saveOnScreen(indexeffTrace)=get(handles.checkboxSaveOnScreen,'value');
showTraces(handles);


function checkboxMouseAligned_Callback(hObject, eventdata, handles)

global lock;
global lockMotion;

if(get(hObject, 'value') == 1)
    lock = 0;
    lockMotion = 0;
    
    % axes(handles.axesMain);
    hndFigure = get(handles.axesMain, 'parent');
    set(hndFigure, 'WindowButtonUpFcn', @upFcn, 'WindowButtonMotionFcn', @motionFcn, 'WindowButtonDownFcn', @downFcn);
else
    lock = 1;
    lockMotion = 1;
    
    % axes(handles.axesMain);
    hndFigure = get(handles.axesMain, 'parent');
    set(hndFigure, 'WindowButtonUpFcn', [], 'WindowButtonMotionFcn', [], 'WindowButtonDownFcn', []);    
end



%% MENU

function menuClearRemove_Callback(hObject, eventdata, handles)

global data

data.removeTraces = zeros(1, data.nTraces);
showTraces(handles);

function menuClearSaveOnScreen_Callback(hObject, eventdata, handles)

global data

data.saveOnScreen = zeros(1, data.nTraces);

showTraces(handles);


function menuClearAlign_Callback(hObject, eventdata, handles)

global data
global mainHandles

data.offset = 0;
set(handles.editOffset, 'string', '0');

data.translateLc = zeros(1, data.nTraces);
data.removeTraces = zeros(1, data.nTraces);

changeupdatecolor(mainHandles,0)             %FdW needs update (red color)
showTraces(handles);


function menuClearAll_Callback(hObject, eventdata, handles)

global data;
global mainHandles

data.offset = 0;
set(handles.editOffset, 'string', '0');

menuClearAlign_Callback(hObject, eventdata, handles);
menuClearRemove_Callback(hObject, eventdata, handles);
menuClearReference_Callback(hObject, eventdata, handles);
menuClearSaveOnScreen_Callback(hObject, eventdata, handles);

changeupdatecolor(mainHandles,0)             %FdW needs update (red color)

showTraces(handles);


function menuExportPlot_Callback(hObject, eventdata, handles)
figure;
showTraces(handles);


function menuall_Callback(hObject, eventdata, handles)
