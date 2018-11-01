function Value=extractParameterValue(listString,ParameterName)

try
    dataIndex = ~cellfun('isempty', strfind(listString,ParameterName)); %Number Points extend
    dataString=listString(dataIndex);
    dataStringSplit=strsplit(dataString{1},'=');
    Value=dataStringSplit{end};
catch e
    Value=-1;
end