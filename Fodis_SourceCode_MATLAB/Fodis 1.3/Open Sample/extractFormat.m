function format=extractFormat(dataType,dataEncoder)

if (strcmp(dataType,'raster-data'))
    format='';
    
elseif (strcmp(dataType,'float-data') ||strcmp(dataType,'float'))
    format='float32';
    

elseif (strcmp(dataType,'integer-data') ||strcmp(dataType,'memory-integer-data'))  %%32bit
    if strcmp(dataEncoder,'signedinteger') || strcmp(dataEncoder,'signedinteger-limited')
        format='int32';
    elseif strcmp(dataEncoder,'unsignedinteger') || strcmp(dataEncoder,'unsignedinteger-limited')
        format='uint32';
    end           
elseif (strcmp(dataType,'short-data') || strcmp(dataType,'memory-short-data') || strcmp(dataType,'short'))  %%16bit
    
    if strcmp(dataEncoder,'signedshort') || strcmp(dataEncoder,'``signedshort-limited')
            format='int16';
    elseif strcmp(dataEncoder,'unsignedshort') || strcmp(dataEncoder,'unsignedshort-limited')
            format='uint16';
    end

end    