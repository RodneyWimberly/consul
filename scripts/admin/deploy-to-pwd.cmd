@echo off
cls
rem ==================================================
SET SCRIPT_PATH=d:\projects\consul\scripts\admin
rem SET DOCKER_HUB=docker.pkg.github.com/
SET DOCKER_HUB=docker.io/
rem SET DOCKER_REGISTRY=localhost:5000/
rem SET DOCKER_REGISTRY=ip172-18-0-46-c074tpk34gag00brhs4g-5000.direct.labs.play-with-docker.com/
rem SET DOCKER_REGISTRY=docker.pkg.github.com/rodneywimberly/dockerrepositories/
SET DOCKER_REGISTRY=rodneywimberly/
SET REMOTE_CMD=d:\projects\consul\scripts\admin\pwd-remote-cmd.sh
SET PWD_URL=direct.labs.play-with-docker.com
SET WORKER=ip172-18-0-27-c07loor6hnp000dtdnig@%PWD_URL%
SET P1=https://labs.play-with-docker.com/p/c074tpk34gag00brhs4g#c074tpk3_c074trc34gag00brhs50
SET MANAGER=ip172-18-0-44-c07loor6hnp000dtdnig@%PWD_URL%
SET M1=https://labs.play-with-docker.com/p/c074tpk34gag00brhs4g#c074tpk3_c074trc34gag00brhs5g
cd %SCRIPT_PATH%

rem ==================================================
echo "Build and Deploy Docker Images to Docker Hub"
echo " --> Building consul-bootstrapper image for consul stack"
rem docker build -t %DOCKER_REGISTRY%dockerregistry:consul-bootstrapper ../../bootstrapper/.

echo " --> Building volume image for nfstest stack"
rem docker build -t %DOCKER_REGISTRY%dockerregistry:volume ../../nfs/.

echo " --> Logging in to repository %DOCKER_REmGISTRY%"
rem docker login https://%DOCKER_HUB% --username=RodneyWimberly --password=5a45a7688ea36d4572100a47f894435fef6b2aa5
rem docker login --username=rodneywimberly --password=P@55w0rd!

echo " --> Pushing consul-bootstrapper image for consul stack"
rem docker push %DOCKER_REGISTRY%dockerregistry:consul-bootstrapper

echo " --> Pushing volume image for nfstest stack"
rem docker push %DOCKER_REGISTRY%dockerregistry:volume

rem ==================================================
rem "Tell Play with Docker Lab to Get Latest and Deploy"
echo " --> Executing update-stack.sh on Worker1"
start "Worker Node Update" /B putty.exe -m %REMOTE_CMD% %WORKER%

echo " --> Executing update-stack.sh on Manager1"
start "Manager Node Update" /B putty.exe -m %REMOTE_CMD% %MANAGER%
