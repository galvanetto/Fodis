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

% Last Modified by GUIDE v2.5 14-Nov-2017 19:40:28

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
global data
% Choose default command line output for automaticAlign
handles.output = hObject;

Selected=find(~data.removeTraces);
SelinValid=ismember(find(~data.removeTraces),positiveResult.indexTrace);
nTraces=length(Selected(SelinValid));

set(handles.slider_algnmnt, 'Value', 1);
set(handles.slider_algnmnt, 'Min', 1);
set(handles.slider_algnmnt, 'Max', nTraces);
set(handles.slider_algnmnt, 'SliderStep', [1 1]./nTraces);
set(handles.text_slider,'string',['/' num2str(nTraces)])

showAlgnmntinfo(handles)

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
global data

Selected=find(~data.removeTraces);
SelinValid=ismember(find(~data.removeTraces),positiveResult.indexTrace);
nTraces=length(Selected(SelinValid));


indexTrace = get(hObject, 'Value');
if(indexTrace < 1);indexTrace = 1;end
if(indexTrace > nTraces)
    indexTrace = nTraces;
end

set(handles.edittracealgn, 'string', num2str(round(indexTrace)));
showAlgnmntinfo(handles)


function slider_algnmnt_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function edittracealgn_Callback(hObject, eventdata, handles)
global positiveResult
global data

Selected=find(~data.removeTraces);
SelinValid=ismember(find(~data.removeTraces),positiveResult.indexTrace);
nTraces=length(Selected(SelinValid));

indexTrace = round(str2double(get(hObject, 'String')));
if(indexTrace < 1);indexTrace = 1;end
if(indexTrace > nTraces)
    indexTrace = nTraces;
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

function checkbox_Gaussian_Callback(hObject, eventdata, handles)
on=get(hObject,'Value');
if on
    set(handles.edit_sigm,'Enable','on')
    
else
     set(handles.edit_sigm,'Enable','off')
end

showAlgnmntinfo(handles)

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

function align_singleTrace_Callback(hObject, eventdata, handles)
%% Align to reference computed as mean of reference of single group
global data
global mainHandles
global positiveResult

%Get GUI info
stepbin=str2double(get(handles.editStepBin,'string'))*1E-9;
maxbin=str2double(get(handles.editMaxBin,'string'))*1E-9;
cutpeak=str2double(get(handles.editCutPeak,'string'));
minF=str2double(get(handles.edit_minFalgn,'string'))*1E-12;
maxF=str2double(get(handles.edit_maxFalgn,'string'))*1E-12;
editstartX=str2double(get(handles.editstartX,'string'))*1E-9;
editEndX=str2double(get(handles.editEndX,'string'))*1E-9;
flipflag=get(mainHandles.checkboxFlipTraces, 'value');
flagGaussian=get(handles.checkbox_Gaussian, 'value');                      %Flag to Use/Print the gaussian

if flagGaussian
    data.Alignment.sigm=str2double(get(handles.edit_sigm,'string'))*1E-9;
else
    data.Alignment.sigm=0;
end

% Get saved data on groups
Selected=find(~data.removeTraces);
SelinValid=ismember(find(~data.removeTraces),positiveResult.indexTrace);
Selected=Selected(SelinValid);

traces=data.tracesRetract(Selected,:);
% Preallocation for interpolation

nrel=max(cellfun('length',traces(:,1)));
lengthX=abs(max([traces{:,1}])-min([traces{:,1}]));                        %Distance between the maximum of all traces and the minimum of all traces
data.Alignment.Xi=linspace(-lengthX,2*lengthX,3*nrel);

bins=0:stepbin:maxbin;
data.Alignment.newbins=-maxbin:stepbin:2*maxbin;
nrbins=length(bins)-1;
nrbinsint=length(data.Alignment.newbins);
unitaryspacing=stepbin;                                      %Bin of the histogram

maxlag=100;
err=2;
 
%Preallocation Variables
dataSingleAlign.posbase=zeros(nrbins,size(traces,1));
dataSingleAlign.hstgrmbase=zeros(nrbins,size(traces,1));
dataSingleAlign.pos=zeros(nrbins,size(traces,1));
dataSingleAlign.hstgrm=zeros(nrbins,size(traces,1));
dataSingleAlign.hstgrmi=zeros(nrbinsint,size(traces,1));
dataSingleAlign.refor=zeros(1,size(traces,1));
  
X=traces(:,1);                                                  %%Cell array with all the X of the traces of ll group
Y=traces(:,2);                                                  %%Cell array with all the Y of the traces of ll group

h = waitbar(0);

for kk=1:size(traces,1)                                                    %Iterate for each trace of the group
    
    set(h,'Name',['Align Trace ' num2str(kk) ' of ' num2str(size(traces,1))])
    waitbar(kk/size(traces,1),h)

    Xs=X{kk};                                                              %X value of the trace
    Ys=Y{kk};                                                              %Y trace of the group
    if flipflag;Ys=-Ys;end
    
    [dataSingleAlign.hstgrmbase(:,kk),dataSingleAlign.posbase(:,kk),...
        ~,dataSingleAlign.refor(kk)]= Trace2HistCustom...                  %Evaluate the histogram of each Trace and
        (Xs,Ys,stepbin,maxbin,cutpeak,minF,maxF);                          %the reference (point where it cross the zero)
    
    if isnan(dataSingleAlign.refor(kk));
        dataSingleAlign.refor(kk)=0;
    end
    
    Xs=Xs-dataSingleAlign.refor(kk);                                %Shift the trace to zero (removing the mean of negative part )
    
    [dataSingleAlign.hstgrm(:,kk),dataSingleAlign.pos(:,kk),...
        ~,dataSingleAlign.ref(kk)]=Trace2HistCustom...              %Evaluate the histogram of each Trace and
        (Xs,Ys,stepbin,maxbin,cutpeak,minF,maxF);                  %the reference (point where it cross the zero)
    
    %% Histogram analysis
    %Remove the part between the two limit
    
    valid=(dataSingleAlign.pos(:,kk)>=editstartX) &...              %Index of the histogram inside the limit
        (dataSingleAlign.pos(:,kk)<=editEndX);
    
    dataSingleAlign.hstgrm(~valid,kk)=0;                            %Put to zero the part outside the limit (user selected)
    
    %% Interpolate histogram
    
    dataSingleAlign.hstgrmi(:,kk) = interp1(dataSingleAlign.pos(:,kk),dataSingleAlign.hstgrm(:,kk),data.Alignment.newbins);
    dataSingleAlign.hstgrmi(isnan(dataSingleAlign.hstgrmi))=0;
    
    %%Interpolate curve
    
    [Xord,index_ord]=sort(Xs,'ascend');                            % To interpolate is necessary to have X monotonically increase
    Yord=Ys(index_ord);                                            % Y in crescent order
    [Xordu,index_u]=unique(Xord);                                  % Remove the duplicate
    Yordu=Yord(index_u);                                           % Obtain the correspondent Y value
    
    dataSingleAlign.Yi(:,kk)=interp1(Xordu,Yordu,data.Alignment.Xi);%Interpolate the value on a Common X value for all traces
    
end

delete(h);
 
%Extract Trace 
indexTrace = round(get(handles.slider_algnmnt, 'value'));                  %Slider Position
indexeffTrace=Selected(indexTrace);                                        %Actual trace

Reference=dataSingleAlign.hstgrmi(:,indexTrace);
zeroCrossing=dataSingleAlign.ref(indexTrace);


for kk=1:size(traces,1)

    
    [crsscrl,lags]=xcorr(Reference,dataSingleAlign.hstgrmi(:,kk),maxlag);
    lagsnm=lags*unitaryspacing;
    
    dist=zeroCrossing-dataSingleAlign.ref(kk);
    posmax=crsscrlweight(crsscrl,lagsnm,dist,data.Alignment.sigm);
    
    nmdelay(kk)=lags(posmax)*unitaryspacing;
    nmdelay(kk)=nmdelay(kk);
end    

data.translateLc(Selected)=nmdelay;
changeupdatecolor(mainHandles,0)

hf=findobj('Name','automaticAlign');
close(hf);

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
flagGaussian=get(handles.checkbox_Gaussian, 'value');                      %Flag to Use/Print the gaussian

if flagGaussian
    data.Alignment.sigm=str2double(get(handles.edit_sigm,'string'))*1E-9;
else
    data.Alignment.sigm=0;
end

% Get saved data on groups

Selected=find(~data.removeTraces);
SelinValid=ismember(find(~data.removeTraces),positiveResult.indexTrace);
groups=data.TracesGroup(Selected(SelinValid));
traces=data.tracesRetract(Selected(SelinValid),:);
nrgroups=max(groups);

% Preallocation for interpolation
datalgn=cell(nrit,nrgroups);
data.Alignment.nrgroups=nrgroups;
data.Alignment.nrit=nrit;
data.Alignment.weight=[];

nrel=max(cellfun('length',traces(:,1)));
lengthX=abs(max([traces{:,1}])-min([traces{:,1}]));                        %Distance between the maximum of all traces and the minimum of all traces
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
        X=traces(list,1);                                                  %%Cell array with all the X of the traces of ll group
        Y=traces(list,2);                                                  %%Cell array with all the Y of the traces of ll group
        data.Alignment.weight=cat(2,data.Alignment.weight,length(list));   
        
        %Preallocation Variables
        datalgn{ii,ll}.posbase=zeros(nrbins,length(list));
        datalgn{ii,ll}.hstgrmbase=zeros(nrbins,length(list));
        datalgn{ii,ll}.pos=zeros(nrbins,length(list));
        datalgn{ii,ll}.hstgrm=zeros(nrbins,length(list));
        datalgn{ii,ll}.hstgrmi=zeros(nrbinsint,length(list));
        datalgn{ii,ll}.refor=zeros(1,length(list));

        for kk=1:length(list)                                              %Iterate for each trace of the group
            
            Xs=X{kk};                                                      %X value of the trace
            Ys=Y{kk};                                                      %Y trace of the group
            if flipflag;Ys=-Ys;end
            
            [datalgn{ii,ll}.hstgrmbase(:,kk),datalgn{ii,ll}.posbase(:,kk),...
                ~,datalgn{ii,ll}.refor(kk)]= Trace2HistCustom...           %Evaluate the histogram of each Trace and 
               (Xs,Ys,stepbin,maxbin,cutpeak,minF,maxF);                   %the reference (point where it cross the zero)
                                                                           
            if isnan(datalgn{ii,ll}.refor(kk));
                datalgn{ii,ll}.refor(kk)=0;
            end
            
            Xs=Xs-datalgn{ii,ll}.refor(kk);                                %Shift the trace to zero (removing the mean of negative part )
            
            [datalgn{ii,ll}.hstgrm(:,kk),datalgn{ii,ll}.pos(:,kk),...       
                ~,datalgn{ii,ll}.ref(kk)]=Trace2HistCustom...              %Evaluate the histogram of each Trace and 
                (Xs,Ys,stepbin,maxbin,cutpeak,minF,maxF);                  %the reference (point where it cross the zero)
            
            %% Histogram analysis
            %Remove the part between the two limit
           
            valid=(datalgn{ii,ll}.pos(:,kk)>=editstartX) &...              %Index of the histogram inside the limit
                (datalgn{ii,ll}.pos(:,kk)<=editEndX);
            
            datalgn{ii,ll}.hstgrm(~valid,kk)=0;                            %Put to zero the part outside the limit (user selected)
            
            %% Interpolate histogram 
            
            datalgn{ii,ll}.hstgrmi(:,kk) = interp1(datalgn{ii,ll}.pos(:,kk),datalgn{ii,ll}.hstgrm(:,kk),data.Alignment.newbins);
            datalgn{ii,ll}.hstgrmi(isnan(datalgn{ii,ll}.hstgrmi))=0;
                 
            %%Interpolate curve
            
            [Xord,index_ord]=sort(Xs,'ascend');                            % To interpolate is necessary to have X monotonically increase
            Yord=Ys(index_ord);                                            % Y in crescent order
            [Xordu,index_u]=unique(Xord);                                  % Remove the duplicate
            Yordu=Yord(index_u);                                           % Obtain the correspondent Y value
            
            datalgn{ii,ll}.Yi(:,kk)=interp1(Xordu,Yordu,data.Alignment.Xi);%Interpolate the value on a Common X value for all traces
            
        end
        
        %ii Iteration
        %ll Group
        
        [datalgn{ii,ll}.hstgrmalgn,...                                     %Matrix with all the histogram aligned to the references (of the group)
            datalgn{ii,ll}.Yalgn,...                                       %Matrix with all the traces aligned to the references (of the group)             
            datalgn{ii,ll}.mean_group,...                                  %Histogram with the group mean. Is called group template
            datalgn{ii,ll}.ref]...                                         %Vector with the zero-reference of each trace after alignment
            = alignfunc(...                                                %Align all Traces in a group to a common value
            data.Alignment.Xi,...                                          %Common X of all traces (after interpolation)                           
            datalgn{ii,ll}.Yi,...                                          %All Y of all the traces in a group
            data.Alignment.newbins,...                                     %Common X (bins) of all histogram
            datalgn{ii,ll}.hstgrmi,...                                     %All histogram of all traces in a group
            datalgn{ii,ll}.ref,...                                         %All reference Value (zero crossing) of the traces in a group
            data.Alignment.sigm,...                                     
            err,maxlag);
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

Selected=find(~data.removeTraces);
SelinValid=ismember(find(~data.removeTraces),positiveResult.indexTrace);
Selected=Selected(SelinValid);

indexTrace = round(get(handles.slider_algnmnt, 'value'));                  %Slider Position
indexeffTrace=Selected(indexTrace);                                        %Actual trace
    
flagGaussian=get(handles.checkbox_Gaussian, 'value');                      %Flag to use/Print the gaussian
sigm=str2double(get(handles.edit_sigm,'string'))*1E-9;                     %Gaussian Sigma
flagFlip = get(mainHandles.checkboxFlipTraces, 'value');                   %If Flip trace

axes(handles.axes_autalgn1)
cla;

% Get trace
[extendTipSampleSeparation,retractTipSampleSeparation,extendVDeflection,...
    retractVDeflection]= getTrace(indexeffTrace, data);

if flagFlip == 1;mirror=-1;else mirror=1;end %flip the signale

F = mirror*retractVDeflection;
%% Plot1

plot(retractTipSampleSeparation*1E9,F*1E12,'k','linewidth',1.2);           %Plot Trace
hold on
plot([0,0],[data.scaleMinF data.scaleMaxF],'--b','linewidth',1.2)          %Plot zero axes

if flagGaussian
    
    gaussx=-max(retractTipSampleSeparation):0.1e-9:max(retractTipSampleSeparation);
    gaussy=gaussmf(gaussx,[sigm,0]);                                           
    %Plot trace and gaussian
    h=area(gaussx*1E9,-60*gaussy);                                         %Plot Gaussian
    h.FaceColor = [1 0 0 ];
    alpha(0.25)
    set(gca,'FontSize',7)
    hold on
  

end

% set axis label
title('Traces')
xlim([data.scaleMinTss data.scaleMaxTss]); xlabel('tss (nm)');
ylim([data.scaleMinF data.scaleMaxF]);     ylabel('F (pN)');

%% Plot2
axes(handles.axes_autalgn2)
cla;

% Reference to align to zero
tss=retractTipSampleSeparation;
x1=tss;
x1 = x1((F<(-50*1e-12) & F>(-400*1e-12)));                   %condition

if isempty(x1)
    overzero=find(F>0);
    
    if isempty(overzero)
        zero=mean(tss);                        %if no zero is found, zero is the average value
    else
        zero=tss(overzero(1));                 %zero to first positive value
    end
    
else
    zero=mean(x1);                             %ideal zero
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
