function value = convertInExponential(symbol)

if strcmp(symbol,'m')
    
    value=10^-3;
    
elseif strcmp(symbol,'u')
    
    value=10^-6;

    
elseif strcmp(symbol,'n')
    
    value=10^-9;
        
elseif strcmp(symbol,'p')
    
    value=10^-12;
    
else 
    
    value =1;
    
end