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
#### is_windows: boolean flag for if this is windows-like
is_windows="${1:-1}"

echo "Is Windows flag: ${is_windows}"

# test matlab
cd ../AppMatlab/
if [[ $is_windows -eq "0" ]] ; then
	matlab_binary="/Applications/MATLAB_R2017a.app/bin/matlab"
else
	matlab_binary="matlab"
fi 
echo "Booting Matlab..."
"${matlab_binary}" -wait -nodesktop  -nosplash -r "run('feather_example.m'); pause(2); exit;"
cd - > /dev/null
# test python
echo "Booting python..."
cd ../AppPython/
if [[ $is_windows -eq "0" ]] ; then
	python2 main_example.py || ( echo "Runing python2 failed" ; exit );
	python3 main_example.py || ( echo "Runing python3 failed" ; exit );
else
	/c/ProgramData/Anaconda2/python.exe main_example.py || ( echo "Runing python2 failed" ; exit );
fi
cd - > /dev/null



# Returns:



