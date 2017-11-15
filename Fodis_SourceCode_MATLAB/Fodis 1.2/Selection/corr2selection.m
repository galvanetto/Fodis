function varargout = corr2selection(varargin)
% CORR2SELECTION MATLAB code for corr2selection.fig
%      CORR2SELECTION, by itself, creates a new CORR2SELECTION or raises the existing
%      singleton*.
%
%      H = CORR2SELECTION returns the handle to a new CORR2SELECTION or the handle to
%      the existing singleton*.
%
%      CORR2SELECTION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CORR2SELECTION.M with the given input arguments.
%
%      CORR2SELECTION('Property','Value',...) creates a new CORR2SELECTION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before corr2selection_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to corr2selection_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help corr2selection

% Last Modified by GUIDE v2.5 19-Dec-2016 10:55:35

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @corr2selection_OpeningFcn, ...
                   'gui_OutputFcn',  @corr2selection_OutputFcn, ...
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


% --- Executes just before corr2selection is made visible.
function corr2selection_OpeningFcn(hObject, eventdata, handles, varargin)
global positiveResult
% Choose default command line output for corr2selection
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%Gui Setting
nTraces=positiveResult.nTraces;
set(handles.slider_corrsel, 'Min', 1);
set(handles.slider_corrsel, 'Max', nTraces);
set(handles.slider_corrsel, 'SliderStep', [1/(nTraces-1) 1/(nTraces-1)]);
set(handles.slider_corrsel, 'Value', 1);

set(handles.slider_corrsel2, 'Min', 1);
set(handles.slider_corrsel2, 'Max', nTraces);
set(handles.slider_corrsel2, 'SliderStep', [1/(nTraces-1) 1/(nTraces-1)]);
set(handles.slider_corrsel2, 'Value', 1);

set(handles.text_valid, 'string', ['Traces Valid            '...
    num2str(0) '/' num2str(positiveResult.nTraces)]);
set(handles.text_editTr1,'string',['/' num2str(positiveResult.nTraces)])
set(handles.text_editTr2,'string',['/' num2str(positiveResult.nTraces)])

setappdata(handles.figure_corrsel,'pushbuttonTrigger',1)
compute_hist(handles)
% UIWAIT makes corr2selection wait for user response (see UIRESUME)
% uiwait(handles.figure_corrsel);


% --- Outputs from this function are returned to the command line.
function varargout = corr2selection_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function slider_corrsel_Callback(hObject, eventdata, handles)
global positiveResult

indexTrace = get(hObject, 'Value');
if(indexTrace < 1);indexTrace = 1;end
if(indexTrace > positiveResult.nTraces)
    indexTrace = positiveResult.nTraces;
end

set(handles.edit_editTr1, 'string', num2str(indexTrace));
switchview(handles)

function slider_corrsel_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function edit_editTr1_Callback(hObject, eventdata, handles)
global positiveResult

% check value
indexTrace = round(str2double(get(hObject, 'String')));
if(indexTrace < 1);indexTrace = 1;end
if(indexTrace > positiveResult.nTraces)
    indexTrace = positiveResult.nTraces;
end
% set value
set(handles.slider_corrsel, 'value', indexTrace);
set(handles.edit_editTr1, 'string', num2str(round(indexTrace)));

switchview(handles)
function edit_editTr1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function slider_corrsel2_Callback(hObject, eventdata, handles)
global positiveResult

indexTrace = get(hObject, 'Value');
if(indexTrace < 1);indexTrace = 1;end
if(indexTrace > positiveResult.nTraces)
    indexTrace = positiveResult.nTraces;
end

set(handles.edit_editTr2, 'string', num2str(indexTrace));
switchview(handles)

function slider_corrsel2_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function edit_editTr2_Callback(hObject, eventdata, handles)
global positiveResult

% check value
indexTrace = round(str2double(get(hObject, 'String')));
if(indexTrace < 1);indexTrace = 1;end
if(indexTrace > positiveResult.nTraces)
    indexTrace = positiveResult.nTraces;
end
% set value
set(handles.slider_corrsel2, 'value', indexTrace);
set(handles.edit_editTr2, 'string', num2str(indexTrace));

switchview(handles)

function edit_editTr2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_sigm_Callback(hObject, eventdata, handles)
compute_hist(handles)
function edit_sigm_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_filterdim_Callback(hObject, eventdata, handles)
compute_hist(handles)
function edit_filterdim_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_lowcut_Callback(hObject, eventdata, handles)
compute_hist(handles)
function edit_lowcut_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function checkbox_gaussian_Callback(hObject, eventdata, handles)
compute_hist(handles)


function edit_MinPeakProm_Callback(hObject, eventdata, handles)
compute_hist(handles)

function edit_MinPeakProm_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_sigmacorr_Callback(hObject, eventdata, handles)
compute_corr(handles)
function edit_sigmacorr_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function limit_corr_Callback(hObject, eventdata, handles)
showcorr(handles)
function limit_corr_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_maxlag_Callback(hObject, eventdata, handles)
compute_corr(handles)
function edit_maxlag_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function checkbox_filter_Callback(hObject, eventdata, handles)
compute_hist(handles)

function compute_hist(handles)

global data
global mainHandles
global positiveResult

% get flag flip
flagFlip = get(mainHandles.checkboxFlipTraces, 'value');
% update index trace and nTraces
nTraces = positiveResult.nTraces;                          %Nr total traces

%Preallocate and GUI data acq
data.histoutput=cell(1,nTraces);
ref=zeros(1,nTraces);

stepbin=str2double(get(mainHandles.editBinSize,'string'))*1E-9;
maxbin=str2double(get(mainHandles.editTraceMaxTss,'string'))*1E-9;
minF=str2double(get(mainHandles.editFMin,'string'))*1E-12;
maxF=str2double(get(mainHandles.editFMax,'string'))*1E-12;

sigm=str2double(get(handles.edit_sigm,'string'))*1e-9;
lowcut=str2double(get(handles.edit_lowcut,'string'));
dimf=str2double(get(handles.edit_filterdim,'string'));
filteron=get(handles.checkbox_filter,'value');
gausson=get(handles.checkbox_gaussian,'value');
MinPeakProm=str2double(get(handles.edit_MinPeakProm,'string'));

%WaitBar
h = waitbar(0, 'Please wait');
set(h,'Name','Computing histogram')

for  ii=1:nTraces
    
    indexeffTrace=positiveResult.indexTrace(ii);       %Actual trace
    %Load Translation
    translateLc = data.translateLc(indexeffTrace);
    
    % Get trace
    [~,retractTipSampleSeparation,~,...
        retractVDeflection]= getTrace(indexeffTrace, data);

    if flagFlip == 1;mirror=-1;else mirror=1;end %flip the signale
    % get tss-F
    tss = retractTipSampleSeparation+translateLc;
    F = mirror*retractVDeflection;
    
    %Put to zero
    [~,~,~,ref(ii)]=Trace2HistCustom(tss,F,stepbin,maxbin,Inf,minF,maxF);
    tss=tss-ref(ii);
    [data.SelectTrace.hstgrmo{1,ii},data.SelectTrace.poso{1,ii},~,~]=Trace2HistCustom(tss,F,stepbin,maxbin,Inf,minF,maxF);
    
    %Filter moving average
    if filteron
        b = 1/dimf*ones(dimf,1);
        hstgrm_filt=filter(b,1,data.SelectTrace.hstgrmo{1,ii});
    else
        hstgrm_filt=data.SelectTrace.hstgrmo{1,ii};
    end
    pos=data.SelectTrace.poso{1,ii};
    % Find peaks to find the relation between empty space and peaks
    [peaks,locs,~,~]=findpeaks(hstgrm_filt,pos,'MinPeakProminence',MinPeakProm); 
    
%     gaussx=pos(1):0.05*1E-9:pos(end);
    gaussx=pos;

    if gausson
        if ~isempty(locs)
            signaltot=zeros(length(locs),length(gaussx));
        else
            signaltot=zeros(1,length(gaussx));
        end
        for ll=1:length(locs)
            gaussol= normpdf(gaussx,locs(ll),sigm);
            gaussol=(gaussol-min(gaussol(:)))./(max(gaussol(:))-min(gaussol(:)));
            gaussol(gaussol<lowcut)=0;
            signaltot(ll,:)=peaks(ll)*gaussol;
        end
        %histoutput is the hstgrm with a gaussian instead of each peaks;
            data.SelectTrace.histoutput{1,ii}=max(signaltot,[],1);
            data.SelectTrace.pos{1,ii}=gaussx;
    else
        if ~isempty(locs)
            signaltot=zeros(length(locs),length(pos));
        else
            signaltot=zeros(1,length(pos));
        end
        locsol=hstgrm_filt;
        for ll=1:length(locs)
            locsol(~(locs(ll)-3*sigm:locs(ll)+3*sigm))=0;
            locsol(locsol<locsol)=0;
            signaltot(ll,:)=locsol;
        end
        
        %histoutput is zero exept in the [peaks-3*sigm:peak+3sigm];
        data.SelectTrace.histoutput{1,ii}=max(signaltot,[],1);
        data.SelectTrace.pos{1,ii}=pos;
    end
    
    if(mod(ii, round(0.1 * nTraces)) == 0);waitbar(ii / nTraces);end

end

delete(h)

compute_corr(handles)

function compute_corr(handles)
global data
global positiveResult
global mainHandles

stepbin=str2double(get(mainHandles.editBinSize,'string'))*1E-9;
sigm=str2double(get(handles.edit_sigm,'string'));
maxlagnm=str2double(get(handles.edit_maxlag,'string'))*1E-9;
maxlag=round(maxlagnm/stepbin);

nTraces = positiveResult.nTraces;                          %Nr total traces

data.SelectTrace.valcorr=zeros(nTraces,nTraces);
data.SelectTrace.valcov=zeros(nTraces,nTraces);

h = waitbar(0, 'Please wait');
set(h,'Name','Computing correlation')

for jj=1:nTraces
    for ll=jj:nTraces
        
        [crsscrl,lags]=xcorr(data.SelectTrace.histoutput{1,jj}(6:end) ,data.SelectTrace.histoutput{1,ll}(6:end),maxlag,'coeff');
                
        gausswei= normpdf(lags,0,sigm);
        gausswei=(gausswei-min(gausswei(:)))./(max(gausswei(:))-min(gausswei(:)));
        newcrsscrl=gausswei.*crsscrl;
        [~,posmax]=max(newcrsscrl);
        vote=newcrsscrl(posmax);
        lag=lags(posmax);
               
        data.SelectTrace.valcorr(jj,ll)=vote;
        data.SelectTrace.valcorr(ll,jj)=vote;
        
        data.SelectTrace.lag(ll,jj)=lag*stepbin;
        data.SelectTrace.lag(jj,ll)=lag*stepbin;

        
        if(mod(jj, round(0.1 * nTraces)) == 0);waitbar(jj / nTraces);end
    end
end
delete(h)
switchview(handles)


function pushbutton_switchview_Callback(hObject, eventdata, handles)
on=getappdata(handles.figure_corrsel,'pushbuttonTrigger');
setappdata(handles.figure_corrsel,'pushbuttonTrigger',~on);
switchview(handles)

function switchview(handles)
on=getappdata(handles.figure_corrsel,'pushbuttonTrigger');
if on 
    show_hist(handles)
    show_hist2(handles)
    showcorr(handles)
else
    showTrace(handles)
    showTrace2(handles)
    showcorr(handles)
end

function showcorr(handles)
global data
global mainHandles

stepbin=str2double(get(mainHandles.editBinSize,'string'))*1E-9;
sigm=str2double(get(handles.edit_sigmacorr,'string'))*1E-9;
indexTrace1 = round(get(handles.slider_corrsel, 'value'));  %Slider Position
indexTrace2 = round(get(handles.slider_corrsel2, 'value'));  %Slider Position
limit_corr=str2double(get(handles.limit_corr,'string'));
maxlagnm=str2double(get(handles.edit_maxlag,'string'))*1E-9;
maxlag=round(maxlagnm/stepbin);

hist1=data.SelectTrace.histoutput{1,indexTrace1};
hist2=data.SelectTrace.histoutput{1,indexTrace2};
[crsscrl,lags]=xcorr(hist1,hist2,maxlag,'coeff');
lagsnm=lags*stepbin;
gausswei= normpdf(lagsnm,0,sigm);
gausswei=gausswei/max(gausswei(:));
newcrsscrl=gausswei.*crsscrl;
[~,posmax]=max(newcrsscrl);
vote=newcrsscrl(posmax);

axes(handles.axes_corr)
cla;
hold on
xlimit=[min(lagsnm(:)*1E9) max(lagsnm(:)*1E9)];
h=area([xlimit(1),xlimit(2)],[limit_corr,limit_corr]);
h.FaceColor = [0 0.7 0];
h.EdgeColor = 'none';
h.FaceAlpha=0.3;

h2=area(lagsnm*1E9,gausswei);
h2.FaceColor = [.7 0 0];
h2.FaceAlpha=0.5;

plot(lagsnm*1E9,newcrsscrl,'color',[0 0 .7],'linewidth',1.2);
plot(lagsnm(posmax)*1E9,vote,'dk','markersize',7,'MarkerFaceColor',[0 0 .7],'linewidth',2)
plot([0,0],[0,1],'--k')

set(gca,'FontSize',7)
title(['Correlation between Traces Nr ' num2str(indexTrace1) ' and Nr ' num2str(indexTrace2)])
xlim([xlimit(1) xlimit(2)]); xlabel('Lags(nm)')
ylim([0 1]); ylabel('Correlation') 

 
function show_hist(handles)
global data

indexTrace = round(get(handles.slider_corrsel, 'value'));  %Slider Position
axes(handles.axes_figure_corrsel)
cla;

xdata=data.SelectTrace.pos{1,indexTrace}*1e9;
ydata=data.SelectTrace.histoutput{1,indexTrace};
xdata2=data.SelectTrace.poso{1,indexTrace}*1e9;
ydata2=data.SelectTrace.hstgrmo{1,indexTrace};

h1=bar(xdata2,ydata2);
h1.FaceColor = [.5 .5 .5];
h1.EdgeColor= [.5 .5 .5];
hold on
h2 = area(xdata,ydata,1E-12,'EdgeColor',[1 0 0]);
h2.FaceColor = [.7 0 0];
h2.FaceAlpha = 0.5;

% set axis label
title(['Histogram of Trace nr. ' num2str(indexTrace)])
xlim([data.scaleMinTss data.scaleMaxTss]);   xlabel('Bin (nm)');
ylim([0 max(ydata)+.1]); ylabel('Repetiton');
set(gca,'FontSize',7)
set(gca,'xgrid','on')
% set(gca,'xtick',round(linspace(data.scaleMinTss,data.scaleMaxTss,30)))

function show_hist2(handles)
global data

indexTrace = round(get(handles.slider_corrsel2, 'value'));  %Slider Position
axes(handles.axes_figure_corrsel2)
cla;

xdata=data.SelectTrace.pos{1,indexTrace}*1e9;
ydata=data.SelectTrace.histoutput{1,indexTrace};
xdata2=data.SelectTrace.poso{1,indexTrace}*1e9;
ydata2=data.SelectTrace.hstgrmo{1,indexTrace};

% h1=area(xdata2,ydata2);
% h1.FaceColor = [.5 .5 .5];
h1=bar(xdata2,ydata2);
h1.FaceColor = [.5 .5 .5];
h1.EdgeColor= [.5 .5 .5];
hold on
h2 = area(xdata,ydata,1E-12,'EdgeColor',[1 0 0]);
h2.FaceColor = [.7 0 0];
h2.FaceAlpha = 0.5;

% set axis label
title(['Histogram of Trace nr. ' num2str(indexTrace)])
xlim([data.scaleMinTss data.scaleMaxTss]);   xlabel('Bin (nm)');
ylim([0 max(ydata2)+0.1]); ylabel('Repetiton');
set(gca,'FontSize',7)
set(gca,'xgrid','on')
% set(gca,'xtick',round(linspace(data.scaleMinTss,data.scaleMaxTss,30)))

function showTrace(handles)
global data
global positiveResult
global mainHandles

indexTrace = round(get(handles.slider_corrsel, 'value'));  %Slider Position
indexeffTrace=positiveResult.indexTrace(indexTrace);       %Actual trace
%Load Translation
translateLc = data.translateLc(indexeffTrace);
flagFlip = get(mainHandles.checkboxFlipTraces, 'value');

% Get trace
[extendTipSampleSeparation,retractTipSampleSeparation,extendVDeflection,...
    retractVDeflection]= getTrace(indexeffTrace, data);

if flagFlip == 1;mirror=-1;else mirror=1;end %flip the signale
% get tss-F
xdata = retractTipSampleSeparation+translateLc;
ydata = mirror*retractVDeflection;
    
axes(handles.axes_figure_corrsel)
cla;

plot(xdata*1e9,ydata*1e12)
% set axis label
title(['Trace nr. ' num2str(indexTrace)])
xlim([data.scaleMinTss data.scaleMaxTss]);   xlabel('tss (nm)');
ylim([data.scaleMinF data.scaleMaxF]); ylabel('F ()');
set(gca,'FontSize',7)


function showTrace2(handles)

global data
global positiveResult
global mainHandles

indexTrace = round(get(handles.slider_corrsel2, 'value'));  %Slider Position
indexeffTrace=positiveResult.indexTrace(indexTrace);       %Actual trace
%Load Translation
translateLc = data.translateLc(indexeffTrace);
flagFlip = get(mainHandles.checkboxFlipTraces, 'value');

% Get trace
[~,retractTipSampleSeparation,~,...
    retractVDeflection]= getTrace(indexeffTrace, data);

if flagFlip == 1;mirror=-1;else mirror=1;end %flip the signale
% get tss-F
xdata = retractTipSampleSeparation+translateLc;
ydata = mirror*retractVDeflection;
    
axes(handles.axes_figure_corrsel2)
cla
plot(xdata*1e9,ydata*1e12)

% set axis label
title(['Trace nr. ' num2str(indexTrace)])
xlim([data.scaleMinTss data.scaleMaxTss]);   xlabel('tss (nm)');
ylim([data.scaleMinF data.scaleMaxF]); ylabel('F ()');
set(gca,'FontSize',7)


function pushbutton_corrview_Callback(hObject, eventdata, handles)
global data
limit_corr=str2double(get(handles.limit_corr,'String'));

h=findobj('tag','figcorr');
if ~isempty(h)
else
    h=figure;
    set(h,'tag','figcorr')
end
figure(h)
cla;

title('Correlation Matrix')
Corr=data.SelectTrace.valcorr;
Corr(Corr<=limit_corr)=0;
imagesc(Corr)

function Sort_corr_Callback(hObject, eventdata, handles)
global data
limit_corr=str2double(get(handles.limit_corr,'String'));

h=findobj('tag','figcorrsort');
if ~isempty(h)
else
    h=figure;
    set(h,'tag','figcorrsort')
end
Corr=data.SelectTrace.valcorr;
Corr(Corr<=limit_corr)=0;
data.SelectTrace.ord=symamd(Corr); %symrcm  or symamd

figure(h)
cla;

imagesc(Corr(data.SelectTrace.ord,data.SelectTrace.ord))

title('Sorted Correlation Matrix')
xlabel('Trace Nr.')
% list=get(gca,'xtick');
set(gca,'xtick',1:1:length(data.SelectTrace.ord))
set(gca,'xticklabels',{num2str(data.SelectTrace.ord')})
% set(gca,'xticklabels',{num2str(data.SelectTrace.ord(list)')})

ylabel('Trace Nr.')
set(gca,'ytick',1:1:length(data.SelectTrace.ord))
set(gca,'yticklabels',{num2str(data.SelectTrace.ord')})
% set(gca,'yticklabels',{num2str(data.SelectTrace.ord(list)')})


function pushbutton_tracecorrelation_Callback(hObject, eventdata, handles)
global data
limit_corr=str2double(get(handles.limit_corr,'String'));

indexTrace = round(get(handles.slider_corrsel, 'value'));  %Slider Position
indexTrace2 = round(get(handles.slider_corrsel2, 'value'));  %Slider Position

h=findobj('tag','figmonotrace');
if ~isempty(h)
else
    h=figure;
    set(h,'tag','figmonotrace')
end
figure(h)
cla;

title('Correlation Matrix')
Corr=data.SelectTrace.valcorr;
Corr(Corr<=limit_corr)=0;
plot(Corr(:,indexTrace),'ko','MarkerFaceColor','k')
hold on 
%Plot lowlimit
h=area([0 length(Corr(:,indexTrace))],[limit_corr limit_corr]);
h.FaceColor=[0 0.7 0];
h.EdgeColor='none';
h.FaceAlpha=0.3;
%Plot other trace
plot(indexTrace2,Corr(indexTrace2,indexTrace),'ko','MarkerFaceColor','b')
text(indexTrace2-2.5,Corr(indexTrace2,indexTrace)+0.04,['Nr. ' num2str(indexTrace2)])

%Plot current trace
plot(indexTrace,Corr(indexTrace,indexTrace),'ko','MarkerFaceColor','r')
text(indexTrace-2.5,Corr(indexTrace,indexTrace)-0.04,['Nr. ' num2str(indexTrace)])

title(['Correlation of Trace Nr: ' num2str(indexTrace) ' with the others Traces' ])
xlim([0 length(Corr(:,indexTrace))]);xlabel('Trace Nr.')
ylabel('Value of Correlation')


function pushbutton_selectInterval_Callback(hObject, eventdata, handles)
global data
global positiveResult


Sort_corr_Callback(handles.Sort_corr, eventdata, handles)

h=findobj('tag','figcorrsort');
if ~isempty(h)
else
    h=figure;
    set(h,'tag','figcorrsort')
end
figure(h)
hold on

hndLine = imline;
wait(hndLine);

%get position
pos = hndLine.getPosition;

if isempty(pos)
    return
end

pos1=round(pos(:,1));
pos2=round(pos(:,2));

if(pos1(1, 1) > pos1(2, 1))
   pos1=flipud(pos1);
end
if(pos2(1, 1) > pos2(2, 1))
   pos2=flipud(pos2);
end

diff1=abs(pos1(1, 1)-pos1(2, 1));
diff2=abs(pos2(1, 1)-pos2(2, 1));

if diff1>diff2
    posend=pos1;
else
    posend=pos2;
end

hold on
selected=posend(1):1:posend(2);
plot(selected,selected,'xk')
delete(hndLine)

set(handles.text_valid, 'string', ['Traces Valid            '...
    num2str(length(selected)) '/' num2str(positiveResult.nTraces)]);

data.SelectTrace.Valid=data.SelectTrace.ord(selected);


function pushbutton_selectcorrint_Callback(hObject, eventdata, handles)
global data
global positiveResult

pushbutton_corrview_Callback(handles.pushbutton_corrview,eventdata, handles)

indexTrace = round(get(handles.slider_corrsel, 'value'));  %Slider Position
limit_corr=str2double(get(handles.limit_corr,'String'));

Corr=data.SelectTrace.valcorr;
CorrTrace=Corr(:,indexTrace);
CorrTrace(CorrTrace<=limit_corr)=0;
idx=find(CorrTrace>0);

h=findobj('tag','figcorr');
if ~isempty(h)
else
    h=figure;
    set(h,'tag','figcorr')
end
figure(h)
hold on

plot(idx, idx,'xk')

set(handles.text_valid, 'string', ['Traces Valid            '...
    num2str(length(idx)) '/' num2str(positiveResult.nTraces)]);

data.SelectTrace.Valid=idx;

function pushbutton_updatetraces_Callback(hObject, eventdata, handles)
global positiveResult
global mainHandles
global data

ref=str2double(get(handles.edit_refTrace,'String'));

newpositionofpositiveres=sort(data.SelectTrace.Valid,'ascend');
positiveResult.indexTrace=positiveResult.indexTrace(newpositionofpositiveres);
positiveResult.nTraces=length(positiveResult.indexTrace);

choice = questdlg('Do you want to align the traces with the Traces specified in the Reference Trace box ', ...
   'Align to Reference','Yes Please','No Thanks','No Thanks');

if strcmp(choice,'Yes Please')
   data.translateLc(positiveResult.indexTrace)=-data.SelectTrace.lag(ref,newpositionofpositiveres);
end

h=findobj('tag','figcorrsort');
delete(h)
h=findobj('tag','figmonotrace');
delete(h)
h=findobj('tag','figcorr');
delete(h)
h=findobj('tag','figure_corrsel');
delete(h)

changeupdatecolor(mainHandles,0)

h=findobj('tag','fig_FtW');
figure(h);



function edit_refTrace_Callback(hObject, eventdata, handles)

function edit_refTrace_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
