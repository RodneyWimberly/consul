@echo off
cls
cd d:\consul\soakes\consul\scripts\admin

rem ==================================================
SET DOCKER_REGISTRY=docker.pkg.github.com/rodneywimberly/dockerrepositories/
SET REMOTE_CMD=d:\consul\soakes\consul\scripts\admin\pwd-remote-cmd.sh
SET WORKER=ip172-18-0-7-c0703eb6hnp000fnpnq0@direct.labs.play-with-docker.com
SET MANAGER=ip172-18-0-38-c0703eb6hnp000fnpnq0@direct.labs.play-with-docker.com

rem ==================================================
echo "Building consul-bootstrapper image for consul stack"
docker build -t %DOCKER_REGISTRY%consul-bootstrapper:1.0 bootstrapper/.

echo "Logging in to repository ${DOCKER_REGISTRY}"
docker login https://docker.pkg.github.com--username=RodneyWimberly --password=5a45a7688ea36d4572100a47f894435fef6b2aa5

echo "Pushing consul-bootstrapper image for consul stack"
docker push %DOCKER_REGISTRY%consul-bootstrapper:1.0

rem ==================================================
echo " --> Executing update-stack.sh on Worker1"
start "Worker Node Update" /B putty.exe -m %REMOTE_CMD% %WORKER%

echo " --> Executing update-stack.sh on Manager1"
start "Manager Node Update" /B putty.exe -m %REMOTE_CMD% %MANAGER%
