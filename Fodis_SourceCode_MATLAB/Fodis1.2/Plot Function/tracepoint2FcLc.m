function [Lc]=tracepoint2FcLc(tss,F,PersistentLenght)

% get constants
kb = 1.3806488E-23; % (JK^-1)
Temp = 298; % (K)

% coefficients
a1 = 4;
a2 = (4 * F / (kb*Temp/PersistentLenght)) - 3;
a3 = 0;
a4 = -1;

% get solutions
lambda = roots([a1 a2 a3 a4]);
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
Lc = tss/(1 - (bestL));

end