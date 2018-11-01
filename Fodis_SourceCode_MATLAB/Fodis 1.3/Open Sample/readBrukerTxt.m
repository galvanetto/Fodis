function [tracesExtend,tracesRetract] = readBrukerTxt(file)

%Read BRUKER 
tracesExtend = cell(1, 2);
tracesRetract = cell(1, 2);

% open the file normally
fileId = fopen(file, 'r');
% read data from file
data = textscan(fileId, '%s', 'delimiter', '\n');
data = data{1};
data = data(~cellfun('isempty', data'));

firstCharacterList = cellfun(@(s)s(1:2),data,'UniformOutput',false);

headerRetractIndex = cellfun('isempty', strfind(firstCharacterList, '"\')) == 0;                %All segment in file
headerString=data(headerRetractIndex);
headerNumber=length(headerString);

if (headerNumber==0)
   
    header=data{1};
    headerUnit=strsplit(header,'\t');
    headerUnitActual = strtrim(headerUnit);

    
    numericData=data(2:end);
    numericValue=cell2mat(cellfun(@str2num,numericData,'un',0));  
    numericValueScaled=numericValue;
    
    for ii=1:length(headerUnit)
            
       
        unitValue=headerUnitActual{ii};
        unitMoltiplicator=convertInExponential(unitValue(1));
        
        numericValueScaled(:,ii)=numericValue(:,ii)*unitMoltiplicator;
        
    end
    
    tracesExtend{1,1} = zeros(size(numericValue))';
    tracesExtend{1,2}= zeros(size(numericValue))';
    tracesRetract{1,1} = numericValueScaled(:,1)';
    tracesRetract {1,2}=  numericValueScaled(:,2)';

else
    dataString=data(~headerRetractIndex);
    numericValue=cell2mat(cellfun(@str2num,dataString,'un',0));
    numericValueScaled=numericValue;

    header=dataString{1};
    headerUnit=strsplit(header,'\t');
    headerUnitActual = strtrim(headerUnit);
    
    headerRetractIndex = cellfun('isempty', strfind(headerUnitActual, 'Rt')) == 0;               
    headerNewtonIndex = cellfun('isempty', strfind(headerUnitActual, 'N_')) == 0;                
    headerMeterIndex = cellfun('isempty', strfind(headerUnitActual, 'm_')) == 0;                
    headerDeflectionIndex = cellfun('isempty', strfind(headerUnitActual, 'Defl')) == 0;                
    headerPositionIndex = cellfun('isempty', strfind(headerUnitActual, 'Z_')) == 0; 
    headerSensIndex = cellfun('isempty', strfind(headerUnitActual, 'ensor')) == 0;

    ColumnX=find(headerRetractIndex & headerMeterIndex & headerPositionIndex);
    ColumnY=find(headerRetractIndex & headerNewtonIndex & headerDeflectionIndex);
    
    if isempty(ColumnY)
        ColumnY=find(headerRetractIndex & headerMeterIndex & headerDeflectionIndex);
    end
    
    if isempty(ColumnY)
        ColumnY=find(headerRetractIndex & headerDeflectionIndex);
    end
    
    if isempty(ColumnX)
        ColumnY=find(headerRetractIndex & headerSensIndex);
    end
    
    
    
    headerSplitX=strsplit(headerUnitActual{ColumnX(1)},'_');
    headerUnitX=headerSplitX{end-1};
    unitMoltiplicatorX=convertInExponential(headerUnitX(1));
    
    numericValueScaled(:,ColumnX(1))=numericValue(:,ColumnX(1))*unitMoltiplicatorX;
    
    headerSplitY=strsplit(headerUnitActual{ColumnY(1)},'_');
    headerUnitY=headerSplitY{end-1};
    unitMoltiplicatorY=convertInExponential(headerUnitY(1));
    
    numericValueScaled(:,ColumnY(1))=numericValue(:,ColumnY(1))*unitMoltiplicatorY;
    
    tracesExtend{1,1} = zeros(size(numericValue))';
    tracesExtend{1,2}= zeros(size(numericValue))';
    tracesRetract{1,1} = numericValueScaled(:,ColumnX(1))';
    tracesRetract {1,2}=  numericValueScaled(:,ColumnY(1))';
    
    
    fclose(fileId);

end

% 
