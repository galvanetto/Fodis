function [Fc, tss] = getFFromLc(Lc, p, tss)

% generate tss
tss = tss(tss <= Lc);

% initialize Fc
Fc = [];

% check selection
if(isempty(Lc))
    return;
end

% get constants
kb = 1.3806488E-23; % (JK^-1)
T = 298; % (K)

% range for p from 0.3 - 0.45
alpha = kb*T/p;

% get Fc
Fc = alpha * (((1 - (tss./Lc)).^-2)/4 + (tss./Lc) - 1/4);

% clear Fc
idx = tss <= Lc;
Fc = Fc(idx);
tss = tss(idx);
