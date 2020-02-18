function exportTracesRows(data)
% Export traces

[filename, pathname] = uiputfile({'*.txt'}, 'Export traces');

if (filename == 0);return;end
h = waitbar(0, 'Please wait');


fid = fopen(fullfile(pathname, filename), 'w');
% fprintf(fid, '%s ', strWaves{:});
% fprintf(fid, '\n');

for ii=1:data.nTraces
    y_write=mat2str(-data.tracesRetract{ii,2});
    fprintf(fid, y_write(2:end-1) );
    fprintf(fid,'\n');
    x_write=mat2str(data.tracesRetract{ii,1});
    fprintf(fid, x_write(2:end-1)  );
    fprintf(fid,'\n');
    
    disp(ii)

end

fclose(fid);
waitbar(1);
delete(h);
