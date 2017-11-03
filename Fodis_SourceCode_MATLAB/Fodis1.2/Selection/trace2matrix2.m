
function [Mat]=trace2matrix2(x,y,nm,pN)
%transforms a trace into a matrix nm*pN  with ones where the are points of
%the trace into a cell, zeros where there are no points
%y and x are the coordinates of the trace



y1=y*1e12;
x1=x*1e9;


masky=y1>0;
maskx=x1>0;

%le nuove variabili x2 e y2 hanno zeri dove erano negative 
y2=y1.*masky;
x2=x1.*maskx;

%bisogna ora aumentare di 1 perchè lo zero dà problemi***dovrei aggiungere
%un retroshift -1 prima nel percorso ma non l'ho fatto ancora
y2=y2+1;
x2=x2+1;


Mat = zeros(pN,nm);

for ii=1:size(x2,2) 
    
        Mat(round(y2(ii)),round(x2(ii)))=1;
        

end;

Mat = Mat(1:pN,1:nm);


end