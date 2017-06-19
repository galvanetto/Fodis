function [tracesExtend,tracesRetract] = readTxt(files,ii)
%Read JPK-force .txt
tracesExtend = cell(1, 2);
tracesRetract = cell(1, 2);

% open a file
fileId = fopen(files{ii}, 'r');
% read data from file
data = textscan(fileId, '%s', 'delimiter', '\n');
data = data{1};

% get idx units, columns, startData, endData
idxSegment = find(cellfun('isempty', strfind(data, '# segment: ')) == 0);
idxColumns = find(cellfun('isempty', strfind(data, '# columns: ')) == 0);
idxUnits = find(cellfun('isempty', strfind(data, '# units: ')) == 0);
idxStartData = idxUnits + 2;
idxEndData = find(cellfun('isempty', strfind(data, '# segmentIndex: ')) == 0) - 2;
idxEndData(1) = [];
idxEndData(3) = length(data);

% check traces, if there are 3 segment OK otherwise skip
if(length(idxSegment) ~= 3)
    disp(['Bad file skipped (invalid format, cannot find 3 traces): ' files{ii}]);
    % close file
    fclose(fileId);
    error('Not enough segment')
end

% check the segment names
countSegment = 0;
for idxTemp = 1:1:3
    
    % extract trace name
    tempText = textscan(data{idxSegment(idxTemp)}, '%s');
    tempText = tempText{1};
    tempText = tempText{3};
    
    % extract column number of vDeflaction and tipSampleSeparation
    tempColumn = textscan(data{idxColumns(idxTemp)}, '%s');
    tempColumn = tempColumn{1};
    idxVDeflaction = find(cellfun('isempty', strfind(tempColumn, 'vDeflection')) == 0) - 2;
    idxTipSampleSeparation = find(cellfun('isempty', strfind(tempColumn, 'tipSampleSeparation')) == 0) - 2;
    if(isempty(idxTipSampleSeparation))
        idxTipSampleSeparation = find(cellfun('isempty', strfind(tempColumn, 'height')) == 0) - 2;
    end
    
    % extract only data
    tempData = data(idxStartData(idxTemp):1:idxEndData(idxTemp));
    tempData = {sprintf('%s ', tempData{:})};
    tempData = strtrim(tempData);
    tempData = textscan(tempData{:}, '%f');
    tempData = tempData{1};
    tempVDeflaction = tempData(idxVDeflaction:(length(tempColumn) - 2):end);
    tempTipSampleSeparation = tempData(idxTipSampleSeparation:(length(tempColumn) - 2):end);
    
    % save data
    switch tempText
        case 'pause'
            
            countSegment = countSegment + 1;
            
        case 'extend'
            
            extendVDeflaction = tempVDeflaction;
            extendTipSampleSeparation = tempTipSampleSeparation;
            countSegment = countSegment + 1;
        case 'retract'
            
            retractVDeflaction = tempVDeflaction;
            retractTipSampleSeparation = tempTipSampleSeparation;
            countSegment = countSegment + 1;
            
        otherwise
            
            % close file
            fclose(fileId);
            error(['Bad file skiped (invalid format, wrong trace name): ' files{ii}]);           
    end
end

% check if pause, extend and retract are defined
if(countSegment ~= 3)
    disp(['Bad file skiped (invalid format, cannot find pause and/or extend and/or retract trace/s): ' files{ii}]);
    % close file
    fclose(fileId);
    error('Not enough segment')
end

tracesExtend{1,1} = extendTipSampleSeparation';
tracesExtend{1,2}= extendVDeflaction';
tracesRetract{1,1} = retractTipSampleSeparation';
tracesRetract {1,2}= retractVDeflaction';

fclose(fileId);

% sweep corrupted files if they are still opened
fclose('all');

