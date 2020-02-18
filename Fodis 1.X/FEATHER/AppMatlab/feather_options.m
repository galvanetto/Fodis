classdef feather_options
   properties
        threshold
        tau
        base_path
        python_binary
   end
   methods
      function obj = feather_options(threshold,tau,base_path,python_binary)
            %{
            constructor for object

            Args:
                threshold: probability threshold which feather uses (0,1)
                tau: fractional smoothing (0,1)         
                base_path: location of the python code
                python_binary: where the python binary lives
            Returns:
                constructed feather options object
            %} 
            obj.threshold = threshold;
            obj.tau = tau;
            obj.base_path = base_path;
            obj.python_binary = python_binary;
      end
   end
end
