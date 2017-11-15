function exportTraces(data)
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

traces = zeros(maxLength, data.nTraces * 2);

for ii = 1:1:data.nTraces
%     strWaves{jj} = ['wave', num2str(jj- 1)];
    t=-data.tracesRetract{ii, 2};
    traces(1:length(t), jj) = t;
    
%     strWaves{jj+1} = ['wave', num2str(jj)];
    t=data.tracesRetract{ii, 1};
    traces(1:length(t), jj + 1) = t;
    jj = jj +2;
    
end

fid = fopen(fullfile(pathname, filename), 'w');
% fprintf(fid, '%s ', strWaves{:});
% fprintf(fid, '\n');

for ii = 1:1:length(traces(:, 1))
    
    for jj = 1:1:(2*data.nTraces)
        t = traces(ii, jj);
        fprintf(fid, '%g ', t(isnan(t) == false));        
    end
    
     fprintf(fid, '\n');
     if mod(ii, 10) == 0;waitbar(ii / length(traces(:, 1)));end
end

fclose(fid);
waitbar(1);
delete(h);
