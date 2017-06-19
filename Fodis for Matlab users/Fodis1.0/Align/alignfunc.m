function [hstgrmalgn3,Yalgn3,mean_k,ref3]=alignfunc(Xi,Yi,newbins,hstgrmi,sigm,ref,err,maxlag)

nrTrace=size(Yi,2);
unitaryspacing=newbins(2)-newbins(1);
numCycle=0;

if nrTrace==1                                        %If there is one trace
    
    hstgrmalgn3= hstgrmi;
    Yalgn3=Yi;
    mean_k=hstgrmi;
    ref3=ref;
    
elseif nrTrace==2                                  %If there are two traces

    %CrossCorrelation
    [crsscrl,lags]=xcorr(hstgrmi(:,1),hstgrmi(:,2),maxlag);
    lagsnm=lags*unitaryspacing;
    %Distance between reference
    dist=ref(2)-ref(1);
    %Weighted crosscorr
    posmax=crsscrlweight(crsscrl,lagsnm,dist,sigm);
    %Compute delay
    nmdelay=lags(posmax)*unitaryspacing;
       
    % Update data with new translation
    poshistn=newbins+nmdelay;
    posXn=Xi+nmdelay;
    ref(2)=ref(2)+nmdelay;
    
    hstgrmalgn(:,1)=hstgrmi(:,1);
    hstgrmalgn(:,2)=interp1(poshistn,hstgrmi(:,2),newbins);
    hstgrmalgn(isnan(hstgrmalgn))=0;
    
    Yalgn(:,1)=Yi(:,1);
    Yalgn(:,2)=interp1(posXn,Yi(:,2),Xi);
    
    hstgrmalgn3=hstgrmalgn;
    Yalgn3=Yalgn;
    mean_k=((hstgrmalgn(:,1)+hstgrmalgn(:,2))/2);
    ref3=ref;

else
    
    hstgrmalgn1=zeros(length(newbins),nrTrace);
    hstgrmalgn2=zeros(length(newbins),nrTrace);
    hstgrmalgn3=zeros(length(newbins),nrTrace);
    
    Yalgn1=zeros(length(Xi),nrTrace);
    Yalgn2=zeros(length(Xi),nrTrace);
    
    delay_tot1=zeros(nrTrace,1);
    delay_tot2=zeros(nrTrace,1);
    delay_tot3=zeros(nrTrace,1);
    
    ref1=zeros(1,nrTrace);
    ref2=zeros(1,nrTrace);
    
    %Randomize
    
    list=1:1:nrTrace;
    ix=randperm(nrTrace);
    list_r=list(ix);
    
    %% Initial Condition
    
    %Chose two random histogram in the group
    idx1=list_r(1);
    idx2=list_r(2);
    
    %Distance between reference
    dist=ref(idx2)-ref(idx1);
    %CrossCorrelation
    [crsscrl,lags]=xcorr(hstgrmi(:,idx1),hstgrmi(:,idx2),maxlag);
    lagsnm=lags*unitaryspacing;
    %Weighted crosscorr
    posmax=crsscrlweight(crsscrl,lagsnm,dist,sigm);
    %Compute delay
    delay_tot1(idx2,1)=lags(posmax);
    nmdelay=lags(posmax)*unitaryspacing;
    
    % Update data with new translation
    poshistn=newbins+nmdelay;
    posXn=Xi+nmdelay;
    
    hstgrmalgn1(:,idx1)=hstgrmi(:,idx1);
    hstgrmalgn1(:,idx2) = interp1(poshistn,hstgrmi(:,idx2),newbins);
    hstgrmalgn1(isnan(hstgrmalgn1))=0;
    
    Yalgn1(:,idx1)=Yi(:,idx1);
    Yalgn1(:,idx2)=interp1(posXn,Yi(:,idx2),Xi);
    
    ref1(idx1)=ref(idx1);
    ref1(idx2)=ref(idx2)+nmdelay;
    
    mean_k=(hstgrmalgn1(:,idx2)+hstgrmalgn1(:,idx1))/2;
    
    
    %% STEP 1 Compute Global Average
    for ll=3:nrTrace
        
        idx=list_r(ll);
        
        %CrossCorrelation
        [crsscrl,lags]=xcorr(mean_k,hstgrmi(:,idx),maxlag);
        lagsnm=lags*unitaryspacing;
        refall=mean(nonzeros(ref1));
        %Distance between reference
        dist=ref(idx)-refall;
        %Weighted crosscorr
        posmax=crsscrlweight(crsscrl,lagsnm,dist,sigm);
        delay_tot1(idx,1)=lags(posmax);
        nmdelay=lags(posmax)*unitaryspacing;
        
        % Update data with new translation
        poshistn=newbins+nmdelay;
        posXn=Xi+nmdelay;
        ref1(idx)=ref(idx)+nmdelay;
        
        hstgrmalgn1(:,idx) = interp1(poshistn,hstgrmi(:,idx),newbins);
        hstgrmalgn1(isnan(hstgrmalgn1))=0;
        Yalgn1(:,idx)=interp1(posXn,Yi(:,idx),Xi);
        %Update histogram mean to wich compute the correlation
        mean_k=((hstgrmalgn1(:,idx)+mean_k.*(ll-1))./ll);
        
    end
    
    %% STEP 2 Alignment all the tracks respect to Global Average
    
    InitMean=mean_k;
    refall=mean(ref1);
    
    for kk=1:nrTrace
        
        %CrossCorrelation
        [crsscrl,lags]=xcorr(InitMean,hstgrmi(:,kk),maxlag);
        lagsnm=lags*unitaryspacing;
        %Distance between reference
        dist=ref(kk)-refall;
        %Weighted crosscorr
        posmax=crsscrlweight(crsscrl,lagsnm,dist,sigm);
        delay_tot2(kk,1)=lags(posmax);
        nmdelay=lags(posmax)*unitaryspacing;
        % Update data with new translation
        poshistn=newbins+nmdelay;
        posXn=Xi+nmdelay;
        ref2(kk)=ref(kk)+nmdelay;
        
        hstgrmalgn2(:,kk) = interp1(poshistn,hstgrmi(:,kk),newbins);
        hstgrmalgn2(isnan(hstgrmalgn2))=0;
        Yalgn2(:,kk)=interp1(posXn,Yi(:,kk),Xi);
        
    end
    
    %% STEP 3 Refined alignment
    ref3=ref2;
    Yalgn3=Yalgn2;
    hstgrmalgn_i=hstgrmalgn2;
    
    %New randomize
    ixx=randperm(nrTrace);
    list_r=list(ixx);
    
    
    while err>1  && numCycle<100                     %Repeat until the error goes under one
        for jj=1:nrTrace
            
            idx=list_r(jj);
            
            mean_krtemp=((nrTrace.*mean_k)-hstgrmalgn_i(:,idx))./(nrTrace-1);
             
            %CrossCorrelation 
            [crsscrl,lags]=xcorr(mean_krtemp,hstgrmalgn_i(:,idx),maxlag);
            lagsnm=lags*unitaryspacing;
            refall3=mean(ref3(1:end ~= idx));
            %Distance between reference
            dist=ref3(idx)-refall3;
            %Weighted crosscorr
            posmax=crsscrlweight(crsscrl,lagsnm,dist,sigm);
            delay_tot3(idx,1)=lags(posmax);
            nmdelay=lags(posmax)*unitaryspacing;
            % Update data with new translation
            poshistn=newbins+nmdelay;
            posXn=Xi+nmdelay;
            ref3(idx)=ref3(idx)+nmdelay;
            
            hstgrmalgn3(:,idx) = interp1(poshistn,hstgrmalgn_i(:,idx),newbins);
            hstgrmalgn3(isnan(hstgrmalgn3))=0;
            Yalgn3(:,idx)=interp1(posXn,Yalgn3(:,idx),Xi);
            
            mean_k=((hstgrmalgn3(:,idx)+mean_krtemp.*(nrTrace-1))./nrTrace);
            
        end
        %Compute new error and update histogram
        err=sum(delay_tot3.^2)
        hstgrmalgn_i=hstgrmalgn3;
        numCycle=numCycle+1;
        
    end
    
    if err>=100;
        Yalgn3=Yalgn2;
        hstgrmalgn3=hstgrmalgn2;
        ref3=ref2;
        mean_k=InitMean;
    end
    
end


function weighttop=crsscrlweight(crsscrl,lagsnm,dist,sigm)

gausswei= normpdf(lagsnm,-dist,sigm);
gausswei=gausswei/max(gausswei(:));

newcrsscrl=gausswei'.*crsscrl;
[~,weighttop]=max(newcrsscrl);

