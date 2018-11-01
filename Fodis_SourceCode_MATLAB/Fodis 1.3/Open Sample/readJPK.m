function [tracesExtend,tracesRetract] = readJPK(file)

%Preallocate cell for put the traces
tracesExtend = cell(1, 2);
tracesRetract = cell(1, 2);
sharedHeaderPresence=0;

f=filesep;                              %Filseparatore (differ from system)
tmpName = tempname;                     %Assign a temporary name to the extracted folder

%Unzip jpk-force
try
    filenames=unzip(file,[tmpName f file]);
catch e
    disp('Problem during extraction of file')
    return;
end

% disp(['File Written to' tmpName])

%Remove part of path not necessary 'path-until the filename'
filenamesCutted=filenames;
for i=1:length(filenames)
    
    stringActualFilename=filenamesCutted{i};
    lengthFolderTemp=length(tmpName);
    
    indexStartNameFile=strfind(stringActualFilename,tmpName);
    
    if ~isempty(indexStartNameFile)
        stringActualFilenameCutted = stringActualFilename(indexStartNameFile+lengthFolderTemp:end);
        filenamesCutted{i}=stringActualFilenameCutted;
    end
end

%% Extract general headerInformation
generalHeaderLocation=~cellfun('isempty',strfind(filenamesCutted, [file f 'header.properties']));
[extendLength,retractLength,extendPauseLength,retractPauseLength]=extractGeneralHeaderInformation(filenames(generalHeaderLocation));

%% Extract sharedData headerInformation
sharedHeaderLocation=~cellfun('isempty',strfind(filenamesCutted, ['shared-data' f 'header.properties']));

if ~isempty(find(sharedHeaderLocation,1))
    structChannel=extractSharedHeaderInformation(filenames(sharedHeaderLocation));
    sharedHeaderPresence=1;
end

%% Extract number of segment
segmentFilenameLocation=find(~cellfun('isempty',strfind(filenamesCutted, 'segments')));

%Exclude all Directory (not file).
validSegmentLocationIndex=ones(1,length(segmentFilenameLocation)); %Vector of valid file. 1 valid, 0 not valid
segmentNumber=zeros(1,length(segmentFilenameLocation));

for jj=1:length(segmentFilenameLocation)
    
    if isdir(filenames{segmentFilenameLocation(jj)})                       %Directory ->nothing to search
        validSegmentLocationIndex(jj)=0;
        segmentNumber(jj)=-1;
        
    else
        % Extract number of segments
        actualFilename=filenamesCutted{segmentFilenameLocation(jj)};
        
        separatorInSegmentFilename=strfind(actualFilename,f);
        segmentInSegmentFilename=strfind(actualFilename,'segment');
        
        separatorPreSegmentNumberIndex=find(separatorInSegmentFilename>segmentInSegmentFilename(1));     %Separator before of the number of the segment
        separatorPreSegmentNumber=separatorInSegmentFilename(separatorPreSegmentNumberIndex(1));
        
        separatorPostSegmentNumberIndex=find(separatorInSegmentFilename>separatorPreSegmentNumber);      %Separator after of the number of the segment
        separatorPostSegmentNumber=separatorInSegmentFilename(separatorPostSegmentNumberIndex(1));
        
        segmentNumber(jj)=str2double(actualFilename(separatorPreSegmentNumber+1:separatorPostSegmentNumber-1)); %All number of segment present in file
        
    end
end


for kk=0:max(segmentNumber)
    
    allFilenameInActualSegment=filenames(segmentFilenameLocation(segmentNumber==kk));
    
    segmentHeader=~cellfun('isempty',strfind(allFilenameInActualSegment, 'header'));
    openSegmentHeaderFile = fopen(char(allFilenameInActualSegment(segmentHeader)), 'r');
    dataSegmentHeader = textscan(openSegmentHeaderFile, '%s', 'delimiter', '\n');
    
    segmentType=extractParameterValue(dataSegmentHeader{1},'force-segment-header.settings.style');
    
    switch segmentType
        case 'retract'   %Keep research only if the segment is retract. The other are leaved
          
            % search for available Channel            
            columnsPossibleName={'vDeflection','tipSampleSeparation','verticalTipPosition','smoothedCapacitiveSensorHeight',...
                'capacitiveSensorHeight','measuredHeight','height'};
            
            segmentColumns=extractParameterValue(dataSegmentHeader{1}, 'channels.list');
            columnsName = strsplit(segmentColumns,' ');
            
            %Extract information on recorded channel
            IndexColumnAvailable=zeros(3,length(columnsPossibleName));
            
            for jj=1:length(columnsName)
                
                valueInList = find(cellfun('isempty', strfind(columnsPossibleName, columnsName{jj})) == 0);         %Search which column are present
                indexInFilename=find(cellfun('isempty', strfind(allFilenameInActualSegment, [f columnsName{jj}])) == 0);%And where is the filename with that info
                
                if (find(valueInList,1))
                    IndexColumnAvailable(1,valueInList) = 1;                   % 1 if the possible name is present is equal to 1, 0 otherwise
                    IndexColumnAvailable(2,valueInList) = jj;                  % if there is put a position on the second value
                    IndexColumnAvailable(3,valueInList) = indexInFilename;     % Put the filename position of the value
                end
            end
            
            %% Search for yaxis (VDeflection)
            indexYValue=0;
            indexYValueFormat=0;
            
            if (IndexColumnAvailable(1,1)==0)
                disp(['Cannot Find VDeflection in File: ' file]);
                fclose(fileId);
                return;
            else
                indexYValue=IndexColumnAvailable(3,1);
                indexYValueFormat=IndexColumnAvailable(2,1);
            end
            
            %% Search for good xaxis (tip-sample separation)
            indexXValue=0;
            indexXValueFormat=0;
            
            validIndex=find(IndexColumnAvailable(1,2:end));
            
            if isempty(validIndex)
                disp(['Not Found Any valid format in File: ' file]);
                return;
            else
                indexXValue=IndexColumnAvailable(3,1+validIndex(1));
                indexXValueFormat=IndexColumnAvailable(2,1+validIndex(1));
                disp(['Loaded Channel: ' columnsPossibleName{1+validIndex(1)}]);

%                 if validIndex(1)~=2; disp(['Tip Sample Separation not found in File: ' file]);end
            end
            
            %Extract Format
            yChannelName=columnsName{indexYValueFormat};
            xChannelName=columnsName{indexXValueFormat};
            
            if (sharedHeaderPresence)
    
                yChannel=extractParameterValue(dataSegmentHeader{1},['channel.' yChannelName '.lcd-info']);
                yFormat=structChannel.(['Channel' yChannel]).format;
                yMultiplier=structChannel.(['Channel' yChannel]).multiplier.Total;
                
                xChannel=extractParameterValue(dataSegmentHeader{1},['channel.' xChannelName '.lcd-info']);
                xFormat=structChannel.(['Channel' xChannel]).format;
                xMultiplier=structChannel.(['Channel' xChannel]).multiplier.Total;
                
            else  %%Versione old pre 2011
                
                yStructChannel=extractSegmentHeaderInformation(allFilenameInActualSegment(segmentHeader),yChannelName);
                yFormat=yStructChannel.(yChannelName).format;
                yMultiplier=yStructChannel.(yChannelName).multiplier.Total;
                
                xStructChannel=extractSegmentHeaderInformation(allFilenameInActualSegment(segmentHeader),xChannelName);
                xFormat=xStructChannel.(xChannelName).format;
                xMultiplier=xStructChannel.(xChannelName).multiplier.Total;
                              
            end
            
            
            % Seearch for good xaxis
            fidtss=fopen(char(allFilenameInActualSegment{indexXValue}),'r','b','UTF-8');
            xAxisValue=fread(fidtss,xFormat);
            retractTipSampleSeparation =xMultiplier*xAxisValue-min(xMultiplier*xAxisValue);
            
            fidF=fopen(char(allFilenameInActualSegment(indexYValue)),'r','b','UTF-8');
            Fdata=fread(fidF,yFormat);
            retractVDeflaction = yMultiplier*Fdata;
            
    end
end

tracesRetract{1,1} = retractTipSampleSeparation';
tracesRetract {1,2}= retractVDeflaction';
tracesExtend{1,1} = zeros(size(retractTipSampleSeparation'));
tracesExtend{1,2}= zeros(size(retractVDeflaction'));

fclose(fidF);
fclose(fidtss);
fclose('all');
rmdir(tmpName,'s')

