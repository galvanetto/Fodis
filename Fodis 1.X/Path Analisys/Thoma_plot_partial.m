function TracesGroup=Thoma_plot_partial(gp,sizeMarker)
%plotta il grafico dei percorsi partendo dalla global matrix dritta
%percorsi in cui in ascisse c'� la posizione quantizzata del picco mentre
%inordinata il numero cardinale di quel particolare picco nella  traccia

gp1=gp';
gpz=[zeros(1,size(gp1,2));gp1];

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


ForceAve=[0 120 45 60 52 100];
LcAve=[0 126 184 211 256 285];

%for the plot
figure;



for ii=1:Ninterval
   
    for jj=1:Ninterval
        
        if(FinalThick(ii,jj)~=0)
            plot([LcAve(jj) LcAve(jj+(Ninterval+1-ii))],[ForceAve(jj) ForceAve(jj++(Ninterval+1-ii))],'k',...
            'LineWidth',FinalThick(ii,jj));
            hold on
        end
        
        
    end
    
    
    
    
end
xlabel('Lc (nm)');
ylabel('Force (pN)');



            %segmento contain all the information of that segment: 1=x1, 2=y1, 3=x2,
            % 4=y2,5=numero ripetizioni=ripetizioni(ii)
            segmento=[0 0 0 0 0];

            for ii=1:size(ia,1)

                %unique is just for plot
                p=GPuniqueSum(:,ii);
                [c,iaa,~]=unique(p);

                for jj=1:size(iaa,1)-1

                    stemp=[0 0 0 0 0];
                    stemp(1)=iaa(jj);
                    stemp(2)=c(jj);
                    stemp(3)=iaa(jj+1);
                    stemp(4)=c(jj+1);
                    stemp(5)=ripetizioni(ii);

                    %first line always 00000
                    segmento=[segmento;stemp];
                end

            end

            segmentoOrdinato=sortrows(segmento);

            segmentoOrdinatoCut=segmentoOrdinato(:,1:4);
            [ccc,~,~]=unique(segmentoOrdinatoCut,'rows');


            %genera vettrori colonna confrontabili tra segmentoordinatocut e ccc: 
            %una riga 2 1 3 2 io la trasformo in (1)2132 dodicimilacento trenta due

            %%
            %ciclo per cccU
            cccU=ccc(:,1);
            for ll=1:size(ccc,1)
                cccU(ll)=row2UniqueNum(ccc(ll,:));
            end

            %ciclo per segmentoOrdinatoCutU
            segmentoOrdinatoCutU=segmentoOrdinatoCut(:,1);
            for ll=1:size(segmentoOrdinatoCut,1)
                segmentoOrdinatoCutU(ll)=row2UniqueNum(segmentoOrdinatoCut(ll,:));
            end
            %%
            figure;
            for gg=2:size(ccc,1)

                spessore=0;
                stessoSegmento=find(segmentoOrdinatoCutU==cccU(gg));

                for kk=1:size(stessoSegmento,1)
                    spessore = spessore +  segmentoOrdinato(stessoSegmento(kk),5);    
                end

                plot([ccc(gg,1)-1 ccc(gg,3)-1],[ccc(gg,2) ccc(gg,4)],'b',...
                    'LineWidth',sizeMarker*(spessore/5));
                hold on
            end
            xlabel('Interval (Pn)');
            ylabel('number of peak (#)');
            grid on

            axis([0 size(gp,2) 0 size(gp,2)]);
            ax = gca; % current axes
            ax.FontSize = 12;
            ax.XTick = 1:1:size(gp,1);
            ax.YTick = 1:1:size(gp,1);
            grid on;

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




           
