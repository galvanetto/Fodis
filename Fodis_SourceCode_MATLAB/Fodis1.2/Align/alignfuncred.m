function [mean_all_filt2,ref2,mean_all_2]=alignfuncred(newbins,mean_all_filt,ref,mean_all,sigm,maxlag)

%Randomize
unitaryspacing=newbins(2)-newbins(1);
nrAll=size(mean_all_filt,2);

mean_all_filt1=zeros(size(mean_all_filt,1),nrAll);
mean_all_filt2=zeros(size(mean_all_filt,1),nrAll);
mean_all_2=zeros(size(mean_all_filt,1),nrAll);

delay_tot1=zeros(nrAll,1);
delay_tot2=zeros(nrAll,1);
nmdelay2=zeros(nrAll,1);

ref1=zeros(size(ref,1),size(ref,2));
ref2=zeros(size(ref,1),size(ref,2));

list=1:1:nrAll;
ix=randperm(nrAll);
list_r=list(ix);

if length(list_r)==1 || length(list_r)==2
    list_r=[list_r,list_r,list_r];
end

%Initial Condition
idx1=list_r(1);
idx2=list_r(2);

%CrossCorrelation
[crsscrl,lags]=xcorr(mean_all_filt(:,idx1),mean_all_filt(:,idx2),maxlag);
lagsnm=lags*unitaryspacing;
%Distance between reference
dist=ref(idx2)-ref(idx1);
%Weighted crosscorr
posmax=crsscrlweight(crsscrl,lagsnm,dist,sigm);
%Compute delay
delay_tot1(idx2,1)=lags(posmax);
nmdelay=lags(posmax)*unitaryspacing;
poshistn=newbins+nmdelay;

% Update data with new translation
mean_all_filt1(:,idx1)=mean_all_filt(:,idx1);
mean_all_filt1(:,idx2) = interp1(poshistn,mean_all_filt(:,idx2),newbins);
mean_all_filt1(isnan(mean_all_filt1))=0;

ref1(idx1)=ref(idx1);
ref1(idx2)=ref(idx2)+nmdelay;

mean_k=(mean_all_filt1(:,idx2)+mean_all_filt1(:,idx1))/2;

%% STEP 1 Compute Global Average
for ll=3:nrAll
    
    idx=list_r(ll);
    %CrossCorrelation
    [crsscrl,lags]=xcorr(mean_k,mean_all_filt(:,idx),maxlag);
    lagsnm=lags*unitaryspacing;
    refall=mean(nonzeros(ref1));
    %Distance between reference
    dist=ref(idx)-refall;
    %Weighted crosscorr
    posmax=crsscrlweight(crsscrl,lagsnm,dist,sigm);
    %Compute delay
    delay_tot1(idx,1)=lags(posmax);
    nmdelay=lags(posmax)*unitaryspacing;
    poshistn=newbins+nmdelay;
    ref1(idx)=ref(idx)+nmdelay;
   
    % Update data with new translation
    mean_all_filt1(:,list_r(ll)) = interp1(poshistn,mean_all_filt(:,idx),newbins);
    mean_all_filt1(isnan(mean_all_filt1))=0;
    
    mean_k=((mean_all_filt1(:,idx)+mean_k.*(ll-1))./ll);   
end


%% STEP 2 Alignment all the tracks respect to Global Average
      
InitMean=mean_k;  
refall=mean(ref1);

for kk=1:nrAll
    
    %CrossCorrelation
    [crsscrl,lags]=xcorr(InitMean,mean_all_filt(:,kk),maxlag);
    lagsnm=lags*unitaryspacing;
    %Distance between reference
    dist=ref(kk)-refall;
    %Weighted crosscorr
    posmax=crsscrlweight(crsscrl,lagsnm,dist,sigm);
    %Compute delay
    delay_tot2(kk,1)=lags(posmax);
    nmdelay2(kk,1)=lags(posmax)*unitaryspacing;
    poshistn=newbins+nmdelay2(kk,1);
   
    % Update data with new translation
    mean_all_filt2(:,kk) = interp1(poshistn,mean_all_filt(:,kk),newbins);
    mean_all_filt2(isnan(mean_all_filt2))=0;
    
    mean_all_2(:,kk) = interp1(poshistn,mean_all(:,kk),newbins);
    mean_all_2(isnan(mean_all_2))=0;
    
    ref2(kk)=ref(kk)+nmdelay2(kk,1);  
end


function weighttop=crsscrlweight(crsscrl,lagsnm,dist,sigm)

gausswei= normpdf(lagsnm,-dist,sigm);
gausswei=(gausswei-min(gausswei(:)))./(max(gausswei(:))-min(gausswei(:)));

newcrsscrl=gausswei'.*crsscrl;
[~,weighttop]=max(newcrsscrl);
