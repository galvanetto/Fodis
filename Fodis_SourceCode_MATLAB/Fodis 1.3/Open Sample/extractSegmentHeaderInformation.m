function structChannel=extractSegmentHeaderInformation(filename,channelName)

%Open File
readHeader = fopen(char(filename), 'r');
%Read File
dataSegmentHeader = textscan(readHeader, '%s', 'delimiter', '\n');

allEntryThisChannelIndex = cellfun('isempty', strfind(dataSegmentHeader{1},channelName)) == 0;
allEntryThisChannel = dataSegmentHeader{1}(allEntryThisChannelIndex);

% Channel Name
dataName=channelName;
structChannel.(channelName).dataName=dataName;

% Channel Type
dataType=extractParameterValue(allEntryThisChannel,['channel.' channelName '.data.type']);
structChannel.(channelName).dataType=dataType;

% Various multiplier
dataMultiplierIndex= ~cellfun('isempty', strfind(allEntryThisChannel,'.multiplier'));
dataMultiplierString=allEntryThisChannel(dataMultiplierIndex);
cumulativeMultiplier=1;
    
    for kk=1:length(dataMultiplierString)
        
        actualMultiplierString=dataMultiplierString{kk};
        if (strfind(actualMultiplierString,'encoder')); continue; end      %If it is encoder Multiplier Continue
        
        dataMultiplierStringSplit=strsplit(actualMultiplierString,'=');
        
        if length(dataMultiplierStringSplit)<2
            dataMultiplier='1';
        else
            dataMultiplier=dataMultiplierStringSplit{end};
        end
        
        dataMultiplier=dataMultiplierStringSplit{end};
        cumulativeMultiplier=cumulativeMultiplier*str2double(dataMultiplier);
        
        dataMultiplierName=strsplit(dataMultiplierStringSplit{1},'.');     %Extract valid name for struct
        structChannel.(channelName).multiplier.(dataMultiplierName{end-2})=dataMultiplier;
        
    end
    
    structChannel.(channelName).multiplier.Total=cumulativeMultiplier;
    
    %%Encoder
    dataEncoderIndex= ~cellfun('isempty', strfind(allEntryThisChannel,['channel.' channelName '.data.encoder.type'])); %Number Points extend
    if ~isempty(find(dataEncoderIndex,1))
        
        %Encoder Type
        dataEncoder=extractParameterValue(allEntryThisChannel,['channel.' channelName '.data.encoder.type']);
        structChannel.(channelName).dataEncoder=dataEncoder;
       
        %Encoder Offset
        dataEncoderOffset=extractParameterValue(allEntryThisChannel,['channel.' channelName '.data.encoder.scaling.offset']);
        structChannel.(channelName).dataEncoderOffset=dataEncoderOffset;

        %Encoder Multiplier
        dataEncoderMultiplier=extractParameterValue(allEntryThisChannel,['channel.' channelName '.data.encoder.scaling.multiplier']);
        structChannel.(channelName).dataEncoderMultiplier=dataEncoderMultiplier;
        
        %Encoder TotalMultiplier
        structChannel.(channelName).multiplier.Total=cumulativeMultiplier*str2double(dataEncoderMultiplier);
        
    else
        structChannel.(channelName).dataEncoder='';
    end
    
    %Extract Format
    format=extractFormat(dataType,dataEncoder);
    structChannel.(channelName).format=format;
    
end
