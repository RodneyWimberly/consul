@echo off
cls
call set-variables.cmd

echo " --> Executing update-stack.sh on Worker1"
start "Worker Node Update" /B putty.exe %WORKER%@%PWD_URL%

echo " --> Executing update-stack.sh on Manager1"
start "Manager Node Update" /B putty.exe %MANAGER%@%PWD_URL%
