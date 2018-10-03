function [tracesExtend,tracesRetract] = readBruker(file)

%Read BRUKER 
tracesExtend = cell(1, 2);
tracesRetract = cell(1, 2);


NSMU = NSMatlabUtilities();
NSMU.Open(which(file));
[xTrace, xRetract, yTrace, yRetract, xLabel, yLabel] = NSMU.CreateForceZPlot(1, NSMU.FORCE, 1);

key1='(';
key2=')';

idx1x=strfind(xLabel,key1);
idx2x=strfind(xLabel,key2);
unitX=xLabel(idx1x+1:idx2x-1);


idx1y=strfind(yLabel,key1);
idx2y=strfind(yLabel,key2);
unitY=yLabel(idx1y+1:idx2y-1);

unitMoltiplicatorX=convertInExponential(unitX(1));
unitMoltiplicatorY=convertInExponential(unitY(1));

tracesExtend{1,1} = xTrace'*unitMoltiplicatorX;
tracesExtend{1,2}= yTrace'*unitMoltiplicatorY;
tracesRetract{1,1} = xRetract'*unitMoltiplicatorX;
tracesRetract {1,2}= yRetract'*unitMoltiplicatorY;

disp(xLabel);
disp(yLabel);

% sweep corrupted files if they are still opened
fclose('all');
