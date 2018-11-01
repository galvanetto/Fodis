function export_Traces_append(data)
% Export traces

[filename, pathname] = uiputfile({'*.txt'}, 'Export traces');

if (filename == 0);return;end
h = waitbar(0, 'Please wait');

jj = 1;
% strWaves = [];
maxLength = -Inf;

for ii = 1:1:data.nTraces
    tempLength = length(data.tracesRetract{ii, 2});
    if maxLength < tempLength
        maxLength = tempLength;
    end
    
end

tracesX= [];
tracesY= [];

for ii = 1:1:data.nTraces

    y=-data.tracesRetract{ii, 2}';
    tracesY = [tracesY; y];
    
    x=data.tracesRetract{ii, 1}';
    tracesX = [tracesX; x];


end

tracesXY=[tracesX tracesY];

fid = fopen(fullfile(pathname, filename), 'w');


waitbar(0.2);


    
    
    fprintf(fid, '%g %g\n', tracesXY');
   
    



fclose(fid);
waitbar(1);
delete(h);
