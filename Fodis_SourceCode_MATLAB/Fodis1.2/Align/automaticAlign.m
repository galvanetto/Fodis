function varargout = automaticAlign(varargin)
% AUTOMATICALIGN MATLAB code for automaticAlign.fig
%      AUTOMATICALIGN, by itself, creates a new AUTOMATICALIGN or raises the existing
%      singleton*.
%
%      H = AUTOMATICALIGN returns the handle to a new AUTOMATICALIGN or the handle to
%      the existing singleton*.
%
%      AUTOMATICALIGN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in AUTOMATICALIGN.M with the given input arguments.
%
%      AUTOMATICALIGN('Property','Value',...) creates a new AUTOMATICALIGN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before automaticAlign_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to automaticAlign_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help automaticAlign

% Last Modified by GUIDE v2.5 11-Nov-2016 13:56:20

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @automaticAlign_OpeningFcn, ...
                   'gui_OutputFcn',  @automaticAlign_OutputFcn, ...
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


% --- Executes just before automaticAlign is made visible.
function automaticAlign_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to automaticAlign (see VARARGIN)
global positiveResult
% Choose default command line output for automaticAlign
handles.output = hObject;
set(handles.slider_algnmnt, 'Value', 1);
set(handles.slider_algnmnt, 'Min', 1);
set(handles.slider_algnmnt, 'Max', positiveResult.nTraces);
set(handles.slider_algnmnt, 'SliderStep', [1 1]./(positiveResult.nTraces-1));
showAlgnmntinfo(handles)
set(handles.text_slider,'string',['/' num2str(positiveResult.nTraces)])

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes automaticAlign wait for user response (see UIRESUME)
% uiwait(handles.figure_al);


% --- Outputs from this function are returned to the command line.
function varargout = automaticAlign_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function slider_algnmnt_Callback(hObject, eventdata, handles)
global positiveResult

indexTrace = get(hObject, 'Value');
if(indexTrace < 1);indexTrace = 1;end
if(indexTrace > positiveResult.nTraces)
    indexTrace = positiveResult.nTraces;
end

set(handles.edittracealgn, 'string', num2str(indexTrace));
showAlgnmntinfo(handles)


function slider_algnmnt_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function edittracealgn_Callback(hObject, eventdata, handles)
global positiveResult

% check value
indexTrace = round(str2double(get(hObject, 'String')));
if(indexTrace < 1);indexTrace = 1;end
if(indexTrace > positiveResult.nTraces)
    indexTrace = positiveResult.nTraces;
end
% set value
set(handles.slider_algnmnt, 'value', indexTrace);
set(hObject, 'string', num2str(indexTrace));

showAlgnmntinfo(handles)

function edittracealgn_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_iter_Callback(hObject, eventdata, handles)

iter=str2double(get(hObject,'string'));
if iter>20
    warndlg('Such a high number of iteration can determine a long computation time')
end

function edit_iter_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_sigm_Callback(hObject, eventdata, handles)
showAlgnmntinfo(handles)

function edit_sigm_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editStepBin_Callback(hObject, eventdata, handles)
showAlgnmntinfo(handles)

function editStepBin_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editMaxBin_Callback(hObject, eventdata, handles)
showAlgnmntinfo(handles)

function editMaxBin_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editCutPeak_Callback(hObject, eventdata, handles)
showAlgnmntinfo(handles)

function editCutPeak_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_minFalgn_Callback(hObject, eventdata, handles)
showAlgnmntinfo(handles)

function edit_minFalgn_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_maxFalgn_Callback(hObject, eventdata, handles)
showAlgnmntinfo(handles)

function edit_maxFalgn_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editstartX_Callback(hObject, eventdata, handles)
showAlgnmntinfo(handles)

function editstartX_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editEndX_Callback(hObject, eventdata, handles)
showAlgnmntinfo(handles)

function editEndX_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function pushbutton_skip_Callback(hObject, eventdata, handles)
global datalgn

if ~isempty(datalgn)
    automaticAlign_st2;
else
    warndlg('No align data found. You must align to proceed')
end

function push_align_Callback(hObject, eventdata, handles)

global data
global mainHandles
global positiveResult
global datalgn

%Get GUI info
stepbin=str2double(get(handles.editStepBin,'string'))*1E-9;
maxbin=str2double(get(handles.editMaxBin,'string'))*1E-9;
cutpeak=str2double(get(handles.editCutPeak,'string'));
minF=str2double(get(handles.edit_minFalgn,'string'))*1E-12;
maxF=str2double(get(handles.edit_maxFalgn,'string'))*1E-12;
editstartX=str2double(get(handles.editstartX,'string'))*1E-9;
editEndX=str2double(get(handles.editEndX,'string'))*1E-9;
nrit=str2double(get(handles.edit_iter,'string'));
flipflag=get(mainHandles.checkboxFlipTraces, 'value');
data.Alignment.sigm=str2double(get(handles.edit_sigm,'string'))*1E-9;
% Get saved data on groups

Selected=ismember(find(~data.removeTraces),positiveResult.indexTrace);
groups=data.TracesGroup(Selected);
traces=data.tracesRetract(Selected,:);
nrgroups=max(groups);

% Preallocation for interpolation
datalgn=cell(nrit,nrgroups);
data.Alignment.nrgroups=nrgroups;
data.Alignment.nrit=nrit;
data.Alignment.weight=[];

nrel=max(cellfun('length',traces(:,1)));
lengthX=abs(max([traces{:,1}])-min([traces{:,1}]));
data.Alignment.Xi=linspace(-lengthX,2*lengthX,3*nrel);

bins=0:stepbin:maxbin;
data.Alignment.newbins=-maxbin:stepbin:2*maxbin;
nrbins=length(bins)-1;
nrbinsint=length(data.Alignment.newbins);

maxlag=100;
err=2;
         
h = waitbar(0);

try

for ii=1:nrit
    set(h,'Name',['Iteration Nr ' num2str(ii) ' of ' num2str(nrit)])
    
    for ll=1:nrgroups
        waitbar(ll/nrgroups,h,['Computing Alignment of Group ' num2str(ll)])
        
        list=find(groups==ll);
        if isempty(list);continue;end
        X=traces(list,1);
        Y=traces(list,2);
        data.Alignment.weight=cat(2,data.Alignment.weight,length(list));
        %Preallocation Variables
        datalgn{ii,ll}.posbase=zeros(nrbins,length(list));
        datalgn{ii,ll}.hstgrmbase=zeros(nrbins,length(list));
        datalgn{ii,ll}.pos=zeros(nrbins,length(list));
        datalgn{ii,ll}.hstgrm=zeros(nrbins,length(list));
        datalgn{ii,ll}.hstgrmi=zeros(nrbinsint,length(list));
        datalgn{ii,ll}.refor=zeros(1,length(list));

        for kk=1:length(list)
            
            Xs=X{kk};
            Ys=Y{kk};
            if flipflag;Ys=-Ys;end
            
            %% Zero alignment
            [datalgn{ii,ll}.hstgrmbase(:,kk),datalgn{ii,ll}.posbase(:,kk),~,datalgn{ii,ll}.refor(kk)]=...
                Trace2HistCustom(Xs,Ys,stepbin,maxbin,cutpeak,minF,maxF);
            
            if isnan(datalgn{ii,ll}.refor(kk));datalgn{ii,ll}.refor(kk)=0;end
            
            Xs=Xs-datalgn{ii,ll}.refor(kk);
            [datalgn{ii,ll}.hstgrm(:,kk),datalgn{ii,ll}.pos(:,kk),~,datalgn{ii,ll}.ref(kk)]=...
                Trace2HistCustom(Xs,Ys,stepbin,maxbin,cutpeak,minF,maxF);
            
            %% Histogram selection: inbetween GUI two limit
           
            valid=(datalgn{ii,ll}.pos(:,kk)>=editstartX) & (datalgn{ii,ll}.pos(:,kk)<=editEndX);
            datalgn{ii,ll}.hstgrm(~valid,kk)=0;
            
            %% Interpolate histogram and curve
            
            datalgn{ii,ll}.hstgrmi(:,kk) = interp1(datalgn{ii,ll}.pos(:,kk),datalgn{ii,ll}.hstgrm(:,kk),data.Alignment.newbins);
            datalgn{ii,ll}.hstgrmi(isnan(datalgn{ii,ll}.hstgrmi))=0;
                        
            %Step necessary to interpolate a collection of points
            [Xord,index_ord]=sort(Xs,'ascend');
            Yord=Ys(index_ord);
            [Xordu,index_u]=unique(Xord);
            Yordu=Yord(index_u);
            
            datalgn{ii,ll}.Yi(:,kk)=interp1(Xordu,Yordu,data.Alignment.Xi);
            
        end
        
        [datalgn{ii,ll}.hstgrmalgn,datalgn{ii,ll}.Yalgn,datalgn{ii,ll}.mean_group,...
            datalgn{ii,ll}.ref]=alignfunc(data.Alignment.Xi,datalgn{ii,ll}.Yi,...
            data.Alignment.newbins,datalgn{ii,ll}.hstgrmi,data.Alignment.sigm,...
            datalgn{ii,ll}.ref,err,maxlag);
    end
end

catch ME
    
    disp(ME);
    
    d = dialog('Position',[300 300 400 200],'Name','Error when Importing Traces');

    txt = uicontrol('Parent',d,...
               'Style','text',...
               'Position',[20 80 360 100],...
               'String','The alignment is not working. Please check the User Guide or go to  https://github.com/nicolagalvanetto/Fodis/issues');

    btn = uicontrol('Parent',d,...
               'Position',[150 20 70 25],...
               'String','Close',...
               'Callback','delete(gcf)');
    
    beep
    delete(h);
    
end


delete(h)
automaticAlign_st2;
        

function showAlgnmntinfo(handles)
global data
global positiveResult
global mainHandles

indexTrace = round(get(handles.slider_algnmnt, 'value'));    %Slider Position
indexeffTrace=positiveResult.indexTrace(indexTrace);       %Actual trace

sigm=str2double(get(handles.edit_sigm,'string'))*1E-9;
flagFlip = get(mainHandles.checkboxFlipTraces, 'value');

axes(handles.axes_autalgn1)
cla;

% Get trace
[extendTipSampleSeparation,retractTipSampleSeparation,extendVDeflection,...
    retractVDeflection]= getTrace(indexeffTrace, data);

if flagFlip == 1;mirror=-1;else mirror=1;end %flip the signale

F = mirror*retractVDeflection;
%% Plot1
gaussx=-max(retractTipSampleSeparation):0.1e-9:max(retractTipSampleSeparation);
%Get Gauss
gaussy=gaussmf(gaussx,[sigm,0]);
%Plot trace and gaussian
plot(retractTipSampleSeparation*1E9,F*1E12,'k','linewidth',1.2);
hold on
h=area(gaussx*1E9,-60*gaussy);
h.FaceColor = [1 0 0 ];
alpha(0.25)
set(gca,'FontSize',7)
hold on 
plot([0,0],[data.scaleMinF data.scaleMaxF],'--b','linewidth',1.2)
% set axis label
title('Traces')
xlim([data.scaleMinTss data.scaleMaxTss]); xlabel('tss (nm)');
ylim([data.scaleMinF data.scaleMaxF]);     ylabel('F (pN)');

%% Plot2
axes(handles.axes_autalgn2)
cla;

% Reference to align to zero
x1=retractTipSampleSeparation;
x1 = x1((F<(-50*1e-12) & F>(-400*1e-12)));                   %condition

if isempty(x1)
    overzero=find(F1>0);
    zero=x1(overzero(1));
else
    zero=mean(x1);
end

stepbin=str2double(get(handles.editStepBin,'string'))*1E-9;
maxbin=str2double(get(handles.editMaxBin,'string'))*1E-9;
cutpeak=str2double(get(handles.editCutPeak,'string'));
minF=str2double(get(handles.edit_minFalgn,'string'))*1E-12;
maxF=str2double(get(handles.edit_maxFalgn,'string'))*1E-12;
editstartX=str2double(get(handles.editstartX,'string'));
editEndX=str2double(get(handles.editEndX,'string'));

[rep,binhist,bins,~]=Trace2HistCustom(retractTipSampleSeparation-zero,F,stepbin,maxbin,cutpeak,minF,maxF);
bar((binhist+stepbin)*1E9,rep,1,'FaceColor', [0.9 0 0], 'EdgeColor', 'none')

% set axis label
title('Alignment template feature')
xlim([-10 maxbin*1E9]); xlabel('Bin (nm)');
ylim([0 cutpeak+1]);     ylabel('Repetiton');
set(gca,'FontSize',7)

hold on
patch('XData',[editstartX editEndX editEndX editstartX],'YData',[0 0 cutpeak+1 cutpeak+1],'FaceColor',[0 0 1],'FaceAlpha',0.1,'EdgeColor','none')



function Untitled_1_Callback(hObject, eventdata, handles)
