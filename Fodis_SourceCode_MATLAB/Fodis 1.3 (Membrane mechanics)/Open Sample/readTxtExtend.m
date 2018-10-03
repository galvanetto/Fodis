function [tracesExtend,tracesRetract,position] = readTxtExtend(file)
%read the extension curve (indended for spectroscopy of the membrane, i.e.
%membrane breking force)
%in the code variables, Retract stays for Extend for working reasons)!!!




%Read JPK-force .txt
tracesExtend = cell(1, 2);
tracesRetract = cell(1, 2);
position=[0 0];

% open a file
fileId = fopen(file, 'r');
% read data from file
dataLocal = textscan(fileId, '%s', 'delimiter', '\n');
dataLocal = dataLocal{1};
dataLocal = dataLocal(~cellfun('isempty', dataLocal'));

% get idx units, columns, startData, endData
idxAllSegment = find(cellfun('isempty', strfind(dataLocal, '# segment: ')) == 0);                %All segment in file
idxSegmentRetract = find(cellfun('isempty', strfind(dataLocal, '# segment: extend')) == 0);     %All Segment retract in file
idxColumns = find(cellfun('isempty', strfind(dataLocal, '# columns: ')) == 0);                   %All Columns in file
idxUnits = find(cellfun('isempty', strfind(dataLocal, '# units: ')) == 0);                       %All Units in file


%Only the one after the segment beginning
idxColumnsValid=find(idxColumns>idxSegmentRetract(1));                     %Find columns of the first segment retract
idxUnitsValid=find(idxUnits>idxSegmentRetract(1));                         %Find units of the first segment retract
idxNextSegment=idxAllSegment( find(idxAllSegment>idxSegmentRetract(1)) );  %Find beginning of the segment after segment retract

idxNumberData = find(cellfun('isempty', strfind(dataLocal, '#')));              %Not Header-->data
idxStartData=find(idxNumberData>idxSegmentRetract(1));                     %Start data of segment retract      

if ~isempty(idxColumnsValid)
    idxColumnsRetract=idxColumns(idxColumnsValid(1));                      %Line of "columns" of segment retract                       
    idxUnitsRetract=idxUnits(idxUnitsValid(1));                            %Line of "units" of segment retract
    idxStartDataRetract=idxNumberData(idxStartData(1));                    %Line of "data" of segment retract
    
    if ~isempty(idxNextSegment) %there is a segment after retract
        
        %Line of data between beginning of data retract and before the
        %beginning of next segmnent
        idxEndData=find(idxNumberData>idxStartDataRetract & idxNumberData<idxNextSegment(1)); 
        
        idxEndDataRetract=idxNumberData(idxEndData(end));                  %End data of segment retract      
    else
        idxEndDataRetract=idxNumberData(end);                              %Segment retract is the last so the end of data is the
                                                                           % end of data of segment retract
    end
    
else %Not found any column
    disp(['Bad file skipped (invalid format, cannot find retract Section): ' file]);
    fclose(fileId);
    return;

end

columnsAvailable=dataLocal{idxColumnsRetract};
indxStartListColumns=strfind(columnsAvailable,':');
columnsAvailable=columnsAvailable(indxStartListColumns+1:end);             %Column available for retract

columnsName = textscan(columnsAvailable, '%s');                            %Devide the name
if isempty(columnsName)
    disp(['Bad file skipped (invalid format, cannot find available Column): ' file]);
    fclose(fileId);
    return;
end

% #1 vDeflection
% #2 tipSampleSeparation
% #3 smoothedCapacitiveSensorHeight
% #4 capacitiveSensorHeight
% #5 measuredHeight
% #6 height

%% search for available name
columnsPossibleName={'vDeflection','tipSampleSeparation','verticalTipPosition','smoothedCapacitiveSensorHeight',...
    'capacitiveSensorHeight','measuredHeight','height'};
IndexColumnAvailable=zeros(2,length(columnsPossibleName));

for jj=1:length(columnsName{1})
    valueInList = find(cellfun('isempty', strfind(columnsPossibleName, columnsName{1}{jj})) == 0);
    IndexColumnAvailable(1,valueInList)=1;      %1 if the possible name is present is equal to 1, 0 otherwise
    IndexColumnAvailable(2,valueInList)=jj;     %if there is put a position on the second value
end


%% Search for Vdeflection
indexYValue=0;
if (IndexColumnAvailable(1,1)==0)
    disp(['Cannot Find VDeflection in File: ' file]);
    fclose(fileId);
    return;
else
    indexYValue=IndexColumnAvailable(2,1);
end


%% Search position of the force spectrum

idxXpos=find(cellfun('isempty', strfind(dataLocal, '# xPosition: ')) == 0);
idxYpos=find(cellfun('isempty', strfind(dataLocal, '# yPosition: ')) == 0);

stringXposition=strsplit(dataLocal{idxXpos(1)},':');
stringYposition=strsplit(dataLocal{idxYpos(1)},':');

position(1)=str2double(stringXposition{end});
position(2)=str2double(stringYposition{end});




%% Search for good x axis

indexXValue=0;
validIndex=find(IndexColumnAvailable(1,2:end));

if isempty(validIndex)
     disp(['Not Found Any valid format in File: ' file]); 
     return;
else
    indexXValue=IndexColumnAvailable(2,1+validIndex(1));
    disp(['Loaded Channel: ' columnsPossibleName{1+validIndex(1)}]);
end

tempData = dataLocal(idxStartDataRetract:1:idxEndDataRetract);                  %Extract numeric data of retract
NumericMatrix=cell2mat(cellfun(@str2num,tempData,'un',0));                 %Put all data in a matrix

tempVDeflaction =NumericMatrix(:,indexYValue);                             %Extract Vdeflection                              
tempTipSampleSeparation = NumericMatrix(:,indexXValue);                    %Extract second value (called tip sample sep for previous version)

%% Generate Output
tracesExtend{1,1} = zeros(size(tempTipSampleSeparation))';
tracesExtend{1,2}= zeros(size(tempVDeflaction))';
tracesRetract{1,1} = tempTipSampleSeparation';
tracesRetract {1,2}= -tempVDeflaction';

fclose(fileId);

% sweep corrupted files if they are still opened
fclose('all');

