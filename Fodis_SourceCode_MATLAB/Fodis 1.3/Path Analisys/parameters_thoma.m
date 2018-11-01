function varargout = parameters_thoma(varargin)
% PARAMETERS_THOMA MATLAB code for parameters_thoma.fig
%      PARAMETERS_THOMA, by itself, creates a new PARAMETERS_THOMA or raises the existing
%      singleton*.
%
%      H = PARAMETERS_THOMA returns the handle to a new PARAMETERS_THOMA or the handle to
%      the existing singleton*.
%
%      PARAMETERS_THOMA('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PARAMETERS_THOMA.M with the given input arguments.
%
%      PARAMETERS_THOMA('Property','Value',...) creates a new PARAMETERS_THOMA or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before parameters_thoma_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to parameters_thoma_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help parameters_thoma

% Last Modified by GUIDE v2.5 25-Oct-2017 12:24:23

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @parameters_thoma_OpeningFcn, ...
                   'gui_OutputFcn',  @parameters_thoma_OutputFcn, ...
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

function parameters_thoma_OpeningFcn(hObject, eventdata, handles, varargin)

changeappereance(handles)
handles.output = hObject;

guidata(hObject, handles);


function varargout = parameters_thoma_OutputFcn(hObject, eventdata, handles) 

varargout{1} = handles.output;



function editPointThoma_Callback(hObject, eventdata, handles)
changeappereance(handles)

function editPointThoma_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editLineThoma_Callback(hObject, eventdata, handles)
changeappereance(handles)

function editLineThoma_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function changeappereance(handles)

global data
global positiveResult

sizePoint = str2double (get(handles.editPointThoma,'String'));
sizeLine = str2double (get(handles.editLineThoma,'String'));

hhh=findobj('Tag','Ttag');

if ~isempty(hhh)
    figure(hhh);
    cla;
else
    pfig=figure;
    set(pfig,'Tag','Ttag');  
end

hold on;

[TracesGroup]=thoma1_plot(data.GMreduced,sizePoint,sizeLine);
Selected=ismember(find(~data.removeTraces),positiveResult.indexTrace);
data.TracesGroup(Selected)=TracesGroup;
