

function [] = assert_m_file_exists(f)
    msg = ['Could not load file [' f '], since it does not exist.'];
    assert(exist(f, 'file') == 2,msg)
end