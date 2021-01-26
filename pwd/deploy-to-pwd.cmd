@echo off
cls
rem ==================================================
SET SCRIPT_PATH=d:\projects\consul\pwd
SET REMOTE_CMD=d:\projects\consul\pwd\pwd-remote-cmd.sh
SET PWD_URL=direct.labs.play-with-docker.com
SET WORKER=ip172-18-0-84-c0885ss34gag00b7v180
SET MANAGER=ip172-18-0-89-c0885ss34gag00b7v180
cd %SCRIPT_PATH%

rem ==================================================
rem "Tell Play with Docker Lab to Get Latest and Deploy"
echo " --> Executing update-stack.sh on Worker1"
start "Worker Node Update" /B putty.exe -m %REMOTE_CMD% %WORKER%@%PWD_URL%

echo " --> Executing update-stack.sh on Manager1"
start "Manager Node Update" /B putty.exe -m %REMOTE_CMD% %MANAGER%@%PWD_URL%
