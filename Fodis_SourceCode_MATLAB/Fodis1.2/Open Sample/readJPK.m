function [tracesExtend,tracesRetract] = readJPK(files,ii)

tracesExtend = cell(1, 2);
tracesRetract = cell(1, 2);

f=filesep;                              %Filseparatore (differ from system)
tmpName = tempname;                     %Assign a temporary name to the extracted folder

try
    filenames=unzip(files{ii},[tmpName f files{ii}]);
catch e
    disp('Problem during extraction of file')
    return;
end

disp(['File Written to' tmpName])

filenamesCutted=filenames;

%Remove part of path not necessary 'path-until the filename'
for i=1:length(filenames)
    
    stringActualFilename=filenamesCutted{i};
    lengthFolderTemp=length(tmpName);
    
    indexStartNameFile=strfind(stringActualFilename,tmpName);
    
    if ~isempty(indexStartNameFile)
        stringActualFilenameCutted = stringActualFilename(indexStartNameFile+lengthFolderTemp:end);
        filenamesCutted{i}=stringActualFilenameCutted;
    end
end


%Extract number of segment
segmentFilenameLocation=find(~cellfun('isempty',strfind(filenamesCutted, 'segments')));

%Exclude all Directory (not file).
validSegmentLocationIndex=ones(1,length(segmentFilenameLocation)); %Vector of valid file. 1 valid, 0 not valid
segmentNumber=zeros(1,length(segmentFilenameLocation));

for jj=1:length(segmentFilenameLocation)
    
    if isdir(filenamesCutted{segmentFilenameLocation(jj)})                         %Directory ->nothing to search
        validSegmentLocationIndex(jj)=0;
        segmentNumber(jj)=-1;
    else                                                                   %File extract number of segment
        
        actualFilename=filenamesCutted{segmentFilenameLocation(jj)};
        
        separatorInSegmentFilename=strfind(actualFilename,f);
        segmentInSegmentFilename=strfind(actualFilename,'segment');
        
        separatorPreSegmentNumberIndex=find(separatorInSegmentFilename>segmentInSegmentFilename(1));        %Separator before of the name of the segment
        separatorPreSegmentNumber=separatorInSegmentFilename(separatorPreSegmentNumberIndex(1));
        
        separatorPostSegmentNumberIndex=find(separatorInSegmentFilename>separatorPreSegmentNumber);      %Separator after of the name of the segment
        separatorPostSegmentNumber=separatorInSegmentFilename(separatorPostSegmentNumberIndex(1));
        
        segmentNumber(jj)=str2double(actualFilename(separatorPreSegmentNumber+1:separatorPostSegmentNumber-1));
        
    end
end

generalHeaderLocation=~cellfun('isempty',strfind(filenamesCutted, [files{ii} f 'header.properties']));
[extendLength,retractLength,extendPauseLength,retractPauseLength]=extractGeneralHeaderInformation(filenames(generalHeaderLocation));

numberOfSegment=max(segmentNumber);
check=0;

for kk=0:numberOfSegment
    
    allFilenameInActualSegment=filenames(segmentFilenameLocation(segmentNumber==kk));
    
    %     [segmentType]=extractSegmentHeaderInformation(allFilenameInSegment(segmentHeader))
    %Extract segment header general header and read information about length of segment
    
    segmentHeader=~cellfun('isempty',strfind(allFilenameInActualSegment, 'header'));
    openSegmentHeaderFile = fopen(char(allFilenameInActualSegment(segmentHeader)), 'r');
    dataSegmentHeader = textscan(openSegmentHeaderFile, '%s', 'delimiter', '\n');
    
    segmentTypeIndex = ~cellfun('isempty', strfind(dataSegmentHeader{1}, 'force-segment-header.settings.style'));
    segmentTypeLine=strsplit(dataSegmentHeader{1}{segmentTypeIndex},'=');
    segmentType=segmentTypeLine{end};
    
    switch segmentType
        case 'retract'
            %% search for available name
            segmentColumnsIndex = ~cellfun('isempty', strfind(dataSegmentHeader{1}, 'channels.list'));
            segmentColumnLine = strsplit(dataSegmentHeader{1}{segmentColumnsIndex},'=');
            segmentColumns = segmentColumnLine{end};
            columnsName = strsplit(segmentColumns,' ');
            
            columnsPossibleName={'vDeflection','tipSampleSeparation','smoothedCapacitiveSensorHeight',...
                'capacitiveSensorHeight','measuredHeight','height'};
            IndexColumnAvailable=zeros(3,6);
            for jj=1:length(columnsName)
                valueInList = find(cellfun('isempty', strfind(columnsPossibleName, columnsName{jj})) == 0);
                indexInFilename=find(cellfun('isempty', strfind(allFilenameInActualSegment, columnsName{jj})) == 0);
                IndexColumnAvailable(1,valueInList)=1;      %1 if the possible name is present is equal to 1, 0 otherwise
                IndexColumnAvailable(2,valueInList)=jj;     %if there is put a position on the second value
                IndexColumnAvailable(3,valueInList) = indexInFilename;
            end
            %% Search for Vdeflection
            indexYValue=0;
            
            if (IndexColumnAvailable(1,1)==0)
                disp(['Cannot Find VDeflection in File: ' files{ii}]);
                fclose(fileId);
                return;
            else
                indexYValue=IndexColumnAvailable(3,1);
            end
            
            %% Search for good VDeflection
            indexXValue=0;
            validIndex=find(IndexColumnAvailable(1,2:end));
            
            if isempty(validIndex)
                disp(['Not Found Any valid format in File: ' files{ii}]);
                return;
            else
                indexXValue=IndexColumnAvailable(3,1+validIndex(1));
                if validIndex(1)~=2; disp(['Tip Sample Separation not found in File: ' files{ii}]);end
            end
            
            % Seearch for good xaxis
            fidtss=fopen(char(allFilenameInActualSegment{indexXValue}),'r','b','UTF-8');
            xAxisValue=fread(fidtss,'float32');
            retractTipSampleSeparation = xAxisValue-min(xAxisValue(:));
                                
            fidF=fopen(char(allFilenameInActualSegment(indexYValue)),'r','b','UTF-8');
            Fdata=fread(fidF,'float32');
            retractVDeflaction = Fdata.*1E-9;

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

