@echo off
cls
rem ==================================================
SET SCRIPT_PATH=d:\projects\consul\scripts\admin
SET REMOTE_CMD=d:\projects\consul\scripts\admin\pwd-remote-cmd.sh
SET PWD_URL=direct.labs.play-with-docker.com
SET WORKER=ip172-18-0-42-c07r5kc34gag00b7u0pg@%PWD_URL%
SET P1=https://labs.play-with-docker.com/p/c074tpk34gag00brhs4g#c074tpk3_c074trc34gag00brhs50
SET MANAGER=ip172-18-0-44-c07r5kc34gag00b7u0pg@%PWD_URL%
SET M1=https://labs.play-with-docker.com/p/c074tpk34gag00brhs4g#c074tpk3_c074trc34gag00brhs5g
cd %SCRIPT_PATH%

rem ==================================================
rem "Tell Play with Docker Lab to Get Latest and Deploy"
echo " --> Executing update-stack.sh on Worker1"
start "Worker Node Update" /B putty.exe -m %REMOTE_CMD% %WORKER%

echo " --> Executing update-stack.sh on Manager1"
start "Manager Node Update" /B putty.exe -m %REMOTE_CMD% %MANAGER%
