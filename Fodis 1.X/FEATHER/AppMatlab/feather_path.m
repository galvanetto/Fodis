function [path] = feather_path(matlab_base_dir)
    %{
    constructor for object

    Args:
        matlab_base_dir: directory housing feather_example.m lives (e.g. 
        '/AppMatlab/'
    Returns:
        path, top level, to Feather code. 
    %} 
    matches = strfind(matlab_base_dir,'AppMatlab');
    error_msg = ['Path ' matlab_base_dir ' did not include AppMatlab. ' ...
                  newline 'If running feather_example.m,' ...
                  ' be sure to run from the AppMatlab folder. ' ... 
                  'Otherwise, please correct input directory to '...
                  'feather_path.m'];
    assert(length(matches) > 0,error_msg);
    idcs   = strfind(matlab_base_dir,filesep);
    path = matlab_base_dir(1:idcs(end)-1); 
end