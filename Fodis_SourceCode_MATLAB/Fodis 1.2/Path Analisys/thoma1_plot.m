function [TracesGroup]=thoma1_plot(gp,sizePoint,sizeLine)

global data
global positiveResult


hhh=findobj('Tag','Ttag');
figure(hhh)


gp1=gp';
Ntraces=size(gp1,2);
gpz=[zeros(1,Ntraces);gp1];

[GPunique,ia,ic]=unique(gpz','rows');
GPunique=GPunique';

GPuniqueSum=cumsum(GPunique);

[ripetizioni,~]=hist(ic,1:size(ia,1));

GPuniqueRow=(GPunique(2:end,:))';
Ninterval=size(GPuniqueRow,2);
FinalThick=zeros(Ninterval);

for ii=1:size(ia,1)
    
    sequenza=row2UniqueNum(GPuniqueRow(ii,:));
    stringasequenza=num2str(sequenza);
    
    for jj=1:Ninterval
        
        numero=10^(Ninterval+1-jj) +1;
        stringanumero=num2str(numero);
        pos=strfind(stringasequenza, stringanumero);
        
        if(~isempty(pos))
            for kk=1:size(pos,2)
                
                FinalThick(jj,pos(kk))=FinalThick(jj,pos(kk))+ripetizioni(ii);
                                
            end
                       
        end
           
        
    end

    
end



%Points coordinates calculation within the intervals

Nintervals=size(data.intervals,1);

LcList=data.LcFc(:,1)*1e9;
ForceList=data.LcFc(:,2)*1e12;

ForceAve=[0];
LcAve=[0];
NumAve=[Ntraces];

for ii=1:Nintervals
    indexLcFc=find(LcList>=data.intervals(ii,1) & LcList<data.intervals(ii,2) );
    
    LcAve(ii+1)=mean(LcList(indexLcFc));
    ForceAve(ii+1)=mean(ForceList(indexLcFc));
    NumAve(ii+1)=size(indexLcFc,1);
    
end


disp('Contour Length values Averages (nm): ')
disp(LcAve);

disp('Force values Averages (pN): ')
disp(ForceAve);

disp('Number of Force Peaks whithin the intervals: ')
disp(NumAve);


%%
%%for the plot
hhh=findobj('Tag','Ttag');
figure(hhh)



for ii=1:Ninterval
   
    for jj=1:Ninterval
        
        if(FinalThick(ii,jj)~=0)
            plot([LcAve(jj) LcAve(jj+(Ninterval+1-ii))],[ForceAve(jj) ForceAve(jj++(Ninterval+1-ii))],'k',...
            'LineWidth',FinalThick(ii,jj) * sizeLine/50,'Color',[0.7,0.7,0.7]);
            hold on
        end
    end
end


%%
%plot of the dots
rgb=distinguishable_colors(Nintervals);

plot(0,0,'.','MarkerSize',sizePoint*Ntraces/5,'Color','k'); 

for ii=1:(Ninterval)
     plot(LcAve(ii+1),ForceAve(ii+1),'.','MarkerSize',sizePoint*NumAve(ii)/5,'Color',rgb(ii,:));
end

%%


ax = gca; % current axes
ax.FontSize = 12;

xlabel('Lc (nm)');
ylabel('Force (pN)');
axis([0 max(LcAve)*1.2 0 max(ForceAve)*1.2]);
set(ax,'Clippingstyle','rectangle')






        %%  |
        %   V
        %-----------------------------------------------------------------
        %The same as path_plot function for group assignation (without
        %plot)

        gp1=gp';
        gpz=[zeros(1,size(gp1,2));gp1];

        %usi UNIQUE  per trovare le uniche combinazioni
        [GPunique,ia,ic]=unique(gpz','rows');
        GPuniqueSum=cumsum(GPunique');

        %Preallocation 
        legend_list=cell(1,length(ia));

        [ripetition,~]=hist(ic,1:size(ia,1));

        hhh=findobj('Tag','Ttag');
        figure(hhh)

        %matrice punti per il plot dei punti
        punti=zeros(size(gp1,1));

        %%
        for ii=1:size(ia,1)

            Uniquesum=GPuniqueSum(:,ii);
            [c,iaa,~]=unique(Uniquesum);
            %plot(iaa-1,c,'LineWidth',sizeLine*ripetition(ii)/10);

            %compongo i vari elementi della legenda
            legend_list{ii}=num2str(ripetition(ii));

            %compongo la matrice punti
            for kk=1:size(gp1,1)  %scorre le colonne
                for jj=1:kk     %scorre le righe
                    xi=find( (iaa-1)==kk);
                    yi=find( c==jj);
                    if(xi==yi)
                        punti(jj,kk)=punti(jj,kk)+ripetition(ii);
                    end
                end
            end
        end


        %%
        %Traces Group

        gpU=rows2DifferentSingleElements(gp);
        UniqueU=unique(gp,'rows');
        GPuniqueU=rows2DifferentSingleElements(UniqueU);

        for kk=1:size(GPuniqueU,1)
            sequenza=find(gpU==GPuniqueU(kk));    
            C{kk}=sequenza;
        end

        TracesGroup=zeros(size(gp,1),1);

        for mm=1:length(C)
            list=C{mm};
            TracesGroup(list)=mm;
        end

function [U]=rows2DifferentSingleElements(M)

U=[];

for ll=1:size(M,1)
    U(ll,1)=row2UniqueNum(M(ll,:));
end

function [a]=row2UniqueNum(A)

%genera numeri :
%pratica se una riga � 2 1 3 2 io la trasformo in (1)2132  dodicimilacentotrenta due
%se la riga � 00203 -->  (1)00203  centomila duecentotre

lunghezza=size(A,2);
a=10^lunghezza;

for jj=0:lunghezza-1
    a = a + A(lunghezza-jj)*10^(jj);
end
