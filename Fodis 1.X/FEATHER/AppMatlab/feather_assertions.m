function [] = feather_assertions()
    %{
    Returns: 
        python_binary: the location of the python binary. throws an error
            if it can't be found. 
    %}
    err_msg = ['FEATHER untested on MATLAB < 2017. Detected: ' version];
    assert(~verLessThan('matlab','9'),err_msg);
    assert_m_file_exists('feather.m')
    assert_m_file_exists('feather_binary.m')
    assert_m_file_exists('feather_options.m')
    assert_m_file_exists('feather_path.m')
    assert_m_file_exists('fec.m')
end
