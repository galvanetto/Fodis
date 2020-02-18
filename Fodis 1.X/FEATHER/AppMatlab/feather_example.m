function [indices]=feather_example(T,X,F,trigger_time)
    %{
    example which uses FEATHER.

    Path must be set properly 
    %}
    feather_assertions();
    
    Folder = what('FEATHER');
     
    base_feather_dir = Folder.path;
    % read the input file
    
    base_path = [base_feather_dir filesep 'AppPython' filesep];
    
    %% Constants to be defined
    trigger_time;                %is the length of the flat noise 
    dwell_time=0;                %is the time of contact
    spring_constant=0.084;
    
    
    
    %% get the individual columns, for plotting purposes
    time = T';
    separation = X';
    force = -F';
    
    %% get the force extension curve object to use
    obj = fec(time,separation,force,trigger_time,dwell_time,...
              spring_constant);
          
    % get the feather-specific options to use
    threshold = 1e-3;
    tau = 1e-3;
    python_binary = feather_binary();
    opt = feather_options(threshold,tau,base_path,python_binary);
    
    % get the predicted event locations
    indices=[];
    try
        indices = feather(obj,opt);
    catch
    end
    
end
