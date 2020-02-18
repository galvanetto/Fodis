function [indices] = feather(fec_obj,opt)
    %{
    interface to call FEATHER

    Args:
        fec_obj: 'fec.m' object
        opt    : 'feather_options.m' object
    Returns:
        indices: list of indices into fec_obj.Time at which an event
        is predicted
    %}
    % save out the fec 
    struct_to_save = {};
    struct_to_save.time = fec_obj.time;
    struct_to_save.separation = fec_obj.separation;
    struct_to_save.force = fec_obj.force;
    % create the temporary files
    %% Necessary to put " " because Yoga 3 folder has a space and system() doesn't like the spaces in the folder
    matlab_file = [opt.base_path,'tmp.mat'];
    output_file = ['"' opt.base_path,'out.csv' '"'];
    input_file = ['"' opt.base_path,'main_feather.py' '"'];
    save(matlab_file,'-struct','struct_to_save','-v7.3');
    matlab_file = ['"' opt.base_path,'tmp.mat' '"'];
    %%
    python_binary = opt.python_binary;
    [status,~] = system([python_binary ' --version']);
    % check that the binary exists
    if (status ~= 0)
       msg = ['Could not find python binary at ' python_binary '.'];
       msg = [msg ' Please check the python location.'];
       error(msg);
    end
    % make the initial command and just run the file by itself..
    command = [python_binary ' ' input_file ];
    [status,~] = system(command);
    command = append_numeric(command,...
                             '-spring_constant',fec_obj.spring_constant);
    command = append_numeric(command,...
                             '-trigger_time',fec_obj.trigger_time);   
    command = append_numeric(command,...
                             '-dwell_time',fec_obj.dwell_time);    
    command = append_numeric(command,...
                             '-threshold',opt.threshold);      
    command = append_numeric(command,...
                             '-tau',opt.tau);    
    command = append_argument(command,...
                              '-file_input',matlab_file);                          
    command = append_argument(command,...
                              '-file_output',output_file);                             
    [~,~] = system(command);
    % read, skipping the first two rows 
    %% Necessary to remove " " because Yoga 3 folder has a space
    output_file = [opt.base_path,'out.csv'];
    matlab_file = [opt.base_path,'tmp.mat'];
    indices = csvread(output_file,2,0);
    % clean up the intermediates
    delete(matlab_file);
    delete(output_file);
end
    
function[output]=append_numeric(output,name,value)
    %{
    Append a numeric argument to a string

    Args:
        see : append_argument, execpt converts value to a numeric
    Returns:
        see append_argument
    %}
    output = append_argument(output,name,num2str(value,'%15.7g'));
end

function[output]=append_argument(output,name,value)
    %{
    Append an argument to a string

    Args:
        output: what to append to
        name: name to append to 
    
        value: what to add after name
    Returns:
        like <output><space><name><space><value>
    %}
    output = [output,' ',name,' ',value];
end
