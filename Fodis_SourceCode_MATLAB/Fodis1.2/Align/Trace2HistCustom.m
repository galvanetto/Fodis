function [rep,binhist,bins,zero]=Trace2HistCustom(x0,F0,stepbin,maxbin,cutpeak,minF,maxF)
%trasformo F-tss (in cui F e' fix e va a 0 al 10 punto) in F-Lc
%Ritorno F1 e Lc1 che sono della stessa lunghezza di T
%T e� un formato data fix )solo valori di forza(solo le y)

x=x0;
F=F0;
% get constants
kb = 1.3806488E-23; % (JK^-1)
Temp = 298; % (K)
% range for p from 0.3 - 0.45
p=4e-10;  %%%%%%% Persistance lenght in nm!!!!!!!!!!!!!!!!!!!!!!!!1


idx=find((F> minF)); %condition minimum force
x = x(idx);
F = F(idx);

idx2=find(F<maxF); %condition minimum force
x = x(idx2);
F = F(idx2);


% coefficients
a1 = 4;
a2 = (4 * F / (kb*Temp/p)) - 3;
a3 = 0;
a4 = -1;

% for each measure
Lc = ones(1, length(F)) * NaN;
for ii = 1:1:length(F)

    % get solutions
    lambda = roots([a1 a2(ii) a3 a4]);
    l1 = lambda(1);
    l2 = lambda(2);
    l3 = lambda(3); 
    
    % get real solutions
    bestL1 = NaN;
    bestL2 = NaN;
    bestL3 = NaN;
    if(imag(l1) == 0 && l1 > 0 && l1 < 1)
        bestL1 = l1;
    elseif(imag(l2) == 0 && l2 > 0 && l2 < 1)
        bestL2 = l2;
    elseif(imag(l3) == 0 && l3 > 0 && l3 < 1)
        bestL3 = l3;
    end
    
    % select solution with min value
    bestL = min([bestL1 bestL2 bestL3]);
    Lc(ii) = x(ii)/(1 - (bestL));

end

Lc1=NaN(length(F),1);
F1=NaN(length(F),1);

F1(1:length(F))=F;
Lc1(1:length(F))=Lc;

bins=0:stepbin:maxbin;
% [rep,binhist]=hist(Lc1,bins);
[rep,edges] = histcounts(Lc1,bins);
binhist=(edges(1:(end-1))+edges(2:end))/2;

rep(rep>cutpeak)=cutpeak;

% Reference to align to zero
x1=x0;
F1=F0;
x1 = x1((F1<(-50*1e-12) & F1>(-400*1e-12)));                   %condition

if isempty(x1)
    overzero=find(F1>0);
    zero=x1(overzero(1));
else
    zero=mean(x1);
end
