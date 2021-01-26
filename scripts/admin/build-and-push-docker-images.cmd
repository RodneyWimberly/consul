@echo off

rem ==================================================
SET SCRIPT_PATH=d:\projects\consul\scripts\admin
SET DOCKER_HUB=docker.pkg.github.com/
rem SET DOCKER_HUB=docker.io/
rem SET DOCKER_REGISTRY=localhost:5000/
rem SET DOCKER_REGISTRY=ip172-18-0-46-c074tpk34gag00brhs4g-5000.direct.labs.play-with-docker.com/
SET DOCKER_REGISTRY=rodneywimberly/consul/
rem SET DOCKER_REGISTRY=rodneywimberly/
SET DOCKER_TAG=:1.0
SET DOCKER_FULL_URL=docker.pkg.github.com/rodneywimberly/dockerrepositories/$image$:1.0
cd %SCRIPT_PATH%

rem ==================================================
echo "Build and Deploy Docker Images to Docker Hub"
echo " --> Building consul-bootstrapper image for consul stack"
docker build -t %DOCKER_HUB%%DOCKER_REGISTRY%bootstrapper%DOCKER_TAG% ../../bootstrapper/.

echo " --> Building volume image for nfstest stack"
docker build -t %DOCKER_HUB%%DOCKER_REGISTRY%nfstest%DOCKER_TAG% ../../nfs/.

echo " --> Logging in to repository %DOCKER_REmGISTRY%"
docker login https://%DOCKER_HUB% --username=RodneyWimberly --password=5a45a7688ea36d4572100a47f894435fef6b2aa5
rem docker login --username=rodneywimberly --password=P@55w0rd!

echo " --> Pushing consul-bootstrapper image for consul stack"
docker push %DOCKER_HUB%%DOCKER_REGISTRY%bootstrapper%DOCKER_TAG%

echo " --> Pushing volume image for nfstest stack"
docker push %DOCKER_HUB%%DOCKER_REGISTRY%nfstest%DOCKER_TAG%
