function varargout = automaticAlign_st2(varargin)
% AUTOMATICALIGN_ST2 MATLAB code for automaticAlign_st2.fig
%      AUTOMATICALIGN_ST2, by itself, creates a new AUTOMATICALIGN_ST2 or raises the existing
%      singleton*.
%
%      H = AUTOMATICALIGN_ST2 returns the handle to a new AUTOMATICALIGN_ST2 or the handle to
%      the existing singleton*.
%
%      AUTOMATICALIGN_ST2('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in AUTOMATICALIGN_ST2.M with the given input arguments.
%
%      AUTOMATICALIGN_ST2('Property','Value',...) creates a new AUTOMATICALIGN_ST2 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before automaticAlign_st2_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to automaticAlign_st2_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help automaticAlign_st2

% Last Modified by GUIDE v2.5 13-Nov-2017 13:38:41

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @automaticAlign_st2_OpeningFcn, ...
                   'gui_OutputFcn',  @automaticAlign_st2_OutputFcn, ...
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


function automaticAlign_st2_OpeningFcn(hObject, eventdata, handles, varargin)
global datalgn

nrGroup=size(datalgn,2);

handles.output = hObject;

set(handles.slider_alignmnt_st2, 'Value', 1);
set(handles.slider_alignmnt_st2, 'Min', 1);
set(handles.slider_alignmnt_st2, 'Max', nrGroup);

if nrGroup==1
    set(handles.slider_alignmnt_st2, 'SliderStep', [1 1]); 
    set(handles.slider_alignmnt_st2, 'Visible','off');
else
    set(handles.slider_alignmnt_st2, 'SliderStep', [1 1]./(nrGroup-1));
    set(handles.slider_alignmnt_st2, 'Visible','on');
end

setappdata(handles.figure_alst2,'triggergroup',0)
cmpt_algnment(handles)                                                     %Compute the group reference

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes automaticAlign_st2 wait for user response (see UIRESUME)
% uiwait(handles.figure_alst2);


% --- Outputs from this function are returned to the command line.
function varargout = automaticAlign_st2_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function slider_alignmnt_st2_Callback(hObject, eventdata, handles)
cmpt_reference(handles);

function slider_alignmnt_st2_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function checkbox_showall_Callback(hObject, eventdata, handles)
cmpt_reference(handles)
function checkbox_showref_Callback(hObject, eventdata, handles)
cmpt_reference(handles)
function checkbox_custref_Callback(hObject, eventdata, handles)
cmpt_reference(handles)

function checkboxSgolay_filt_Callback(hObject, eventdata, handles)
cmpt_algnment(handles)

function edit_filter_k_Callback(hObject, eventdata, handles)
cmpt_algnment(handles)

function edit_filter_k_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_filter_f_Callback(hObject, eventdata, handles)
cmpt_algnment(handles)

function edit_filter_f_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_MinPeakHeight_Callback(hObject, eventdata, handles)
cmpt_algnment(handles)

function edit_MinPeakHeight_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_MinPeakProm_Callback(hObject, eventdata, handles)
cmpt_algnment(handles)

function edit_MinPeakProm_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_MinPeakDist_Callback(hObject, eventdata, handles)
cmpt_algnment(handles)

function edit_MinPeakDist_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_lengthpeaks_Callback(hObject, eventdata, handles)
cmpt_algnment(handles)

function edit_lengthpeaks_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_maxrep_Callback(hObject, eventdata, handles)
cmpt_algnment(handles)

function edit_maxrep_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_sigmref_Callback(hObject, eventdata, handles)
cmpt_reference(handles)
function edit_sigmref_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_winsize_Callback(hObject, eventdata, handles)
cmpt_reference(handles)
function edit_winsize_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_minpromref_Callback(hObject, eventdata, handles)
cmpt_reference(handles)
function edit_minpromref_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_lowcut_Callback(hObject, eventdata, handles)
cmpt_reference(handles)
function edit_lowcut_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_highcut_Callback(hObject, eventdata, handles)
cmpt_reference(handles)
function edit_highcut_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_maxlag_Callback(hObject, eventdata, handles)
cmpt_algnment(handles)
function edit_maxlag_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function cmpt_algnment(handles)
%% Compute the mean referenc of each group
global datalgn
global data

nrGroup=data.Alignment.nrgroups;                                           %Number of group
nrit=data.Alignment.nrit;                                                  %Number of iteration
newbins=data.Alignment.newbins;                                            %X axis of histogram
sigm=data.Alignment.sigm;                                                  %Gaussian sigma

MinPeakHeight=str2double(get(handles.edit_MinPeakHeight,'String'));        %FindPeaks Minimum Height 
MinPeakProm=str2double(get(handles.edit_MinPeakProm,'String'));            %FindPeaks Minimum Peak Prominence                
MinPeakDist=str2double(get(handles.edit_MinPeakDist,'String'))*1E-9;       %FindPeaks Minimum Peak Distance
lengthpeaks=str2double(get(handles.edit_lengthpeaks,'String'))*1E-9;       

maxlagnm=str2double(get(handles.edit_maxlag,'string'))*1E-9;               % Max Lag available for correlation function in nm
maxlag=round(maxlagnm/(newbins(2)-newbins(1)));                            % Max lag available for correlation function in position    

SgolayFlag=get(handles.checkboxSgolay_filt,'Value');                       %Sgolay Filter On                  
k=str2double(get(handles.edit_filter_k,'String'));                         %Sgolay Filter k
f=str2double(get(handles.edit_filter_f,'String'));                         %Sgolay FIlter f

maxHistCount=str2double(get(handles.edit_maxrep,'String'));                %Max Histogram COunt (value above this on histogram are shifted to the max Value)

ref_all=[];
Yalgn_all=[];
hstgrmalgn_all=[];
mean_all=[];
mean_all_filt=[];
mean_ref_all=[];

for ii=1:nrit
    %Select the Iteration
    for ll=1:nrGroup
        
        if SgolayFlag
            filtcomp=sgolayfilt(datalgn{ii,ll}.mean_group,k,f);            %Apply filter to smooth the group mean 
        else
            filtcomp=datalgn{ii,ll}.mean_group;                            %Do not apply the filter
        end
        
        datalgn{ii,ll}.filtcomp=filtcomp;                                  %Save the filtered histogram                                  
        
        [~,locs,~,~]=findpeaks(filtcomp,data.Alignment.newbins,...         %FindPeaks on histogram
            'MinPeakHeight',MinPeakHeight,...
            'MinPeakProminence',MinPeakProm,...
            'MinPeakDistance',MinPeakDist);
        
        index=zeros(1,length(newbins));                                    %Preallocate the index

        for jj=1:length(locs)  
            low=locs(jj)-lengthpeaks;                                      %take only the part of the histogram only on the around
            high=locs(jj)+lengthpeaks;
            index=index|(newbins>low & newbins<high);
        end
        
        %Cut above the max repetition
        filtcomp(~index)=0;                                                % Put the histogram on zero outside the peaks
        filtcomp(filtcomp>maxHistCount)=maxHistCount;                      % Max Histogram Count (value above this on histogram are shifted to the max Value)
        
        %Collect All value of all group of all iteration collected in
        %an unique list. All data is aligned (group-wise)        
        ref_all=cat(2,ref_all,datalgn{ii,ll}.ref);                         %All zero-reference of all traces of all group of all iteration                         
        Yalgn_all=cat(2,Yalgn_all,datalgn{ii,ll}.Yalgn);                   %All traces of all the group of all iteration 
        hstgrmalgn_all=cat(2,hstgrmalgn_all,datalgn{ii,ll}.hstgrmalgn);    %All histogram of all traces of all iteration 
        
        %Group reference obtained by aligning each trace in the group but
        %NOT ALIGNED each other
        mean_all=cat(2,mean_all,datalgn{ii,ll}.filtcomp);                  %All group template original (after sgolay if done) dim:nrgroup*nriter                                                       
        mean_all_filt=cat(2,mean_all_filt,filtcomp);                       %All group template after peaks isolation
        mean_ref_all=cat(2,mean_ref_all,mean(datalgn{ii,ll}.ref));         %All zero for each reference calculated as avg of group ref
    end
end

%Collect All value of all group of all iteration collected in
%an unique list. All data is aligned (group-wise)
data.Alignment.ref_all=ref_all;                                            %All zero-reference of all traces of all iteration
data.Alignment.Yalgn_all=Yalgn_all;                                        %All traces of all the group of all iteration 
data.Alignment.hstgrmalgn_all=hstgrmalgn_all;                              %All histogram after the GROUP alignment

%Group reference obtained by aligning each trace in the group but
%NOT ALIGNED each other
data.Alignment.mean_all=mean_all_filt;                                     %All group reference filtered (only peaks saved)     dim:nrgroup*nriter

[data.Alignment.reference,...                                              % Template of each group aligned to each other
    data.Alignment.zeroref,...                                             % zero Reference of each group template after alignment
    data.Alignment.reference_nofilter]=...                                 % Template of each group aligned to each other (before filtering)
    alignfuncred...
    (newbins,...                                                           % Common X axes for histogram
    mean_all_filt,...                                                      % All group template after peaks isolation
    mean_ref_all,...                                                       % All zero for each reference calculated as avg of group ref
    mean_all,...                                                           % All group template original (after sgolay if done) dim:nrgroup*nriter
    sigm,maxlag);

cmpt_reference(handles);                                                   %Compute the GLOBAL REFERENCE


function cmpt_reference(handles)
%% Compute the global reference on which align all the trace trace
global data

reference=data.Alignment.reference;                                        %All reference for each
zeroref=data.Alignment.zeroref;                                            %zero reference of each template of the group                                                

newbins=data.Alignment.newbins;
weight=data.Alignment.weight;
weightf=sqrt(repmat(weight,size(reference,1),1));

%Weigth the final reference based on the number of traces for each groups
data.Alignment.MotherOfRef_Nof=sum(weightf.*reference,2)./sum(weightf(1,:),2);
data.Alignment.MotherOfRef=histupgrade(handles,newbins,data.Alignment.MotherOfRef_Nof);
data.Alignment.Motherzeroref=sum(weight.*zeroref,2)./sum(weight(1,:),2);

show_algnmnt_st2(handles)

function show_algnmnt_st2(handles)
global data

refon=get(handles.checkbox_showref,'value');
allon=get(handles.checkbox_showall,'value');
refcuston=get(handles.checkbox_custref,'value');
indexGroup=round(get(handles.slider_alignmnt_st2,'value'));
MinPeakHeight=str2double(get(handles.edit_MinPeakHeight,'String'));

newbins=data.Alignment.newbins;
nrit=data.Alignment.nrit;
nrGroup=data.Alignment.nrgroups;
weight=data.Alignment.weight;

%All group references aligned
reference_nof=data.Alignment.reference_nofilter;
reference=data.Alignment.reference;
zero_references=data.Alignment.zeroref;

samegroup=(0:nrGroup:nrGroup*(nrit-1))+indexGroup;                         %Identify all the iteration on the same groups

% Compute the mean of all of the reference of the same group
reference_avg=mean(reference(:,samegroup),2);                              %for filtered
reference_avg_nof=mean(reference_nof(:,samegroup),2);                      %and not filtered
zeroref_both=mean(zero_references(:,samegroup),2);                         %and the zero

%Mean of all references weighted
MotherOfRef=data.Alignment.MotherOfRef;
MotherOfRef_Nof=data.Alignment.MotherOfRef_Nof;
zero_MoR=data.Alignment.Motherzeroref;
                                                 
axes(handles.axes_autal_st2)
cla;

h=area((newbins-zero_MoR)*1E9,reference_avg,'LineStyle','none');
h(1).FaceColor = [0.6 0.6 0.8];
alpha(0.5)
hold on
plot((newbins-zero_MoR)*1E9,reference_avg_nof,'color',[0.4 0.4 1],'Linewidth',1.2);
plot(newbins*1E9,repmat(MinPeakHeight,length(newbins),1),'--','Linewidth',0.1,'color',[0 0 1])

% Plot all the traces
if allon
    cla;
    plot(newbins*1E9,reference)
end

%Plot the reference
if refon
    hold on
    plot((newbins-zero_MoR)*1E9,MotherOfRef_Nof,'Linewidth',1.5,'color',[0.8 0 0])
end
if refcuston    
    plot((newbins-zero_MoR)*1E9,MotherOfRef,'Linewidth',1.5,'color',[1 0.4 0.4])
end

set(handles.textgroup, 'string', ['Group: ',num2str((indexGroup))]);
set(handles.textnrtraces, 'string', ['Nr Traces: ',num2str(weight(indexGroup))]);

title('Group Histogram')
xlim([data.scaleMinTss data.scaleMaxTss]); xlabel('tss (nm)');
ylim([0 max(reference(:))+1]); 

function pushbutton_showgroupTraces_Callback(hObject, eventdata, handles)
global data
global datalgn

Xi=data.Alignment.Xi;
indexGroup=round(get(handles.slider_alignmnt_st2,'value'));
Ygroup=datalgn{1,indexGroup}.Yalgn;

h=findobj('tag','figtracesgroup');
if isempty(h);h=figure;set(h,'tag','figtracesgroup');end
figure(h)
cla;

plot(Xi,Ygroup)

function edit_sigmacorr_Callback(hObject, eventdata, handles)

function edit_sigmacorr_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function pushButton_finalAlignReferenceBinarized_Callback(hObject, eventdata, handles)
%% Align to reference binazrized
global data
Reference=data.Alignment.MotherOfRef;
finalAlign(handles,Reference)


function pushButton_finalAlignReference_Callback(hObject, eventdata, handles)
%% Align to reference computed as mean of reference of single group
global data
Reference=data.Alignment.MotherOfRef_Nof;
finalAlign(handles,Reference)


function finalAlign(handles,Reference)

%% Align to reference computed as mean of reference of single group

global data
global mainHandles
global datalgn
global positiveResult

nrGroup=data.Alignment.nrgroups;
sigm=data.Alignment.sigm;
newbins=data.Alignment.newbins;
unitaryspacing=newbins(2)-newbins(1);
maxlagnm=str2double(get(handles.edit_maxlag,'string'))*1E-9;
maxlag=round(maxlagnm/(unitaryspacing));


% MotherOfRef_nof=data.Alignment.MotherOfRef_Nof;
Motherzeroref=data.Alignment.Motherzeroref;
%Bring Mother of ref in zero
Reference=interp1(newbins-Motherzeroref,Reference,newbins);
Reference(isnan(Reference))=0;


Selected=find(~data.removeTraces);
SelinValid=ismember(find(~data.removeTraces),positiveResult.indexTrace);
Selected=Selected(SelinValid);
groups=data.TracesGroup(Selected);

listall=[];
hstgrm_pre=[];
ref_pre1=[];
ref_pre2=[];

for jj=1:nrGroup 
    list=find(groups==jj); 
    listall=cat(1,listall,list);
    hstgrm_pre=cat(2,hstgrm_pre,datalgn{1,jj}.hstgrmi);
    ref_pre1=cat(2,ref_pre1,datalgn{1,jj}.ref);
    ref_pre2=cat(2,ref_pre2,datalgn{1,jj}.refor);
end


for kk=1:length(listall)

    
    [crsscrl,lags]=xcorr(Reference,hstgrm_pre(:,kk),maxlag);
    lagsnm=lags*unitaryspacing;
    
    dist=ref_pre1(kk);
    posmax=crsscrlweight(crsscrl,lagsnm,dist,sigm);
    
    nmdelay(kk)=lags(posmax)*unitaryspacing;
    nmdelay(kk)=nmdelay(kk);
%     +ref_pre2(kk);
    
end    

data.translateLc(Selected(listall))=nmdelay;
changeupdatecolor(mainHandles,0)


function histoutput=histupgrade(handles,newbins,histinput)

sigmref=str2double(get(handles.edit_sigmref,'String'))*1E-9;
winsize=str2double(get(handles.edit_winsize,'String'));
minpromref=str2double(get(handles.edit_minpromref,'String'));
lowcut=str2double(get(handles.edit_lowcut,'String'));

b = (1/winsize)*ones(1,winsize);
a = 1;
histfilt = filter(b,a,histinput);

[pks,locs,~,~]=findpeaks(histfilt,newbins,'MinPeakProminence',minpromref,'WidthReference','halfheight');

% Last Peaks is the bigger
% [~,I]=max(pks);
% locs=locs(1:I);

gaussiantot=zeros(length(newbins),length(locs));
for ii=1:length(locs)
    
    %put a normalized gaussian in each peaks
    gausswei= normpdf(newbins,locs(ii),sigmref);
    gausswei=gausswei/(max(gausswei(:)));
    %cut below lowcut
    gausswei(gausswei<lowcut)=0;
    gaussiantot(:,ii)=gausswei;
    
end

% make a cut on the last peaks
% gausswei= normpdf(newbins,locs(end),2*sigmref);
% gausswei=2*(gausswei-min(gausswei(:)))./(max(gausswei(:))-min(gausswei(:)));
% gausswei(gausswei>=highcut)=highcut;
% gaussiantot(:,length(locs))=gausswei;

histoutput=max(gaussiantot,[],2);

function weighttop=crsscrlweight(crsscrl,lagsnm,dist,sigm)

gausswei= normpdf(lagsnm,-dist,sigm);
gausswei=gausswei./(max(gausswei(:)));

newcrsscrl=gausswei.*crsscrl;
[~,weighttop]=max(newcrsscrl);
