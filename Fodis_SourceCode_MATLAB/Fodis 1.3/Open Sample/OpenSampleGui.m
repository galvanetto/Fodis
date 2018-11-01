function varargout = OpenSampleGui(varargin)
% OPENSAMPLEGUI MATLAB code for OpenSampleGui.fig
%      OPENSAMPLEGUI, by itself, creates a new OPENSAMPLEGUI or raises the existing
%      singleton*.
%
%      H = OPENSAMPLEGUI returns the handle to a new OPENSAMPLEGUI or the handle to
%      the existing singleton*.
%
%      OPENSAMPLEGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in OPENSAMPLEGUI.M with the given input arguments.
%
%      OPENSAMPLEGUI('Property','Value',...) creates a new OPENSAMPLEGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before OpenSampleGui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to OpenSampleGui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help OpenSampleGui

% Last Modified by GUIDE v2.5 25-Nov-2016 14:41:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @OpenSampleGui_OpeningFcn, ...
                   'gui_OutputFcn',  @OpenSampleGui_OutputFcn, ...
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


% --- Executes just before OpenSampleGui is made visible.
function OpenSampleGui_OpeningFcn(hObject, eventdata, handles, varargin)
global temp

% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to OpenSampleGui (see VARARGIN)
temp.tracesExtend = {};
temp.tracesRetract = {};
% Choose default command line output for OpenSampleGui
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes OpenSampleGui wait for user response (see UIRESUME)


% --- Outputs from this function are returned to the command line.
function varargout = OpenSampleGui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global temp
% Get default command line output from handles structure
waitfor(handles.figure_opensample);

varargout{1} = temp.tracesExtend;
varargout{2} = temp.tracesRetract;



function editMaxSlopeDifference_Callback(hObject, eventdata, handles)

function editMaxSlopeDifference_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editMaxDistanceDrifting_Callback(hObject, eventdata, handles)

function editMaxDistanceDrifting_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editMaxCrossingDistance_Callback(hObject, eventdata, handles)

function editMaxCrossingDistance_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editThresholdVarExtendMotion_Callback(hObject, eventdata, handles)

function editThresholdVarExtendMotion_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editThresholdVarEndPoint_Callback(hObject, eventdata, handles)

function editThresholdVarEndPoint_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editDistanceEndPoint_Callback(hObject, eventdata, handles)

function editDistanceEndPoint_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editTipSampleSeparation_Callback(hObject, eventdata, handles)

function editTipSampleSeparation_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editWindowVar_Callback(hObject, eventdata, handles)

function editWindowVar_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function checkbox_enablefilt_Callback(hObject, eventdata, handles)
on=get(hObject,'Value');
if on
    set(handles.show_excluded,'Enable','on')
else
    set(handles.show_excluded,'Enable','off')
end

function show_excluded_Callback(hObject, eventdata, handles)

function pushbutton_selectFolder_Callback(hObject, eventdata, handles)
global data

intexstr={'.txt','.jpk-force','.txt','.spm','.txt'};   %add here if you add a mode of import
indexpop=get(handles.popupmenu_extension,'Value');
extsel=intexstr{indexpop};
% get panel_folder
folder = uigetdir(data.folder, 'Select the folder containing the sequence to be analyzed');
% if the user chooses "Cancel"
if (folder == 0)
    set(handles.text_folder,'String','NO FOLDER SELECTED')
    set(handles.panel_folder,'HighlightColor',[162 20 47]/255)
    set(handles.panel_folder,'ForegroundColor',[162 20 47]/255)
    set(handles.uipanel_nrtrace,'HighlightColor',[162 20 47]/255)
    set(handles.uipanel_nrtrace,'ForegroundColor',[162 20 47]/255)
    set(handles.text_nrfile,'String',['There are 0' extsel ' file in the folder selected'])
    set(handles.pushbutton_import,'Enable','off')
    return;
end
set(handles.text_folder,'String',folder)
data.folder=folder;
set(handles.panel_folder,'HighlightColor',[119 172 48]/255)
set(handles.panel_folder,'ForegroundColor',[119 172 48]/255)
popupmenu_extension_Callback(handles.popupmenu_extension,eventdata, handles)


function popupmenu_extension_Callback(hObject, eventdata, handles)
global data

indexPC=1;
intexstr={'.txt','.jpk-force','.txt','.spm','.txt'};   %add here if you add a mode of import
indexpop=get(hObject,'Value');
extsel=intexstr{indexpop};

% generate inputCommand
inputCommand = fullfile([num2str(data.folder), strcat('/*',extsel)]);
% get all files
files = dir(inputCommand);
% extract a column cell array with filenames (excluding foldernames)
files = {files.name};

if (indexpop==4) && ~isempty(data.folder)
    
    if ispc && ~isdeployed
        
        filesSecondChoice = dir(data.folder);
        filesSecondChoice = {filesSecondChoice.name};
        filesGood=zeros(1,length(filesSecondChoice));
        
        for ii=1:length(filesSecondChoice)
            
            [dummy1,dummy2,ext] = fileparts(filesSecondChoice{ii});
            numberOfExtDigits = sum(isstrprop(ext,'digit'));
            
            if numberOfExtDigits>=2
                filesGood(ii)=1;
            end
        end
        
        filesSecondChoice=filesSecondChoice(logical(filesGood));
        files=[filesSecondChoice,files];
        
    else
        indexPC=0;       
    end
end

nrTrace=length(files);
% check if the input is empty
if(isempty(files))
    set(handles.text_nrfile,'String',['There are 0' extsel ' file in the folder selected'])
    set(handles.uipanel_nrtrace,'HighlightColor',[162 20 47]/255)
    set(handles.uipanel_nrtrace,'ForegroundColor',[162 20 47]/255)
    set(handles.pushbutton_import,'Enable','off')
    
else
    set(handles.text_nrfile,'String',['There are ' num2str(nrTrace) ' ' extsel ' file in the folder selected'])
    set(handles.uipanel_nrtrace,'HighlightColor',[119 172 48]/255)
    set(handles.uipanel_nrtrace,'ForegroundColor',[119 172 48]/255)
    set(handles.pushbutton_import,'Enable','on')
end

if ~indexPC
    
    set(handles.text_nrfile,'String','Read Bruker file only supported in non-deployed versions in Windows OS')
    set(handles.uipanel_nrtrace,'HighlightColor',[162 20 47]/255)
    set(handles.uipanel_nrtrace,'ForegroundColor',[162 20 47]/255)
    set(handles.pushbutton_import,'Enable','off')
end



function popupmenu_extension_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pushbutton_import_Callback(hObject, eventdata, handles)
global data
global mainHandles
global temp

intexstr={'.txt','.jpk-force','.txt','.spm','.txt'};   %add here if you add a mode of import
indexpop=get(handles.popupmenu_extension,'Value');
filteron=get(handles.checkbox_enablefilt,'Value');
showexon=get(handles.show_excluded,'Value');

extsel=intexstr{indexpop};

addpath(genpath(data.folder));

% generate inputCommand
inputCommand = fullfile([num2str(data.folder), strcat('/*',extsel)]);
% get all files
files = dir(inputCommand);
% extract a column cell array with filenames (excluding foldernames)
files = {files.name};

if (indexpop==4)
    
    filesSecondChoice = dir(data.folder);
    filesSecondChoice = {filesSecondChoice.name};
    filesGood=zeros(1,length(filesSecondChoice));
    
    for ii=1:length(filesSecondChoice)
    
        [dummy1,dummy2,ext] = fileparts(filesSecondChoice{ii});
        numberOfExtDigits = sum(isstrprop(ext,'digit'));
        
        if numberOfExtDigits>=2
            filesGood(ii)=1;
        end
    end
    
    filesSecondChoice=filesSecondChoice(logical(filesGood));
    files=[filesSecondChoice,files];
end

% number of files
nFiles = length(files);

% preallocate traces
temp.tracesExtend = cell(nFiles, 2);
temp.tracesRetract = cell(nFiles, 2);
data.position =zeros(nFiles, 2);
temp.translateLc= zeros(nFiles,1);
% FileNames = cell(nFiles, 2);

% create waitbar
h = waitbar(0, 'Please wait...');
waitbarFactor = ceil(0.05 * nFiles);
% check waitbar factor
if(waitbarFactor == 0);waitbarFactor = 1;end

onFolderFile=zeros(1,nFiles);

% for each file
for ii = 1:1:nFiles
    try
        if indexpop==1              %.txt acquisition
            [temp.tracesExtend(ii,:),temp.tracesRetract(ii,:)] = readTxt(files{ii});
        elseif indexpop==2
            [temp.tracesExtend(ii,:),temp.tracesRetract(ii,:)] = readJPK(files{ii});
        elseif indexpop==3
            [temp.tracesExtend(ii,:),temp.tracesRetract(ii,:)] = readBrukerTxt(files{ii});               
        elseif indexpop==4
            [temp.tracesExtend(ii,:),temp.tracesRetract(ii,:)] = readBruker(files{ii});
        elseif indexpop==5
            [temp.tracesExtend(ii,:),temp.tracesRetract(ii,:),data.position(ii,:)] = readTxtExtend(files{ii}); 
        end
        onFolderFile(ii)=1;
    catch e
        disp(['Pass to the next File.' files{ii} ' not acquired']);
        continue;
    end
    
    %Filter Trace
    if filteron 
        [vote, ~, ~, ~, ~, ~]=classifyTrace(mainHandles,handles,temp,ii);
        
        %Exclude trace if the vote is negative
        if vote==-1
            temp.tracesExtendEX=temp.tracesExtend(ii,:);
            temp.tracesRetractEX=temp.tracesRetract(ii,:);
            temp.tracesExtend(ii,:)=[];
            temp.tracesRetract(ii,:)=[];
            
            disp(['Trace ' files{ii} ' is excluded cause filtering'])
            
            %Plot excluded trace
            if showexon
                figure(10);
                hold on
                plot(temp.tracesExtendEX{1,1}*1E9,-temp.tracesExtendEX{1,2} * 1E12, 'red');
                plot(temp.tracesRetractEX{1,1}*1E9,-temp.tracesRetractEX{1,2}* 1E12, 'blue');
                title('Excluded Traces')
                xlabel('tss (nm)');ylabel('F (pN)')
            end
        else
             disp(['Trace ' files{ii} ' is accepted'])
        end
    end
    % update waitbar
    if((mod(ii, waitbarFactor) == 0) || (ii == nFiles))
        waitbar(ii / nFiles, h);
        disp([num2str(ii * 100 / nFiles), '% loaded files: ', num2str(ii)]);
    end
end
try
    if indexpop==1
        data.acquisitionParameter=readAcquisitionParameter(files{ii});
    end
catch e
end

try
    if indexpop==5
        data.acquisitionParameter=readAcquisitionParameter(files{ii});
    end
catch e
end

temp.tracesExtend(all(cellfun('isempty',temp.tracesExtend),2),:) = [];
temp.tracesRetract(all(cellfun('isempty',temp.tracesRetract),2),:) = [];

% close waitbar
delete(h)
%Remove Path
rmpath(genpath(data.folder));

if sum(onFolderFile)<nFiles
    
       Mess = msgbox({['The import failes in ' num2str(nFiles- sum(onFolderFile)) ' files.'];['--------------------'];...
           ['Please check the Command Window for details'...
       ];['--------------------'];['While the problem persists, contact fodis.help@gimail.com']},'modal');
    
end


close(handles.figure_opensample);


function figure_opensample_CloseRequestFcn(hObject, eventdata, handles)
delete(hObject);
