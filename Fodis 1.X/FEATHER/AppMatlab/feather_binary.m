function [python_binary] = feather_binary()
    %{
    Returns: 
        python_binary: the location of the python binary. throws an error
            if it can't be found. 
    %}
    if (ismac)
        python_binary = [filesep filesep 'anaconda' filesep 'bin' ...
                         filesep 'python2' ];
    else
        python_binary = ['C:' filesep 'ProgramData' filesep ...
                        'Anaconda2' filesep 'python.exe'];        
    end
    % see: 
    % mathworks.com/matlabcentral/answers/49414-check-if-a-file-exists
    file_exists = (exist(python_binary, 'file') == 2);
    err_msg = ['Could not find python binary where expected (' ...  
                python_binary  ')'];
    assert(file_exists,err_msg);
end