#!/bin/bash
# courtesy of: http://redsymbol.net/articles/unofficial-bash-strict-mode/
# (helps with debugging)
# set -e: immediately exit if we find a non zero
# set -u: undefined references cause errors
# set -o: single error causes full pipeline failure.
set -euo pipefail
IFS=$'\n\t'
# datestring, used in many different places...
dateStr=`date +%Y-%m-%d:%H:%M:%S`

# Description:

# Arguments:
#### Arg 1: Description

# Returns:

cd .. 
python2 main_feather.py\
    -tau 1e-2 \
    -threshold 1e-3 \
    -spring_constant 6.67e-3 \
    -trigger_time 0.382 \
    -dwell_time 0.992 \
    -file_input ../Data/example.csv \
    -file_output ./output.txt \



