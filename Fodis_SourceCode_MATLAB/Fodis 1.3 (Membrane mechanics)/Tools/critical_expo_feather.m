function critical_expo_feather(handles)
global data
global positiveResult


% update index trace and nTraces
nTraces = positiveResult.nTraces;                          %Nr total traces

pi=[];

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
    
    temp_r = -retractVDeflection;
    
         %% Find peaks with FEATHER
        %% to find the ~final peak position and use the final part of the trace as the approaching curve
        
        
        
        %limit to the number of points
        limit=2000;
        if length(temp_r)>limit
            temp_r=temp_r(1:limit);
            retractTipSampleSeparation=retractTipSampleSeparation(1:2000);
        end
        
        
        idx=50;
        jj=0;
        while idx==50 && jj*100+300<length(temp_r)
            stdref=std(temp_r(end-100-jj*100:end-jj*100));
            maggiori=find(abs(temp_r(end-200-jj*100:end-101-jj*100))>5*stdref+abs(mean(temp_r(end-100-jj*100:end-jj*100))), 1);
            if(~isempty(maggiori))
                idx=length(temp_r)-jj*100;
            end
            jj=jj+1;
        end
        
        %% link to FEATHER
        
        
        
        %new variables for FEATHER
        newf=[flip(0.6 *temp_r(idx:end)) temp_r];
        
        time_step = 4.882e-4;        %standard with 4048 Hz
        newt = time_step * (1:length(newf));
        newtss=[ flip(retractTipSampleSeparation(idx:end))   retractTipSampleSeparation];
        
        trigger_time = time_step * length(temp_r(idx:end));
        
        indices = feather_example(newt,newtss,newf,trigger_time);
        
        real_indices= indices - ( length(newf) - length(temp_r)) ;
        

        
        
                
        %%
  
    
      
    
    
    pi= [pi   temp_r(real_indices)  ];
    
     waitbar((ii)/(nTraces));
    
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




