function varargout = get_help_here(varargin)
% GET_HELP_HERE MATLAB code for get_help_here.fig
%      GET_HELP_HERE, by itself, creates a new GET_HELP_HERE or raises the existing
%      singleton*.
%
%      H = GET_HELP_HERE returns the handle to a new GET_HELP_HERE or the handle to
%      the existing singleton*.
%
%      GET_HELP_HERE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GET_HELP_HERE.M with the given input arguments.
%
%      GET_HELP_HERE('Property','Value',...) creates a new GET_HELP_HERE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before get_help_here_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to get_help_here_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help get_help_here

% Last Modified by GUIDE v2.5 09-Jun-2017 12:20:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @get_help_here_OpeningFcn, ...
                   'gui_OutputFcn',  @get_help_here_OutputFcn, ...
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


% --- Executes just before get_help_here is made visible.
function get_help_here_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to get_help_here (see VARARGIN)

% Choose default command line output for get_help_here
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes get_help_here wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = get_help_here_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



% hObject    handle to pushbutton_gotoweb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
