@echo off
cls

rem ==================================================
SET SCRIPT_PATH=d:\consul\soakes\consul\scripts\admin
SET DOCKER_HUB=docker.pkg.github.com
SET DOCKER_REGISTRY=%DOCKER_HUB%/rodneywimberly/dockerrepositories/
SET REMOTE_CMD=d:\consul\soakes\consul\scripts\admin\pwd-remote-cmd.sh
SET WORKER=ip172-18-0-7-c0703eb6hnp000fnpnq0@direct.labs.play-with-docker.com
SET MANAGER=ip172-18-0-38-c0703eb6hnp000fnpnq0@direct.labs.play-with-docker.com
cd %SCRIPT_PATH%

rem ==================================================
echo "Build and Deploy Docker Images to Docker Hub"
echo " --> Building consul-bootstrapper image for consul stack"
docker build -t %DOCKER_REGISTRY%consul-bootstrapper:1.0 ../../bootstrapper/.

echo " --> Logging in to repository %DOCKER_REGISTRY%"
docker login https://%DOCKER_HUB% --username=RodneyWimberly --password=5a45a7688ea36d4572100a47f894435fef6b2aa5

echo " --> Pushing consul-bootstrapper image for consul stack"
docker push %DOCKER_REGISTRY%consul-bootstrapper:1.0

rem ==================================================
rem "Tell Play with Docker Lab to Get Latest and Deploy"
echo " --> Executing update-stack.sh on Worker1"
start "Worker Node Update" /B putty.exe -m %REMOTE_CMD% %WORKER%

echo " --> Executing update-stack.sh on Manager1"
start "Manager Node Update" /B putty.exe -m %REMOTE_CMD% %MANAGER%
