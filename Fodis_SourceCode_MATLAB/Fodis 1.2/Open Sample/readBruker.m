function [tracesExtend,tracesRetract] = readBruker(file)

%Read BRUKER 
tracesExtend = cell(1, 2);
tracesRetract = cell(1, 2);

% open the file normally
fileId = fopen(file, 'r');
% read data from file
data = textscan(fileId, '%s', 'delimiter', '\n');
data = data{1};
data = data(~cellfun('isempty', data'));

firstCharacterList = cellfun(@(s)s(1),data,'UniformOutput',false);

headerIndex = cellfun('isempty', strfind(firstCharacterList, '\')) == 0;                %All segment in file
headerString=data(headerIndex);
headerNumber=length(headerString);
dataString=data(~headerIndex);

fidtss=fopen(file,'r','b','UTF-8');
C = textscan(fidtss, '%u16' ,4000,'HeaderLines',headerNumber,'Delimiter',',');

data=fread(fidtss,'float32');

tracesExtend{1,1} = data{:,1}'*1e-9;
tracesExtend{1,2}= data{:,2}'*1e-9;
tracesRetract{1,1} = data{:,1}'*1e-9;
tracesRetract {1,2}= data{:,2}'*1e-9;

fclose(fileId);

% sweep corrupted files if they are still opened
fclose('all');
