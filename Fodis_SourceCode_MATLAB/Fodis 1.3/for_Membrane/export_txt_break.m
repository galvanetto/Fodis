function export_txt_break(pf)
% Export traces

[filename, pathname] = uiputfile({'*.txt'}, 'Export traces');

if (filename == 0);return;end
h = waitbar(0, 'Please wait');







fid = fopen(fullfile(pathname, filename), 'w');


waitbar(0.2);


    
    
    fprintf(fid, '%g %g\n', pf');
   
    



fclose(fid);
waitbar(1);
delete(h);
