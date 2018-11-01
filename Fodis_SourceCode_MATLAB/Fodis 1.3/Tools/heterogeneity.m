function varargout = heterogeneity(varargin)
% HETEROGENEITY MATLAB code for heterogeneity.fig
%      HETEROGENEITY, by itself, creates a new HETEROGENEITY or raises the existing
%      singleton*.
%
%      H = HETEROGENEITY returns the handle to a new HETEROGENEITY or the handle to
%      the existing singleton*.
%
%      HETEROGENEITY('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in HETEROGENEITY.M with the given input arguments.
%
%      HETEROGENEITY('Property','Value',...) creates a new HETEROGENEITY or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before heterogeneity_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to heterogeneity_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help heterogeneity

% Last Modified by GUIDE v2.5 04-Jul-2017 17:11:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @heterogeneity_OpeningFcn, ...
                   'gui_OutputFcn',  @heterogeneity_OutputFcn, ...
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


% --- Executes just before heterogeneity is made visible.
function heterogeneity_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to heterogeneity (see VARARGIN)

% Choose default command line output for heterogeneity
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes heterogeneity wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = heterogeneity_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function editpulling_Callback(hObject, eventdata, handles)
global data
data.pullingspeed=str2double( get(handles.editpulling, 'string')  );

figure('Position',[300,100,400,300]);

f=data.LcFcROI(:, 2);
fmin=min(f);
fmax=max(f);

fbin= fmin: 6*(fmax-fmin)/length(f) :fmax;

for ii=1:length(fbin)
sigma(ii)=size( find(f>fbin(ii)), 1)/length(f);
end

%pulling velocity (m/s)
v=data.pullingspeed*1e-9;
%spring constant (N/m)
k=data.springk;

semilogy(fbin*1e12,-v*k*log(sigma)*1e12,'o');


title({['\Omega function (v=', num2str(v*1e9), ' nm/s, k=', num2str(k),'N/m)'];'(Hinczewski et al., PNAS, 2016)'});
xlabel('Force [pN]');
ylabel('\Omega r (F) [pN/s]');


% --- Executes during object creation, after setting all properties.
function editpulling_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editpulling (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editspring_Callback(hObject, eventdata, handles)
global data
data.springk=str2double( get(handles.editspring, 'string')  );

figure('Position',[300,100,400,300]);

f=data.LcFcROI(:, 2);
fmin=min(f);
fmax=max(f);

fbin= fmin: 6*(fmax-fmin)/length(f) :fmax;

for ii=1:length(fbin)
sigma(ii)=size( find(f>fbin(ii)), 1)/length(f);
end

%pulling velocity (m/s)
v=data.pullingspeed*1e-9;
%spring constant (N/m)
k=data.springk;

semilogy(fbin*1e12,-v*k*log(sigma)*1e12,'o');


title({['\Omega function (v=', num2str(v*1e9), ' nm/s, k=', num2str(k),'N/m)'];'(Hinczewski et al., PNAS, 2016)'});
xlabel('Force [pN]');
ylabel('\Omega r (F) [pN/s]');


% --- Executes during object creation, after setting all properties.
function editspring_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editspring (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
