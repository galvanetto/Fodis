function acquisitionParameter=readAcquisitionParameter(file)

fileId = fopen(file, 'r');                                                 % open a file
dataLocal = textscan(fileId, '%s', 'delimiter', '\n');
dataLocal = dataLocal{1};
dataLocal = dataLocal(~cellfun('isempty', dataLocal'));

% get idx units, columns, startData, endData
idxSpringConstant = find(cellfun('isempty', strfind(dataLocal, '# springConstant: ')) == 0); 
idxSensitivity = find(cellfun('isempty', strfind(dataLocal, '# sensitivity: ')) == 0); 
idxMultiplier = find(cellfun('isempty', strfind(dataLocal, '# heightMultiplier: ')) == 0); 

stringSpringConstant=strsplit(dataLocal{idxSpringConstant(1)},':');    
stringSensitivity=strsplit(dataLocal{idxSensitivity(1)},':'); 
stringMultiplier=strsplit(dataLocal{idxMultiplier(1)},':'); 

acquisitionParameter.SpringConstant=str2double(stringSpringConstant{end});
acquisitionParameter.Sensitivity=str2double(stringSensitivity{end});
acquisitionParameter.Multiplier=str2double(stringMultiplier{end});
