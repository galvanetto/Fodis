function [extendTipSampleSeparation,retractTipSampleSeparation,extendVDeflection,retractVDeflection,fileName] = getTrace(indexTrace, data)

% extract current trace
tracesExtend = data.tracesExtend;
tracesRetract = data.tracesRetract;
% fileName = data.fileNames;
% fileName = fileName{indexTrace};
fileName='ciao';

% extract vertical deflection and tip sample separation
if isempty(tracesExtend)
    extendTipSampleSeparation = [];
    extendVDeflection = [];
    
else
    extendTipSampleSeparation = cell2mat(tracesExtend(indexTrace, 1));
    extendVDeflection = cell2mat(tracesExtend(indexTrace, 2));
    
end
retractTipSampleSeparation = cell2mat(tracesRetract(indexTrace, 1)); 
retractVDeflection = cell2mat(tracesRetract(indexTrace, 2));

end