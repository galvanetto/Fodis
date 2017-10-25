function [tracesExtend,tracesRetract] = readTxt(files,ii)
%Read JPK-force .txt
tracesExtend = cell(1, 2);
tracesRetract = cell(1, 2);

% open a file
fileId = fopen(files{ii}, 'r');
% read data from file
data = textscan(fileId, '%s', 'delimiter', '\n');
data = data{1};
data = data(~cellfun('isempty', data'));
% get idx units, columns, startData, endData
idxAllSegment = find(cellfun('isempty', strfind(data, '# segment: ')) == 0);
idxSegmentRetract = find(cellfun('isempty', strfind(data, '# segment: retract')) == 0);
idxColumns = find(cellfun('isempty', strfind(data, '# columns: ')) == 0);
idxUnits = find(cellfun('isempty', strfind(data, '# units: ')) == 0);

idxNumberData = find(cellfun('isempty', strfind(data, '#')));

%Only the one after the segment beginning
idxColumnsValid=find(idxColumns>idxSegmentRetract(1));
idxUnitsValid=find(idxUnits>idxSegmentRetract(1));
idxNextSegment=find(idxAllSegment>idxSegmentRetract(1));

idxStartData=find(idxNumberData>idxSegmentRetract(1));

if ~isempty(idxColumnsValid)
    idxColumnsRetract=idxColumns(idxColumnsValid(1));
    idxUnitsRetract=idxUnits(idxUnitsValid(1));
    idxStartDataRetract=idxNumberData(idxStartData(1));
    
    if ~isempty(idxNextSegment)
        idxEndData=find(idxNumberData>idxStartDataRetract && idxNumberData<idxNextSegment(1));
        idxEndDataRetract=idxNumberData(idxEndData(end));
    else
        idxEndDataRetract=idxNumberData(end);
    end
else
    disp(['Bad file skipped (invalid format, cannot find retract Section): ' files{ii}]);
    fclose(fileId);
    return;
end

columnsAvailable=data{idxColumnsRetract};
indxStartListColumns=strfind(columnsAvailable,':');
columnsAvailable=columnsAvailable(indxStartListColumns+1:end);

columnsName = textscan(columnsAvailable, '%s');

if isempty(columnsName)
    disp(['Bad file skipped (invalid format, cannot find available Column): ' files{ii}]);
    fclose(fileId);
    return;
end

IndexColumnAvailable=zeros(2,6);
% #1 vDeflection
% #2 tipSampleSeparation
% #3 smoothedCapacitiveSensorHeight
% #4 capacitiveSensorHeight
% #5 measuredHeight
% #6 height

columnsPossibleName={'vDeflection','tipSampleSeparation','smoothedCapacitiveSensorHeight',...
    'capacitiveSensorHeight','measuredHeight','height'};
for jj=1:length(columnsName{1})
    valueInList = find(cellfun('isempty', strfind(columnsPossibleName, columnsName{1}{jj})) == 0);
    IndexColumnAvailable(1,valueInList)=1;
    IndexColumnAvailable(2,valueInList)=jj;
end

indexYValue=0;
if (IndexColumnAvailable(1,1)==0)
    disp(['Cannot Find VDeflection in File: ' files{ii}]);
    fclose(fileId);
    return;
else
    indexYValue=IndexColumnAvailable(2,1);
end

indexXValue=0;
if (IndexColumnAvailable(1,2)==0)
    disp(['Tip Sample Separation not found in File: ' files{ii}]);
    if (IndexColumnAvailable(1,3)==0)   
        if (IndexColumnAvailable(1,4)==0)
            if (IndexColumnAvailable(1,5)==0)
                if (IndexColumnAvailable(1,6)==0)
                    disp(['Not Found Any valid format in File: ' files{ii}]);
                    fclose(fileId);
                    return;
                else
                    indexXValue=IndexColumnAvailable(2,6);
                end
            else
                indexXValue=IndexColumnAvailable(2,5);
            end
        else
            indexXValue=IndexColumnAvailable(2,4);
        end
    else
        indexXValue=IndexColumnAvailable(2,3);
    end
else
    indexXValue=IndexColumnAvailable(2,2);
end



disp(indexXValue);

% extract only data

tempData = data(idxStartDataRetract:1:idxEndDataRetract);

NumericMatrix=cell2mat(cellfun(@str2num,tempData,'un',0));
tempVDeflaction =NumericMatrix(:,indexYValue);
tempTipSampleSeparation = NumericMatrix(:,indexXValue);

tracesExtend{1,1} = zeros(size(tempTipSampleSeparation))';
tracesExtend{1,2}= zeros(size(tempVDeflaction))';
tracesRetract{1,1} = tempTipSampleSeparation';
tracesRetract {1,2}= tempVDeflaction';

fclose(fileId);

% sweep corrupted files if they are still opened
fclose('all');

