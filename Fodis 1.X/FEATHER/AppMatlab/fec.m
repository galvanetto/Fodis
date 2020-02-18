classdef fec
   properties
      time
      separation
      force
      trigger_time
      dwell_time
      spring_constant
   end
   methods
      function obj = fec(time,separation,force,trigger_time,dwell_time,...
                         spring_constant)
            %{
            constructor for object

            Args:
                time/separation/force: for the force-extension curve
                <trigger/dwell>_time: the time at which the approach ends /
                the dwell starts
                         
                spring constant: of the approach          
            Returns:
                constructed force-extension curve object
            %}                     
            obj.time = time;
            obj.separation = separation;
            obj.force = force;
            obj.trigger_time = trigger_time;
            obj.dwell_time = dwell_time;
            obj.spring_constant = spring_constant;
      end
   end
end
