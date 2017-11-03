
A=importdata('cntrbeg.txt');
CC=load('cntrbeg.mat');
CC=CC.c;
% CC=CC.CC;
traces=A.data;
sigm=1E-8;
% sigm=0.5E-11;
newbins=-100e-9:0.5e-9:200e-9;
unitaryspacing=newbins(2)-newbins(1);
maxlag=100;

result=cell(1,size(CC,2));
mean_all=zeros(length(newbins),size(CC,2));
hist_all=zeros(length(newbins),size(CC,2));
mean_ref_all=zeros(1,size(CC,2));
weight=zeros(1,size(CC,2));
ref_all=[];
Yalgn_all=[];
hstgrmalgn_all=[];
uu=1;
for ii=1:10
    ref_all=[];
    Yalgn_all=[];
    hstgrmalgn_all=[];
    for ll=1:size(CC,2)
        
        list=CC{ll};
        X=traces(:,2*list);
        Y=traces(:,2*list-1);
        weight(uu)=length(list);
        
        if length(list)==1
            
            
            [hstgrmbase(:,1),posbase(:,1),~,ref]=trace2histClinker2(X,Y);
            hstgrm=zeros(length(hstgrmbase(:,1)),length(list));
            pos=zeros(length(posbase(:,1)),length(list));
            X=X-ref;
            [hstgrm(:,1),pos(:,1),~,ref]=trace2histClinker2(X,Y);
            %hstgrm(:,1)=sgolayfilt(hstgrm(:,1),3,15);
            lengthX=abs(max(X(:))-min(X(:)));
            Xi=linspace(-lengthX,2*lengthX,3*length(X(:,1)));
            
            hstgrm(1:15,:)=0;
            hstgrm(isnan(hstgrm))=0;
            hstgrmalgn=interp1(pos,hstgrm,newbins)';
            hstgrmalgn(isnan(hstgrmalgn))=0;
            result{ll}.hstgrmi= hstgrmalgn;
            result{ll}.hstgrmalgn=result{ll}.hstgrmi;
            result{ll}.mean_group=result{ll}.hstgrmi;
            result{ll}.ref=ref;
            [Xord,index_ord]=sort(X,'ascend');
            Yord=Y(index_ord);
            [Xordu,index_u]=unique(Xord);
            Yordu=Yord(index_u);
            result{ll}.Yalgn=interp1(Xordu,Yordu,Xi)';
            
        end
        
        if length(list)==2
            
            lengthX=abs(max(X(:))-min(X(:)));
            Xi=linspace(-lengthX,2*lengthX,3*length(X(:,1)));
            
            for kk=1:size(X,2)
                
                [Xord,index_ord]=sort(X(:,kk),'ascend');
                Yord=Y(index_ord,kk);
                [Xordu,index_u]=unique(Xord);
                Yordu=Yord(index_u);
                Yi(:,kk)=interp1(Xordu,Yordu,Xi);
                
            end
            
            [hstgrmbase1(:,1),posbase1(:,1),~,ref1]=trace2histClinker2(X(:,1),Y(:,1));
            [hstgrmbase2(:,1),posbase2(:,1),~,ref2]=trace2histClinker2(X(:,2),Y(:,2));
            X(:,1)=X(:,1)-ref1;X(:,2)=X(:,2)-ref2;
            [hstgrm1(:,1),pos1(:,1),~,ref1]=trace2histClinker2(X(:,1),Y(:,1));
            [hstgrm2(:,1),pos2(:,1),~,ref2]=trace2histClinker2(X(:,2),Y(:,2));
            %         hstgrm1(:,1)=sgolayfilt(hstgrm1(:,1),3,15);
            %         hstgrm2(:,1)=sgolayfilt(hstgrm2(:,1),3,15);
            
            hstgrm1(1:15,:)=0;hstgrm2(1:15,:)=0;
            hstgrmi1=interp1(pos1,hstgrm1,newbins);
            hstgrmi1(isnan(hstgrmi1))=0;
            hstgrmi2=interp1(pos2,hstgrm2,newbins);
            hstgrmi2(isnan(hstgrmi2))=0;
            result{ll}.hstgrmi=[hstgrmi1',hstgrmi1'];
            
            [crsscrl,lags]=xcorr(hstgrmi1',hstgrmi2',maxlag);
            lagsnm=lags*unitaryspacing;
            
            dist=ref2-ref1;
            gausswei= normpdf(lagsnm,-dist,sigm);
            gausswei=(gausswei-min(gausswei(:)))./(max(gausswei(:))-min(gausswei(:)));
            newcrsscrl=gausswei'.*crsscrl;
            [~,posmax]=max(newcrsscrl);
            nmdelay=lags(posmax)*unitaryspacing;
            
            poshistn=newbins+nmdelay;
            posXn=Xi+nmdelay;
            
            hstgrmalgn1=hstgrmi1;
            hstgrmalgn2=interp1(poshistn,hstgrmi2,newbins);
            hstgrmalgn2(isnan(hstgrmalgn2))=0;
            
            Yalgn(:,1)=Yi(:,1);
            Yalgn(:,2)=interp1(posXn,Yi(:,2),Xi);
            
            result{ll}.hstgrmalgn=[hstgrmalgn1;hstgrmalgn2]';
            result{ll}.mean_group=((hstgrmalgn1+hstgrmalgn2)/2)';
            ref2=ref2+nmdelay;
            result{ll}.ref=[ref1,ref2];
            result{ll}.Yalgn=Yalgn;
        end
        
        if length(list)>2
            [result{ll}.hstgrmi,result{ll}.hstgrmalgn,Xi,result{ll}.Yalgn,result{ll}.mean_group,result{ll}.ref]=alignper(X,Y,sigm,newbins);
        end
        
        
        result{ll}.filt=sgolayfilt(result{ll}.mean_group,3,15);
        filtcomp=result{ll}.filt;
        
        [pks,locs,w,p]=findpeaks(result{ll}.filt,newbins,'MinPeakHeight',1,'MinPeakProminence',0.05,'MinPeakDistance',5E-9);
        %     [pks,locs,w,p]=findpeaks(result{ll}.filt,newbins,'MinPeakHeight',2,'MinPeakProminence',0.5,'MinPeakDistance',5E-9);
        
        lengthpeaks=3E-9;
        index=zeros(1,length(newbins));
        
        for jj=1:length(locs)
            
            low=locs(jj)-lengthpeaks;
            high=locs(jj)+lengthpeaks;
            index=index|(newbins>low & newbins<high);
            
        end
        
        filtcomp(~index)=0;
        %    filtcomp(filtcomp<4)=0;
        %    filtcomp(filtcomp>6)=6;
        filtcomp(filtcomp>7)=7;
        
        %     hold on
        %     plot(newbins,filtcomp)
        % mean_all contain all the comparison filter (of histogram) for each group
        mean_all(:,uu)=filtcomp;
        mean_ref_all(:,uu)=mean(result{ll}.ref);
        
        % All value of all group collected in an unique list
        ref_all=cat(2,ref_all,result{ll}.ref);
        Yalgn_all=cat(2,Yalgn_all,result{ll}.Yalgn);
        hstgrmalgn_all=cat(2,hstgrmalgn_all,result{ll}.hstgrmalgn);
        uu=uu+1;
    end
end
 [mean_allal,delaytot_meank,ref_allmeank,refall]=alignredper(newbins,mean_all,mean_ref_all,sigm);

%% block alignment

traces_block2=zeros(length(Xi),size(traces,2));
for ll=1:size(CC,2)
    
    list=CC{ll};
    traces_block2(:,2*list) =repmat(Xi',1,size(traces_block2(:,2*list),2));
    traces_block2(:,2*list-1)=interp1(Xi+delaytot_meank(ll)-refall,result{ll}.Yalgn,Xi);
   
end
% 
% Xf2=traces_block2(:,2:2:end);
% Yf2=traces_block2(:,1:2:end);
% figure(4);plot(Xf2,Yf2)
% title('alltogheter')
%% alignment element by element

weightf=sqrt(repmat(weight,size(mean_allal,1),1));
materref1=max(mean_allal,[],2);
materref2=sum(weightf.*mean_allal,2)./sum(weightf(1,:),2);
% materref2(materref2>2)=2;

materref_all=modificahisto(newbins,materref2,10);
mean_ref_allal=sum(weight.*ref_allmeank,2)./sum(weight(1,:),2);

GloBAv=materref_all;
Y_post=zeros(size(Yalgn_all,1),size(Yalgn_all,2));
hstgrmalgn_post=zeros(size(hstgrmalgn_all,1),size(hstgrmalgn_all,2));


for kk=1:size(Yalgn_all,2)
    
    Y_pre=Yalgn_all(:,kk);
    hstgrm_pre=hstgrmalgn_all(:,kk);
    
    [crsscrl,lags]=xcorr(GloBAv,hstgrm_pre,maxlag);
    lagsnm=lags*unitaryspacing;
    
    dist=ref_all(kk)-mean_ref_allal;
    gausswei= normpdf(lagsnm,-dist,sigm);
    gausswei=(gausswei-min(gausswei(:)))./(max(gausswei(:))-min(gausswei(:)));
    newcrsscrl=gausswei'.*crsscrl;
    
    [~,posmax]=max(newcrsscrl);
%     delay_tot_fin(kk,1)=lags(posmax);
    nmdelay=lags(posmax)*unitaryspacing;
    
    poshistn=newbins+nmdelay;
    posXn=Xi+nmdelay;
        
    hstgrmalgn_post(:,kk) = interp1(poshistn-mean_ref_allal,hstgrmalgn_all(:,kk),newbins);
    hstgrmalgn_post(isnan(hstgrmalgn_post))=0;
    Y_post(:,kk)=interp1(posXn-mean_ref_allal,Y_pre,Xi);
         
end

traces_block1=zeros(length(Xi),size(traces,2));
traces_block1(:,1:2:end)=Y_post;

for ll=1:size(CC,2)
    list=CC{ll};
    traces_block1(:,2*list) =repmat(Xi',1,size(traces_block1(:,2*list),2));
end

% Xf1=traces_block1(:,2:2:end);
% Yf1=traces_block1(:,1:2:end);
% figure(5);plot(Xf1,Yf1)
% title('onebyone')

disp('Fine tutto')


