function [trigger_time,dwell_time,spring_constant] = ...
    feather_meta_header(input_file)
    assert_m_file_exists(input_file);
    fid = fopen(input_file,'r');
    single_line = fgetl(fid);
    expressions = {'TriggerTime','DwellTime','SpringConstant'};
    output = [];
    for i =1:length(expressions)
        tmp_expr = expressions{i};
        pattern = ['[\W]'     ... % Not a letter
                    tmp_expr    ... % the literal expression
                    '\s*:\s*'   ... % optional spaces surrounding colon
                    '([^,\s]+)' ... % any non comma or space
                    ];
        match = regexp(single_line,pattern,'tokens');
        assert(length(match) == 1,['Could not find match for ' tmp_expr ]);
        % POST: exactly one match
        match_str = match{1};
        match_float = str2double(match_str);
        msg = ['Could not convert ' match_str ' value of ' tmp_expr ...
               ' to a float'];
        assert(~isnan(match_float),msg);
        % POST: can convert the value to a float
        output = [output, match_float];
    end
    % make sure we got the right number
    assert(length(output) == 3,'Did not find the correct number');
    trigger_time = output(1);
    dwell_time= output(2);
    spring_constant = output(3);
end