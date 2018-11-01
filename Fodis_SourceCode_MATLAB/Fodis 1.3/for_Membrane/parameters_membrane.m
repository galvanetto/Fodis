function varargout = parameters_membrane(varargin)
% PARAMETERS_MEMBRANE MATLAB code for parameters_membrane.fig
%      PARAMETERS_MEMBRANE, by itself, creates a new PARAMETERS_MEMBRANE or raises the existing
%      singleton*.
%
%      H = PARAMETERS_MEMBRANE returns the handle to a new PARAMETERS_MEMBRANE or the handle to
%      the existing singleton*.
%
%      PARAMETERS_MEMBRANE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PARAMETERS_MEMBRANE.M with the given input arguments.
%
%      PARAMETERS_MEMBRANE('Property','Value',...) creates a new PARAMETERS_MEMBRANE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before parameters_membrane_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to parameters_membrane_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help parameters_membrane

% Last Modified by GUIDE v2.5 06-Apr-2018 01:09:56

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @parameters_membrane_OpeningFcn, ...
                   'gui_OutputFcn',  @parameters_membrane_OutputFcn, ...
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



function parameters_membrane_OpeningFcn(hObject, eventdata, handles, varargin)

update_prob(handles);
handles.output = hObject;

guidata(hObject, handles);

function varargout = parameters_membrane_OutputFcn(hObject, eventdata, handles) 

varargout{1} = handles.output;



function edit_A_Callback(hObject, eventdata, handles)
update_prob(handles)

function edit_A_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_K_Callback(hObject, eventdata, handles)
update_prob(handles)

function edit_K_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_v_Callback(hObject, eventdata, handles)
update_prob(handles)

function edit_v_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_R_Callback(hObject, eventdata, handles)
update_prob(handles)

function edit_R_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_S_Callback(hObject, eventdata, handles)
update_prob(handles)

function edit_S_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_G_Callback(hObject, eventdata, handles)
update_prob(handles)

function edit_G_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function update_prob(handles)

global data




hhm=findobj('Tag','mtag');

if ~isempty(hhm)
    figure(hhm);
    cla;
else
    pfig=figure;
    set(pfig,'Tag','mtag');  
end

hold on;

hhm=findobj('Tag','mtag');
figure(hhm)

HISTM=histogram(data.force_value_membrane * 1E12, 0:200:(max(data.force_value_membrane) * 1E12));


%here I use the untegral function for calculating the line tension and the
%surface energy


A = str2double (get(handles.edit_A,'String'));
K = str2double (get(handles.edit_K,'String'));
v = str2double (get(handles.edit_v,'String'))*1e-6;
R = str2double (get(handles.edit_R,'String'))*1e-9;
S = str2double (get(handles.edit_S,'String'));
G = str2double (get(handles.edit_G,'String'))*1e-12; %Line tension Gamma

kb = physconst('Boltzmann');
T=290;

Fs=2*pi*R*S;
c=(2*pi^2*G^2*R)/(T*kb);

fun=@(x) exp( - c./(x -Fs));

F=Fs:0.05e-9: max( [ max(data.force_value_membrane)   Fs*2]);

P=F;
for ii=1:length(F)
P(ii)=exp (-(A)/(K*v)* integral(fun,Fs+1e-10,F(ii))  );
end

dP=-diff(P);               %minus because i found the problem that the integral gives the right probability starting from F=+inf
dPrescaled=dP*max(HISTM.Values)/max(dP);
plot(F(1:end-1)*1e12,dPrescaled);
