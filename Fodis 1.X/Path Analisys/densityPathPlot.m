function densityPathPlot(gp)
%plotta il grafico dei percorsi partendo dalla global matrix dritta
%percorsi in cui in ascisse c'ï¿½ la posizione quantizzata del picco mentre
%inordinata il numero cardinale di quel particolare picco nella  traccia


gp=gp';
gpz=[zeros(1,size(gp,2));gp];

%usi UNIQUE  per trovare le uniche combinazioni
[GPunique,ia,ic]=unique(gpz','rows');

GPunique=GPunique';

GPuniqueSum=cumsum(GPunique);

[ripetizioni,posizioni]=hist(ic,1:size(ia,1));

nrinterp=10000;

%genero ua cell per la legenda
legenda=cell(1,length(ia));
x_comm=zeros(size(ia,1),nrinterp);
y_comm=zeros(size(ia,1),nrinterp);

for ii=2:size(ia,1) %attenzione : !!! non so perché non funzioni da ii=1
    
    % qui usi unique per unico scopo di plot
    p=GPuniqueSum(:,ii);
    [c,iaa,icc]=unique(p);
    allungoX=1000;        %%così dovresti omogeneizzare il coefficiente angolare
    xcoord=(iaa-1)*allungoX;  
    ycoord=c;
    
%     plot(xcoord,ycoord,'LineWidth',ripetizioni(ii)/4);
%     hold on;

    
    x_comm(ii,:)=linspace(0,xcoord(end),nrinterp);
    y_comm(ii,:) = interp1(xcoord,ycoord,x_comm(ii,:));
    
    %compongo i vari elementi della legenda
    %legenda{ii}=num2str(ripetizioni(ii));
end

sl=(y_comm(:,2:end)-y_comm(:,1:end-1))./(x_comm(:,2:end)-x_comm(:,1:end-1));
x_coord_sl=(x_comm(:,1:end-1)+x_comm(:,2:end))/2;
y_coord_sl=(y_comm(:,1:end-1)+y_comm(:,2:end))/2;

gridpts=50;


x=linspace(0,100*allungoX,gridpts);  
% y=linspace(0,size(gp,1));
% y=linspace(0,max(GPuniqueSum(:)),gridpts);
y=linspace(0,6,gridpts);
[X,Y] = meshgrid(x,y);

Z1=zeros(length(x),length(y));
Z2=zeros(length(x),length(y));

h2 = waitbar(0, 'Please wait');
tic
for ii=1:length(x)-1
    for ll=1:length(y)-1
        %                 disp(num2str([ii,ll]))
        [a,b]=find((x_coord_sl>x(ii) & x_coord_sl<x(ii+1)) & (y_coord_sl>y(ll) & y_coord_sl<y(ll+1)));
        if ~isempty(a)
            idx=sub2ind(size(x_coord_sl),a,b);
            %plot(x_coord_sl(idx),y_coord_sl(idx),'xr')
            sl_slc=sl(idx);
            [f,g]=hist(sl_slc,0:0.00003:max(sl(:)));

%             figure;
%             bar(g,f)
%             pause
            
            [val,in]=max(f);
%             mm=mean(f);
%             
            Z1(ll,ii)=length(idx);
%             Z2(ll,ii)=(f(in)*g(in));
            Z2(ll,ii)=val(1);
        end
        
    end
    waitbar(ii/length(x));
end
delete(h2);
toc

figure; 
pcolor(Z1);
% valmax=0.2;
% Z1_norm = Z1/norm(Z1);
% Z1_norm(Z1_norm>valmax)=valmax;
% Z2_norm = Z2/norm(Z2);

% figure;
% pcolor(X,Y,Z1_norm);
% figure;
% pcolor(X,Y,Z2_norm);
% grid off
% legend(legenda);

% axis([0 size(gp,1) 0 size(gp,1)]);

end