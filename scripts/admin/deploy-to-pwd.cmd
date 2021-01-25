
@echo off
cls

rem ==================================================
SET SCRIPT_PATH=d:\consul\soakes\consul\scripts\admin
SET DOCKER_HUB=docker.pkg.github.com
rem SET DOCKER_REGISTRY=localhost:5000/
rem SET DOCKER_REGISTRY=ip172-18-0-46-c074tpk34gag00brhs4g-5000.direct.labs.play-with-docker.com/
rem SET DOCKER_REGISTRY=docker.pkg.github.com/rodneywimberly/dockerrepositories/
SET DOCKER_REGISTRY=rodneywimberly/dockerregistry:
SET REMOTE_CMD=d:\consul\soakes\consul\scripts\admin\pwd-remote-cmd.sh
SET PWD_URL=direct.labs.play-with-docker.com
SET WORKER=ip172-18-0-44-c074tpk34gag00brhs4g@%PWD_URL%
SET P1=https://labs.play-with-docker.com/p/c074tpk34gag00brhs4g#c074tpk3_c074trc34gag00brhs50
SET MANAGER=ip172-18-0-46-c074tpk34gag00brhs4g@%PWD_URL%
SET M1=https://labs.play-with-docker.com/p/c074tpk34gag00brhs4g#c074tpk3_c074trc34gag00brhs5g
cd %SCRIPT_PATH%

rem ==================================================
echo "Build and Deploy Docker Images to Docker Hub"
echo " --> Building consul-bootstrapper image for consul stack"
docker build -t %DOCKER_REGISTRY%consul-bootstrapper:1.0 ../../bootstrapper/.

echo " --> Logging in to repository %DOCKER_REGISTRY%"
rem docker login https://%DOCKER_HUB% --username=RodneyWimberly --password=5a45a7688ea36d4572100a47f894435fef6b2aa5
docker login --username=rodneywimberly --password=P@55w0rd!

echo " --> Pushing consul-bootstrapper image for consul stack"
docker push %DOCKER_REGISTRY%consul-bootstrapper:1.0

rem ==================================================
rem "Tell Play with Docker Lab to Get Latest and Deploy"
echo " --> Executing update-stack.sh on Worker1"
start "Worker Node Update" /B putty.exe -m %REMOTE_CMD% %WORKER%

echo " --> Executing update-stack.sh on Manager1"
start "Manager Node Update" /B putty.exe -m %REMOTE_CMD% %MANAGER%
