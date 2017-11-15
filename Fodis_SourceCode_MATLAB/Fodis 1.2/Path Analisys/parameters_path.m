function varargout = parameters_path(varargin)
% PARAMETERS_PATH MATLAB code for parameters_path.fig
%      PARAMETERS_PATH, by itself, creates a new PARAMETERS_PATH or raises the existing
%      singleton*.
%
%      H = PARAMETERS_PATH returns the handle to a new PARAMETERS_PATH or the handle to
%      the existing singleton*.
%
%      PARAMETERS_PATH('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PARAMETERS_PATH.M with the given input arguments.
%
%      PARAMETERS_PATH('Property','Value',...) creates a new PARAMETERS_PATH or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before parameters_path_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to parameters_path_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help parameters_path

% Last Modified by GUIDE v2.5 16-Nov-2016 14:18:10

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @parameters_path_OpeningFcn, ...
                   'gui_OutputFcn',  @parameters_path_OutputFcn, ...
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

function parameters_path_OpeningFcn(hObject, eventdata, handles, varargin)

changeappereance(handles)
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);


function varargout = parameters_path_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


function editPointSize_Callback(hObject, eventdata, handles)
changeappereance(handles)

function editPointSize_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editLineSize_Callback(hObject, eventdata, handles)
changeappereance(handles)

function editLineSize_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function changeappereance(handles)

global data
global positiveResult

sizePoint = str2double (get(handles.editPointSize,'String'));
sizeLine = str2double (get(handles.editLineSize,'String'));

hh=findobj('Tag','ptag');

if ~isempty(hh)
    figure(hh);
    cla;
else
    pfig=figure;
    set(pfig,'Tag','ptag');  
end

hold on;

[TracesGroup]=path_plot(data.GMreduced,sizePoint,sizeLine);
Selected=ismember(find(~data.removeTraces),positiveResult.indexTrace);
data.TracesGroup(Selected)=TracesGroup;
