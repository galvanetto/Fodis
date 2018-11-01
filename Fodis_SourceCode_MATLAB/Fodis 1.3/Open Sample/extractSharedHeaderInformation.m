function structChannel=extractSharedHeaderInformation(filename)

%Open File
readHeader = fopen(char(filename), 'r');
%Read File
dataSharedHeader = textscan(readHeader, '%s', 'delimiter', '\n');

%Find all lcd-info line end extract it
extendLengthIndex = ~cellfun('isempty', strfind(dataSharedHeader{1},'lcd-info.'));
dataValidSharedHeader=dataSharedHeader{1}(extendLengthIndex);

allChannelNumber=zeros(1,length(dataValidSharedHeader));                   %All channel in the file
for ii=1:length(dataValidSharedHeader)
    
    %Extract the first number for each string : the channel 
    allChannelNumber(ii) = str2double(regexp(dataValidSharedHeader{ii}, '\d', 'match', 'once' )) ; 
    
end

%Extract the list of possible channel
allDifferentChannelNumber=unique(allChannelNumber);

for jj=1:length(allDifferentChannelNumber)
    
    %Extract all the string for the channel analyzed
    actualChannel=allDifferentChannelNumber(jj);
    allEntryThisChannelIndex=allChannelNumber==actualChannel;
    allEntryThisChannel=dataValidSharedHeader(allEntryThisChannelIndex);
    
    % Channel Type
    dataType=extractParameterValue(allEntryThisChannel,['lcd-info.' num2str(actualChannel) '.type']);
    structChannel.(['Channel' num2str(actualChannel)]).dataType=dataType;
     
    % Channel Name
    dataName=extractParameterValue(allEntryThisChannel,['lcd-info.' num2str(actualChannel) '.channel.name']);
    structChannel.(['Channel' num2str(actualChannel)]).dataName=dataName;
    
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
        
        cumulativeMultiplier=cumulativeMultiplier*str2double(dataMultiplier);

        dataMultiplierName=strsplit(dataMultiplierStringSplit{1},'.');     %Extract valid name for struct
        structChannel.(['Channel' num2str(actualChannel)]).multiplier.(dataMultiplierName{end-2})=dataMultiplier;
        
    end
    
    structChannel.(['Channel' num2str(actualChannel)]).multiplier.Total=cumulativeMultiplier;
    
    %%Encoder
    dataEncoderIndex= ~cellfun('isempty', strfind(allEntryThisChannel,['lcd-info.' num2str(actualChannel) '.encoder.type'])); %Number Points extend
    if ~isempty(find(dataEncoderIndex,1))
        
        %Encoder Type
        dataEncoder=extractParameterValue(allEntryThisChannel,['lcd-info.' num2str(actualChannel) '.encoder.type']);
        structChannel.(['Channel' num2str(actualChannel)]).dataEncoder=dataEncoder;
       
        %Encoder Offset
        dataEncoderOffset=extractParameterValue(allEntryThisChannel,['lcd-info.' num2str(actualChannel) '.encoder.scaling.offset']);
        structChannel.(['Channel' num2str(actualChannel)]).dataEncoderOffset=dataEncoderOffset;

        %Encoder Multiplier
        dataEncoderMultiplier=extractParameterValue(allEntryThisChannel,['lcd-info.' num2str(actualChannel) '.encoder.scaling.multiplier']);
        structChannel.(['Channel' num2str(actualChannel)]).dataEncoderMultiplier=dataEncoderMultiplier;
        
        %Encoder TotalMultiplier
        structChannel.(['Channel' num2str(actualChannel)]).multiplier.Total=cumulativeMultiplier*str2double(dataEncoderMultiplier);
        
    else
        structChannel.(['Channel' num2str(actualChannel)]).dataEncoder='';
    end
    
    %Extract Format
    format=extractFormat(dataType,dataEncoder);
    structChannel.(['Channel' num2str(actualChannel)]).format=format;
    
end
