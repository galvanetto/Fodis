function [hstgrmsGroupAligned,YGroupAligned,mean_k,groupRef]=alignfunc(Xi,Yi,newbins,hstgrmi,ref,sigm,err,maxlag)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Align a group of histogram to a common value
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%OUT
%hstgrmsGroupAligned:All histogram of the group aligned
%YGroupAligned:All traces of the group aligned
%mean_k:mean of all aligned histogram (for second step analysis) 
%groupRef: all new references of every traces in the group 

%IN
%Xi:Common X of all traces (after interpolation)                           
%Yi:All Y of all the traces in a group
%newbins:Common X (bins) of all histogram
%hstgrmi:All interpolated histogram of all the traces in a group
%ref:reference Value (zero crossing) of all traces in a group

nrTrace=size(Yi,2);                                                        %Nr traces of this group
unitaryspacing=newbins(2)-newbins(1);                                      %Bin of the histogram

if nrTrace==1                                                              %If there is just one trace in the group, the trace cannot be aligned (no reference)
    
    hstgrmsGroupAligned= hstgrmi;                                          %The aligned histogram is the input histogram 
    YGroupAligned=Yi;                                                      %The aligned Y is the input Y
    mean_k=hstgrmi;                                                        
    groupRef=ref;                                                              %
    
elseif nrTrace==2                                                          % If there is two traces in the group
%Shift trace 2 (keep trace 1 position)

    [crsscrl,lags]=xcorr(hstgrmi(:,1),hstgrmi(:,2),maxlag);                % CrossCorrelation between two histogram of two traces
    lagsnm=lags*unitaryspacing;                                            % Convert the lags in nm (from position)

    dist=ref(2)-ref(1);                                                    % Distance between reference
    maxCrssCorr=crsscrlweight(crsscrl,lagsnm,dist,sigm);                   % find the maximum of the crosscorrelation attenuated by a gaussian centered 
                                                                           % in -dist (has to be shift trace 2) and sigma sigm.  
                                                                           % Going far from distance reduce the correlation
                                                                           % as a gaussian. 

    nmdelay=lags(maxCrssCorr)*unitaryspacing;                              %Chosen shift (max of weighet crosscorrelation) in nm
    
    %% Update histogram 2 with the new shift
    
    poshistn=newbins+nmdelay;                                              % Update Histogram value
    posXn=Xi+nmdelay;                                                      % Update X value
    ref(2)=ref(2)+nmdelay;                                                 % Update reference of trace 2
    
    hstgrmalgn(:,1)=hstgrmi(:,1) ;                                         % Keep histogram 1                                    
    hstgrmalgn(:,2)=interp1(poshistn,hstgrmi(:,2),newbins);                % Update Histogram 2
    hstgrmalgn(isnan(hstgrmalgn))=0;                                       % All nan put to 0
    
    hstgrmsGroupAligned=hstgrmalgn;                                        % Assign Output histogram

    Yalgn(:,1)=Yi(:,1);                                                    %Keep trace 1 
    Yalgn(:,2)=interp1(posXn,Yi(:,2),Xi);                                  %Update trace 2 (interpolating as well)
    
    YGroupAligned=Yalgn;                                                   %Assign Output Y
    mean_k=((hstgrmalgn(:,1)+hstgrmalgn(:,2))/2);                          %Mean of histogram
    groupRef=ref;                                                          %All reference of all

else
    
    %Preallocate variable
    hstgrmalgn1=zeros(length(newbins),nrTrace);
    hstgrmalgn2=zeros(length(newbins),nrTrace);
    hstgrmsGroupAligned=zeros(length(newbins),nrTrace);
    
    Yalgn1=zeros(length(Xi),nrTrace);
    Yalgn2=zeros(length(Xi),nrTrace);
    
    delay_tot1=zeros(nrTrace,1);
    delay_tot2=zeros(nrTrace,1);
    delay_tot3=zeros(nrTrace,1);
    
    ref1=zeros(1,nrTrace);
    ref2=zeros(1,nrTrace);
    

    
    %% Initial Condition to start allignment
    
    list=1:1:nrTrace;                                                      %Vector 1,2,3,...,N with N:number of traces                
    list_r=list(randperm(nrTrace));                                        %Randomize it
    
    idx1=list_r(1);                                                        %Chose two random histogram in the group
    idx2=list_r(2);
    
    [crsscrl,lags]=xcorr(hstgrmi(:,idx1),hstgrmi(:,idx2),maxlag);          % CrossCorrelation between two histogram of two traces
    lagsnm=lags*unitaryspacing;                                            % Convert the lags in nm (from position)

    dist=ref(idx2)-ref(idx1);                                              %Distance between reference
    maxCrssCorr=crsscrlweight(crsscrl,lagsnm,dist,sigm);                   % find the maximum of the crosscorrelation attenuated by a gaussian centered 
                                                                           % in -dist (has to be shift trace 2) and sigma sigm.  
                                                                           % Going far from distance reduce the correlation
                                                                           % as a gaussian. 
                                                                         
    nmdelay=lags(maxCrssCorr)*unitaryspacing;                              %Chosen shift (max of weighet crosscorrelation) in nm
    delay_tot1(idx2,1)=lags(maxCrssCorr);                                  %Collect index of maximum crosscorrelation
    

    poshistn=newbins+nmdelay;                                              % Update Histogram value
    posXn=Xi+nmdelay;                                                      % Update X value
    
    hstgrmalgn1(:,idx1)=hstgrmi(:,idx1);                                   % Keep histogram 1                                    
    hstgrmalgn1(:,idx2) = interp1(poshistn,hstgrmi(:,idx2),newbins);       % Update Histogram 2
    hstgrmalgn1(isnan(hstgrmalgn1))=0;                                      % All nan put to 0
    
    Yalgn1(:,idx1)=Yi(:,idx1);                                             %Keep trace 1 
    Yalgn1(:,idx2)=interp1(posXn,Yi(:,idx2),Xi);                           %Update trace 2 (interpolating as well)
    
    ref1(idx1)=ref(idx1);                                                  %Keep reference 1                           
    ref1(idx2)=ref(idx2)+nmdelay;                                          %Update reference 2
    
    mean_k=(hstgrmalgn1(:,idx2)+hstgrmalgn1(:,idx1))/2;                    %Evaluate the mean between the two traces
    
    %% STEP 1: Compute GROUP AVERAGE
    % After have computed the mean between the first two traces all the
    % other traces are aligned to the mean of the first two
    
    for ll=3:nrTrace
        
        
        idx=list_r(ll);                                                    %Take another random trace
        
        [crsscrl,lags]=xcorr(mean_k,hstgrmi(:,idx),maxlag);                % CrossCorrelation between a histogram and the mean of all previous one
        lagsnm=lags*unitaryspacing;                                        % Convert the lags in nm (from position)

        refall=mean(nonzeros(ref1));                                       %Mean of all the reference already aligned

        
        dist=ref(idx)-refall;                                              %Distance between reference
        maxCrssCorr=crsscrlweight(crsscrl,lagsnm,dist,sigm);               % find the maximum of the crosscorrelation attenuated by a gaussian centered 
                                                                           % in -dist (has to be shift trace 2) and sigma sigm.  
                                                                           % Going far from distance reduce the correlation
                                                                           % as a gaussian. 
                                                                         
        nmdelay=lags(maxCrssCorr)*unitaryspacing;                          %Chosen shift (max of weighet crosscorrelation) in nm
        delay_tot1(idx,1)=lags(maxCrssCorr);                                %Collect index of maximum crosscorrelation
        
        poshistn=newbins+nmdelay;                                              % Update Histogram value
        posXn=Xi+nmdelay;                                                      % Update X value
    
        hstgrmalgn1(:,idx) = interp1(poshistn,hstgrmi(:,idx),newbins);     % Update Histogram
        hstgrmalgn1(isnan(hstgrmalgn1))=0;                                 % All nan put to 0
    
        Yalgn1(:,idx)=interp1(posXn,Yi(:,idx),Xi);                         %Update trace (interpolating as well)
    
        ref1(idx)=ref(idx)+nmdelay;                                        %Update reference 
        
        mean_k=((hstgrmalgn1(:,idx)+mean_k.*(ll-1))./ll);                  %Update histogram mean (with the new traces aligned) 
                                                                                
    end
    
    groupAverage=mean_k;                                                   %GROUP AVERAGE
    refall=mean(ref1);                                                     %Mean of all the aligned reference

    
    %% STEP 2: Alignment all the tracks respect to Group Average
    %Now all the traces are aligned to the just computed Group Average
    
    for kk=1:nrTrace
        
        [crsscrl,lags]=xcorr(groupAverage,hstgrmi(:,kk),maxlag);           % CrossCorrelation between a histogram and the mean of all previous one
        lagsnm=lags*unitaryspacing;                                        % Convert the lags in nm (from position)
        
        dist=ref(kk)-refall;                                               %Distance between reference
        maxCrssCorr=crsscrlweight(crsscrl,lagsnm,dist,sigm);               % find the maximum of the crosscorrelation attenuated by a gaussian centered 
                                                                           % in -dist (has to be shift trace 2) and sigma sigm.  
                                                                           % Going far from distance reduce the correlation
                                                                           % as a gaussian. 
                                                                         
        nmdelay=lags(maxCrssCorr)*unitaryspacing;                          %Chosen shift (max of weighet crosscorrelation) in nm
        delay_tot2(kk,1)=lags(maxCrssCorr);                                %Collect index of maximum crosscorrelation
        
        poshistn=newbins+nmdelay;                                          % Update Histogram value
        posXn=Xi+nmdelay;                                                  % Update X value
    
        hstgrmalgn2(:,kk) = interp1(poshistn,hstgrmi(:,kk),newbins);       % Update Histogram
        hstgrmalgn2(isnan(hstgrmalgn2))=0;                                % All nan put to 0
    
        Yalgn2(:,kk)=interp1(posXn,Yi(:,kk),Xi);                           %Update trace (interpolating as well)
    
        ref2(kk)=ref(kk)+nmdelay;                                          %Update reference 
             
    end
    
    %% STEP 3: Refined alignment
    % Iterate the alignment until the distance between traces is below a
    % value or a number of iteration is reachd
    
    groupRef=ref2;
    YGroupAligned=Yalgn2;
    hstgrmalgn_i=hstgrmalgn2;
    
    numCycle=0;                                                            %Cycle limit 
    list_r=list(randperm(nrTrace));                                        %New randomization
                                                              
    
    while err>1  && numCycle<100                     %Repeat until the error goes under one
        for jj=1:nrTrace
            
            idx=list_r(jj);
            
            mean_krtemp=((nrTrace.*mean_k)-hstgrmalgn_i(:,idx))./(nrTrace-1);% Evaluate 
            refall3=mean(groupRef(1:end ~= idx));                          %Evaluate new reference of the group

            [crsscrl,lags]=xcorr(mean_krtemp,hstgrmalgn_i(:,idx),maxlag);  % CrossCorrelation between a histogram and the mean of all previous one
            lagsnm=lags*unitaryspacing;                                    % Convert the lags in nm (from position)
            
            dist=groupRef(idx)-refall3;                                    %Distance between reference
            maxCrssCorr=crsscrlweight(crsscrl,lagsnm,dist,sigm);           % find the maximum of the crosscorrelation attenuated by a gaussian centered
                                                                           % in -dist (has to be shift trace 2) and sigma sigm.
                                                                           % Going far from distance reduce the correlation
                                                                           % as a gaussian.
            
            nmdelay=lags(maxCrssCorr)*unitaryspacing;                      %Chosen shift (max of weighet crosscorrelation) in nm
            delay_tot3(idx,1)=lags(maxCrssCorr);                           %Collect index of maximum crosscorrelation
            
            poshistn=newbins+nmdelay;                                      % Update Histogram value
            posXn=Xi+nmdelay;                                              % Update X value
            
            hstgrmsGroupAligned(:,idx) = interp1(poshistn,hstgrmalgn_i(:,idx),newbins);   % Update Histogram
            hstgrmsGroupAligned(isnan(hstgrmsGroupAligned))=0;             % All nan put to 0
            
            YGroupAligned(:,idx)=interp1(posXn,YGroupAligned(:,idx),Xi);   %Update trace (interpolating as well)
            
            groupRef(idx)=groupRef(idx)+nmdelay;                                        %Update references                            
            mean_k=((hstgrmsGroupAligned(:,idx)+mean_krtemp.*(nrTrace-1))./nrTrace);    %Update mean_k
            
        end
        err=sum(delay_tot3.^2)                                             % Compute new error
        hstgrmalgn_i=hstgrmsGroupAligned;                                  % update histogram
        numCycle=numCycle+1;                                               % increase Number of cycle
        
    end
    
    if err>=100;                                                           %If the error is too big keep the value before all the refinement
        
        YGroupAligned=Yalgn2;                       
        hstgrmsGroupAligned=hstgrmalgn2;
        groupRef=ref2;
        mean_k=groupAverage;
        
    end
    
end


