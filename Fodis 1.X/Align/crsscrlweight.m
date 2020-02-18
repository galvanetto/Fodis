function weighttop=crsscrlweight(crsscrl,lagsnm,dist,sigm)

if sigm~=0
    gausswei= normpdf(lagsnm,-dist,sigm);                                      %Gaussian bell ()
    gausswei=gausswei/max(gausswei(:));                                        %Normalize the gaussina
else
    gausswei=1;
end
newcrsscrl=gausswei'.*crsscrl;                                             %Multilpy the crosscorrelation for the gaussian. Farther value are attenuate 
[~,weighttop]=max(newcrsscrl);                                             %Find the maximum of the crosscorrelation (after attenuation)

