@echo off

rem ==================================================
SET SCRIPT_PATH=d:\projects\consul\scripts\admin
rem SET DOCKER_HUB=docker.pkg.github.com/
SET DOCKER_HUB=docker.io/
rem SET DOCKER_REGISTRY=localhost:5000/
rem SET DOCKER_REGISTRY=ip172-18-0-46-c074tpk34gag00brhs4g-5000.direct.labs.play-with-docker.com/
rem SET DOCKER_REGISTRY=rodneywimberly/consul/
SET DOCKER_REGISTRY=rodneywimberly/
SET DOCKER_TAG=:1.0
SET DOCKER_FULL_URL=docker.pkg.github.com/rodneywimberly/dockerrepositories/$image$:1.0
cd %SCRIPT_PATH%

rem ==================================================
echo "Build and Deploy Docker Images to Docker Hub"
echo " --> Building consul-bootstrapper image for consul stack"
docker build -t %DOCKER_HUB%%DOCKER_REGISTRY%dockerrepositories:bootstrapper ../../bootstrapper/.

echo " --> Building volume image for nfstest stack"
docker build -t %DOCKER_HUB%%DOCKER_REGISTRY%dockerrepositories:nfstest ../../nfs/.

echo " --> Logging in to repository %DOCKER_REmGISTRY%"
rem docker login https://%DOCKER_HUB% --username=RodneyWimberly --password=b1b203616d5b8f247d0a0749ebc02ecdac81a7d3
docker login --username=rodneywimberly --password=P@55w0rd!

echo " --> Pushing consul-bootstrapper image for consul stack"
docker push %DOCKER_HUB%%DOCKER_REGISTRY%dockerrepositories:bootstrapper

echo " --> Pushing volume image for nfstest stack"
docker push %DOCKER_HUB%%DOCKER_REGISTRY%dockerrepositories:nfstest
