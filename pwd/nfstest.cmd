@echo off
pushd

rem ==================================================
SET CONTAINER_ROOT_PATH=d:\projects\consul\vault

SET DOCKER_USER=rodneywimberly
SET DOCKER_PASSWORD=Mich$11$!

SET IMAGE_OWNER=%GITHUB_USER%
SET IMAGE_NAME=nfstest
SET IMAGE_VERSION=1.0

rem ==================================================
echo "Build and Deploy Docker Images to Docker Hub"

rem docker login --username=%DOCKER_USER% --password=%DOCKER_PASSWORD%

cd %CONTAINER_ROOT_PATH%\nfstest
echo " --> Building %IMAGE_OWNER%/%IMAGE_NAME% image"
docker build -t %IMAGE_OWNER%/%IMAGE_NAME% .


echo " --> Logging in to image registry hub"
docker login https://%GITHUB_HUB% --username=%GITHUB_USER% --password=%GITHUB_PASSWORD%

echo " --> Pushing %IMAGE_OWNER%/%IMAGE_NAME% image"
docker push %IMAGE_OWNER%/%IMAGE_NAME%

popd
