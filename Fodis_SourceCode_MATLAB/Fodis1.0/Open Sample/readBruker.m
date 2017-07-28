function [tracesExtend,tracesRetract] = readBruker(files,ii)

tracesExtend = cell(1, 2);
tracesRetract = cell(1, 2);

% open a file
fileId = fopen(files{ii}, 'r');
% read data from file
data = textscan(fileId, '%f%f','HeaderLines',1);


tracesExtend{1,1} = data{:,1}'*1e-9;
tracesExtend{1,2}= data{:,2}'*1e-9;
tracesRetract{1,1} = data{:,1}'*1e-9;
tracesRetract {1,2}= data{:,2}'*1e-9;

fclose(fileId);

% sweep corrupted files if they are still opened
fclose('all');
