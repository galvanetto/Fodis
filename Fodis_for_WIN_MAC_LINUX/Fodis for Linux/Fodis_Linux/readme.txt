Open Fodis_Linux folder

Run as administrator  sudo ./MyAppInstaller_web.install
It will download a free version of the MATLAB_RUNTIME necessary to run Fodis. 
It will take few minutes to download and ~255 MB of free space

Now run ./run_Fodis.sh < MCR Folder>
where MCR Folder is the path where you installed the MCR. 
Usually is something like /MATLAB/MATLAB_Runtime/v90/

The system requirements can be consulted here 
https://it.mathworks.com/support/sysreq/previous_releases.html
for version r2016b






MATLAB Compiler

1. Prerequisites for Deployment 

. Verify the MATLAB Runtime is installed and ensure you    
  have installed version 9.0 (R2015b).   

. If the MATLAB Runtime is not installed, do the following:
  (1) enter
  
      >>mcrinstaller
      
      at MATLAB prompt. The MCRINSTALLER command displays the 
      location of the MATLAB Runtime installer.

  (2) run the MATLAB Runtime installer.

Or download the Linux 64-bit version of the MATLAB Runtime for R2015b 
from the MathWorks Web site by navigating to

   http://www.mathworks.com/products/compiler/mcr/index.html
   
   
For more information about the MATLAB Runtime and the MATLAB Runtime installer, see 
Package and Distribute in the MATLAB Compiler documentation  
in the MathWorks Documentation Center.    


2. Files to Deploy and Package

Files to package for Standalone 
================================
-Fodis 
-run_Fodis.sh (shell script for temporarily setting environment variables and executing 
               the application)
   -to run the shell script, type
   
       ./run_Fodis.sh <mcr_directory> <argument_list>
       
    at Linux or Mac command prompt. <mcr_directory> is the directory 
    where version 9.0 of the MATLAB Runtime is installed or the directory where 
    MATLAB is installed on the machine. <argument_list> is all the 
    arguments you want to pass to your application. For example, 

    If you have version 9.0 of the MATLAB Runtime installed in 
    /mathworks/home/application/v90, run the shell script as:
    
       ./run_Fodis.sh /mathworks/home/application/v90
       
    If you have MATLAB installed in /mathworks/devel/application/matlab, 
    run the shell script as:
    
       ./run_Fodis.sh /mathworks/devel/application/matlab
-MCRInstaller.zip
   -if end users are unable to download the MATLAB Runtime using the above  
    link, include it when building your component by clicking 
    the "Runtime downloaded from web" link in the Deployment Tool
-This readme file 

3. Definitions

For information on deployment terminology, go to 
http://www.mathworks.com/help. Select MATLAB Compiler >   
Getting Started > About Application Deployment > 
Deployment Product Terms in the MathWorks Documentation 
Center.


4. Appendix 

A. Linux x86-64 systems:
In the following directions, replace MCR_ROOT by the directory where the MATLAB Runtime 
   is installed on the target machine.

(1) Set the environment variable XAPPLRESDIR to this value:

    MCR_ROOT/v90/X11/app-defaults


(2) If the environment variable LD_LIBRARY_PATH is undefined, set it to the concatenation 
   of the following strings:

    MCR_ROOT/v90/runtime/glnxa64:
    MCR_ROOT/v90/bin/glnxa64:
    MCR_ROOT/v90/sys/os/glnxa64:
    MCR_ROOT/v90/sys/opengl/lib/glnxa64

    If it is defined, set it to the concatenation of these strings:

    ${LD_LIBRARY_PATH}: 
    MCR_ROOT/v90/runtime/glnxa64:
    MCR_ROOT/v90/bin/glnxa64:
    MCR_ROOT/v90/sys/os/glnxa64:
    MCR_ROOT/v90/sys/opengl/lib/glnxa64

   For more detail information about setting the MATLAB Runtime paths, see Package and 
   Distribute in the MATLAB Compiler documentation in the MathWorks Documentation Center.


     
        NOTE: To make these changes persistent after logout on Linux 
              or Mac machines, modify the .cshrc file to include this  
              setenv command.
        NOTE: The environment variable syntax utilizes forward 
              slashes (/), delimited by colons (:).  
        NOTE: When deploying standalone applications, it is possible 
              to run the shell script file run_Fodis.sh 
              instead of setting environment variables. See 
              section 2 "Files to Deploy and Package".    






