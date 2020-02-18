function critical_expo(handles)
global data
global positiveResult


% update index trace and nTraces
nTraces = positiveResult.nTraces;                          %Nr total traces

y={};

hhh=waitbar(0,'Wait...');

for ii=1:1:nTraces
    
 
       
    
    indexTrace = ii;
    indexeffTrace=positiveResult.indexTrace(indexTrace);       %Actual trace
    
    %Load Translation
    translateLc = data.translateLc(indexeffTrace);
    

  
    
    % get Lc parameters
    [tssMin,tssMax,FMin,FMax,xBin,binSize,histValue,maxHistValue,zerosTempMax,...
        LcMin,LcMax,maxTssOverLc,xBinSizeMax,thresholdHist,xBinFcMax,...
        xBinDeltaLc, minDeltaLc, maxDeltaLc, startLcDeltaLc, persistenceLength]...
        = getLcParameters(handles);
    
    % Set GUI values
    set(handles.textFrameRate, 'String', ['/' num2str(nTraces)]);
    set(handles.editFrame, 'String', num2str(indexTrace));
    
    set(handles.sliderTraces, 'Value', indexTrace);
    set(handles.sliderTraces, 'Max', nTraces);
    set(handles.sliderTraces, 'SliderStep', [1 1] / nTraces);
    set(handles.sliderTraces, 'Value', indexTrace);
    set(handles.SGL_fil,'Value',data.SGFilter(indexeffTrace));
    
    [extendTipSampleSeparation,retractTipSampleSeparation,extendVDeflection,...
        retractVDeflection]= getTrace(indexeffTrace, data);
    


    % get tss F
    tss = retractTipSampleSeparation+translateLc;
    F = -retractVDeflection;
    
    
    % get contour lenght
    [Lc, Fc, LcHist, LcHistMax, xBinLcHist, LcHistVar, FcMax, FcProfile, LcMaxPts]...
        = getContourLength(tss, F, tssMin, tssMax, FMin, FMax, LcMin, LcMax,...
        maxTssOverLc, xBin, binSize, zerosTempMax,0, xBinSizeMax,...
        thresholdHist, persistenceLength);
    
 
    
    
    
    
    % get peaks profile
    [lcPeaks, slideTrace] = getProfilePeaks(tss, F, tssMin, tssMax,...
        FMin, FMax, LcMin, LcMax, maxTssOverLc, xBin, binSize,...
        zerosTempMax, translateLc, xBinSizeMax, thresholdHist, persistenceLength);
    
    % get fitTrace
    xBinFit = tssMin:str2double(get(handles.editBinFit, 'string')) * 1E-9:tssMax;
    
    [fitTrace] = getFitTrace(tss, lcPeaks, slideTrace, persistenceLength, xBinFit);
    
    

    
    
    %% remove strange spikes from fitTrace
    fitTrace2=fitTrace;
    
    idxzero=find(fitTrace2(1:end-1)==0);
    
    % Assignment of the next value so the abnormal zero points should be depleted
    fitTrace2(idxzero)=fitTrace2(idxzero+1);
  
    
    
    y{ii,1}=  fitTrace2 ;
    
    
    
    waitbar((ii)/(2*nTraces));
    
end




for ii=1:nTraces
    

    try
        [picos,idxpicos]=findpeaks(y{ii,1}); %% find height of the peaks
        
        deltapicos=y{ii,1}(idxpicos)-y{ii,1}(idxpicos+1); % find delta of the peaks
        
        
    catch
    end
    
    if ii == 1
        pi=picos;
        
        deltapi=deltapicos;
    else
        pi=[pi picos];   %pi is the vector containing all the negative peaks of the derivative
        
        deltapi=[deltapi deltapicos];
    end
    
    waitbar((nTraces+ii)/(2*nTraces));
end



%%

figure

subplot(2,2,1);

%% compute histogram of force
[freq1,bin1]=cumhist(pi,10000); %% compute the cumulative histogram of drops
loglog(bin1,freq1,'-o')
axis([min(bin1) max(bin1) min(freq1) max(freq1)]);
grid on
xlabel('Force drop size')
ylabel('Cumulative complementary density function (CCDF)')


%%

%% The same data as z-scores of the mean
mepi=mean(pi);
spi=std(pi);

for i=1:length(pi)
    z(i)=(pi(i)-mepi ) /spi;
end

subplot(2,2,2);

[freq,bin]=cumhist(z,10000);
loglog(bin,freq,'-o')
axis([min(bin) max(bin) min(freq) max(freq)]);
grid on
xlabel('Z-score drop size')
ylabel('Cumulative complementary density function (CCDF)')

%%

subplot(2,2,3);


%% COmpute the same stuff but as rank ordered (simple and efficient)
sorteo=sort(pi,'descend');
loglog(sorteo,'-o')
%axis([1 length(sorteo) min(sorteo) max(sorteo)]);
axis([1 length(sorteo) 10^-12 max(sorteo)]);

grid on
xlabel('Rank')
ylabel('Force drop size')

set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.1, 0.1, 0.8, 0.9]);
suptitle('details')


%%
%plot reference lines
xref=[1 10 100 1000 10000];
%         yref2=1e-10*xref.^-0.2;
%         yref1=1e-10*xref.^-0.1;
%         yref05=1e-10*xref.^-0.5;
%
figure

%         loglog(xref,yref2);
%
%         loglog(xref,yref1);
%         loglog(xref,yref05);

%calculate the slope of first 100 points
X = [ones(100,1) log(1:100)'];
b=[0 -0.4];


try    %if there are no 100 points
    b = X\log(sorteo(1:100)');
catch
end

yref=max(sorteo)*xref.^(b(2));
loglog(xref,yref);

hold on;

loglog(sorteo)
%axis([1 length(sorteo) min(sorteo) max(sorteo)]);
axis([1 length(sorteo) 10^-12 max(sorteo)]);

grid on
xlabel(['Rank   (slope of first 100 points =  ',num2str(b(2)), ' )'])
ylabel('Force drop size')

delete(hhh);



% function critical_expo(handles)
% global data
% global positiveResult
% 
% 
% % update index trace and nTraces
% nTraces = positiveResult.nTraces;                          %Nr total traces
% 
% y={};
% 
% hhh=waitbar(0,'Wait...');
% 
% for ii=1:1:nTraces
%     
%  
%        
%     
%     indexTrace = ii;
%     indexeffTrace=positiveResult.indexTrace(indexTrace);       %Actual trace
%     
%     %Load Translation
%     translateLc = data.translateLc(indexeffTrace);
%     
% 
%   
%     
%     % get Lc parameters
%     [tssMin,tssMax,FMin,FMax,xBin,binSize,histValue,maxHistValue,zerosTempMax,...
%         LcMin,LcMax,maxTssOverLc,xBinSizeMax,thresholdHist,xBinFcMax,...
%         xBinDeltaLc, minDeltaLc, maxDeltaLc, startLcDeltaLc, persistenceLength]...
%         = getLcParameters(handles);
%     
%     % Set GUI values
%     set(handles.textFrameRate, 'String', ['/' num2str(nTraces)]);
%     set(handles.editFrame, 'String', num2str(indexTrace));
%     
%     set(handles.sliderTraces, 'Value', indexTrace);
%     set(handles.sliderTraces, 'Max', nTraces);
%     set(handles.sliderTraces, 'SliderStep', [1 1] / nTraces);
%     set(handles.sliderTraces, 'Value', indexTrace);
%     set(handles.SGL_fil,'Value',data.SGFilter(indexeffTrace));
%     
%     [extendTipSampleSeparation,retractTipSampleSeparation,extendVDeflection,...
%         retractVDeflection]= getTrace(indexeffTrace, data);
%     
% 
% 
%     % get tss F
%     tss = retractTipSampleSeparation+translateLc;
%     F = -retractVDeflection;
%     
%     
%     % get contour lenght
%     [~, ~, ~, ~, ~, ~, FcMax, ~, ~]...
%         = getContourLength(tss, F, tssMin, tssMax, FMin, FMax, LcMin, LcMax,...
%         maxTssOverLc, xBin, binSize, zerosTempMax,0, xBinSizeMax,...
%         thresholdHist, persistenceLength);
%     
%  
%     
%         FcMaxEFF=FcMax(FcMax>0);
% 
%     
%     
%     
%     
%     
%     
%     
%     y{ii,1}=  FcMaxEFF ;
%     
%     waitbar((ii)/(2*nTraces));
%     
% end
% 
% 
% 
% 
% for ii=1:nTraces
%     
% 
%     try
%         picos=y{ii,1}; %% find the negative peaks i.e., the "drops"
%     catch
%     end
%     
%     
%     
%     if ii == 1
%         pi=picos;
%     else
%         pi=[pi picos];   %pi is the vector containing all the negative peaks of the derivative
%     end
%     
%     waitbar((nTraces+ii)/(2*nTraces));
% end
% 
% 
% 
% %%
% 
% figure
% 
% subplot(2,2,1);
% 
% %% compute histogram of force
% [freq1,bin1]=cumhist(pi,10000); %% compute the cumulative histogram of drops
% loglog(bin1,freq1,'-o')
% axis([min(bin1) max(bin1) min(freq1) max(freq1)]);
% grid on
% xlabel('Force drop size')
% ylabel('Cumulative complementary density function (CCDF)')
% 
% 
% %%
% 
% %% The same data as z-scores of the mean
% mepi=mean(pi);
% spi=std(pi);
% 
% for i=1:length(pi)
%     z(i)=(pi(i)-mepi ) /spi;
% end
% 
% subplot(2,2,2);
% 
% [freq,bin]=cumhist(z,10000);
% loglog(bin,freq,'-o')
% axis([min(bin) max(bin) min(freq) max(freq)]);
% grid on
% xlabel('Z-score drop size')
% ylabel('Cumulative complementary density function (CCDF)')
% 
% %%
% 
% subplot(2,2,3);
% 
% 
% %% COmpute the same stuff but as rank ordered (simple and efficient)
% sorteo=sort(pi,'descend');
% loglog(sorteo,'-o')
% %axis([1 length(sorteo) min(sorteo) max(sorteo)]);
% axis([1 length(sorteo) 10^-12 max(sorteo)]);
% 
% grid on
% xlabel('Rank')
% ylabel('Force drop size')
% 
% set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.1, 0.1, 0.8, 0.9]);
% suptitle('details')
% 
% 
% %%
% %plot reference lines
% xref=[1 10 100 1000 10000];
% %         yref2=1e-10*xref.^-0.2;
% %         yref1=1e-10*xref.^-0.1;
% %         yref05=1e-10*xref.^-0.5;
% %
% figure
% 
% %         loglog(xref,yref2);
% %
% %         loglog(xref,yref1);
% %         loglog(xref,yref05);
% 
% %calculate the slope of first 100 points
% X = [ones(100,1) log(1:100)'];
% b=[0 -0.4];
% 
% 
% try    %if there are no 100 points
%     b = X\log(sorteo(1:100)');
% catch
% end
% 
% yref=max(sorteo)*xref.^(b(2));
% loglog(xref,yref);
% 
% hold on;
% 
% loglog(sorteo)
% %axis([1 length(sorteo) min(sorteo) max(sorteo)]);
% axis([1 length(sorteo) 10^-12 max(sorteo)]);
% 
% grid on
% xlabel(['Rank   (slope of first 100 points =  ',num2str(b(2)), ' )'])
% ylabel('Force drop size')
% 
% delete(hhh);








% % % %                global data
% % % %         global positiveResult
% % % %
% % % %
% % % %         % update index trace and nTraces
% % % %         nTraces = positiveResult.nTraces;                          %Nr total traces
% % % %
% % % %         y={};
% % % %
% % % %         hhh=waitbar(0,'Wait...');
% % % %
% % % %         for ii=1:1:nTraces
% % % %
% % % %             iieffTrace=positiveResult.indexTrace(ii);       %Actual trace
% % % %             translateLc = data.translateLc(iieffTrace);
% % % %             % check if traces must be removed
% % % %
% % % %
% % % %             % get trace
% % % %             [~,retractTipSampleSeparation,...
% % % %                 ~,retractVDeflection,~]...
% % % %                 = getTrace(iieffTrace, data);
% % % %
% % % %
% % % %                 y{ii,1}=retractVDeflection;
% % % %
% % % %
% % % %
% % % %         end
% % % %
% % % %
% % % %
% % % %
% % % %
% % % %         for ii=1:nTraces
% % % %
% % % %             miny=min(find(y{ii,1}<0));
% % % %
% % % %
% % % %             %dife=diff(y{ii,1}(miny:1:end));
% % % %
% % % %             %%
% % % %             %try di di diff between more distant points
% % % %             nJump=1;
% % % %
% % % %             yAfter=y{ii,1}(miny+nJump:1:end);
% % % %             yBefore=y{ii,1}(miny:1:end-nJump);
% % % %
% % % %             dife=yAfter-yBefore;
% % % %             %%
% % % %             try
% % % %                 [picos,~]=findpeaks(dife); %% find the negative peaks i.e., the "drops"
% % % %             catch
% % % %             end
% % % %
% % % %             if ii == 1
% % % %                 pi=picos;
% % % %             else
% % % %                 pi=[pi picos];   %pi is the vector containing all the negative peaks of the derivative
% % % %             end
% % % %
% % % %             waitbar(ii/nTraces);
% % % %         end
% % % %
% % % %
% % % %
% % % %         %%
% % % %
% % % %         figure
% % % %
% % % %         subplot(2,2,1);
% % % %
% % % %         %% compute histogram of force
% % % %         [freq1,bin1]=cumhist(pi,10000); %% compute the cumulative histogram of drops
% % % %         loglog(bin1,freq1,'-o')
% % % %         axis([min(bin1) max(bin1) min(freq1) max(freq1)]);
% % % %         grid on
% % % %         xlabel('Force drop size')
% % % %         ylabel('Cumulative complementary density function (CCDF)')
% % % %
% % % %
% % % %         %%
% % % %
% % % %         %% The same data as z-scores of the mean
% % % %         mepi=mean(pi);
% % % %         spi=std(pi);
% % % %
% % % %         for i=1:length(pi)
% % % %             z(i)=(pi(i)-mepi ) /spi;
% % % %         end
% % % %
% % % %         subplot(2,2,2);
% % % %
% % % %         [freq,bin]=cumhist(z,10000);
% % % %         loglog(bin,freq,'-o')
% % % %         axis([min(bin) max(bin) min(freq) max(freq)]);
% % % %         grid on
% % % %         xlabel('Z-score drop size')
% % % %         ylabel('Cumulative complementary density function (CCDF)')
% % % %
% % % %         %%
% % % %
% % % %         subplot(2,2,3);
% % % %
% % % %
% % % %         %% COmpute the same stuff but as rank ordered (simple and efficient)
% % % %         sorteo=sort(pi,'descend');
% % % %         loglog(sorteo,'-o')
% % % %         %axis([1 length(sorteo) min(sorteo) max(sorteo)]);
% % % %         axis([1 length(sorteo) 10^-12 max(sorteo)]);
% % % %
% % % %         grid on
% % % %         xlabel('Rank')
% % % %         ylabel('Force drop size')
% % % %
% % % %          set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.1, 0.1, 0.8, 0.9]);
% % % %         suptitle('details')
% % % %
% % % %
% % % %         %%
% % % %         %plot reference lines
% % % %         xref=[1 10 100 1000 10000];
% % % % %         yref2=1e-10*xref.^-0.2;
% % % % %         yref1=1e-10*xref.^-0.1;
% % % % %         yref05=1e-10*xref.^-0.5;
% % % % %
% % % %         figure
% % % %
% % % % %         loglog(xref,yref2);
% % % % %
% % % % %         loglog(xref,yref1);
% % % % %         loglog(xref,yref05);
% % % %
% % % %         %calculate the slope of first 100 points
% % % %         X = [ones(100,1) log(1:100)'];
% % % %         b = X\log(sorteo(1:100)');
% % % %         yref=max(sorteo)*xref.^(b(2));
% % % %         loglog(xref,yref);
% % % %
% % % %          hold on;
% % % %
% % % %         loglog(sorteo)
% % % %         %axis([1 length(sorteo) min(sorteo) max(sorteo)]);
% % % %         axis([1 length(sorteo) 10^-12 max(sorteo)]);
% % % %
% % % %         grid on
% % % %         xlabel(['Rank   (slope of first 100 points =  ',num2str(b(2)), ' )'])
% % % %         ylabel('Force drop size')
% % % %
% % % %         delete(hhh);
% % % %
% % % %
% % % %
% % % %
% % % %




