function [TracesGroup]=path_plot(gp,sizePoint,sizeLine)
%plotta il grafico dei percorsi partendo dalla global matrix dritta
%percorsi in cui in ascisse c'� la posizione quantizzata del picco mentre
%inordinata il numero cardinale di quel particolare picco nella  traccia

gp1=gp';
gpz=[zeros(1,size(gp1,2));gp1];

%usi UNIQUE  per trovare le uniche combinazioni
[GPunique,ia,ic]=unique(gpz','rows');
GPuniqueSum=cumsum(GPunique');

%Preallocation 
legend_list=cell(1,length(ia));

[ripetition,~]=hist(ic,1:size(ia,1));

hh=findobj('Tag','ptag');
figure(hh)

%matrice punti per il plot dei punti
punti=zeros(size(gp1,1));

%%
for ii=1:size(ia,1)
    
    Uniquesum=GPuniqueSum(:,ii);
    [c,iaa,~]=unique(Uniquesum);
    plot(iaa-1,c,'LineWidth',sizeLine*ripetition(ii)/10);
    
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
legend(legend_list);
axis([0 size(gp1,1) 0 size(gp1,1)]);
ax = gca; % current axes
ax.FontSize = 12;
ax.XTick = 1:1:size(gp1,1);
ax.YTick = 1:1:size(gp1,1);
grid on;
xlabel('Interval (Pn)');
ylabel('number of peak (#)');
set(ax,'Clippingstyle','rectangle')

%%
%plot of the dots
rgb=distinguishable_colors(size(gp1,1));

RGB=rgb+0.5;
RGB(RGB>=1.0)=1.0;

%PLOT DOTS
for ii=1:size(gp1,1)
    for jj=1:ii
        if(punti(jj,ii)>0)
            plot(ii,jj,'.','MarkerSize',sizePoint*(punti(jj,ii)^(2/3)),'Color',RGB(ii,:));
        end
    end
end

%Plot first Dot
plot(0,0,'.','MarkerSize',(sizePoint*size(gp1,2)^(2/3)),'Color','k');

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
