%Extract general header and read information about length of segment
function [extendLength,retractLength,extendPauseLength,retractPauseLength]=extractGeneralHeaderInformation(filename)

readHeader = fopen(char(filename), 'r');
dataGeneralHeader = textscan(readHeader, '%s', 'delimiter', '\n');

extendLengthIndex = ~cellfun('isempty', strfind(dataGeneralHeader{1},'extend-k-length')); %Number Points extend
extendLengthLine=strsplit(dataGeneralHeader{1}{extendLengthIndex},'=');
extendLength=str2double(extendLengthLine{end});

extendPauseLengthIndex = ~cellfun('isempty', strfind(dataGeneralHeader{1},'extended-pause-k-length')); %Number Points extend
extendPauseLengthLine=strsplit(dataGeneralHeader{1}{extendPauseLengthIndex},'=');
extendPauseLength=str2double(extendPauseLengthLine{end});

retractLengthIndex = ~cellfun('isempty', strfind(dataGeneralHeader{1},'retract-k-length')); %Number Points retract
retractLengthLine=strsplit(dataGeneralHeader{1}{retractLengthIndex},'=');
retractLength=str2double(retractLengthLine{end});

retractPauseLengthIndex = ~cellfun('isempty', strfind(dataGeneralHeader{1},'retracted-pause-k-length')); %Number Points pause
retractPauseLengthLine=strsplit(dataGeneralHeader{1}{retractPauseLengthIndex},'=');
retractPauseLength=str2double(retractPauseLengthLine{end});
