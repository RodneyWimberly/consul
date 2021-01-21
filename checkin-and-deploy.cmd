@echo off
cls
cd d:\consul\soakes\consul

echo " --> Adding changed items to source control"
git add .
echo " --> Commiting changed items to source control"
git commit -m "<your message here>"
echo " --> Pushing changed items to source control"
git push --progress --all --repo=https://rodneywimberly:b606a0781f57605d4e5b00b753a6f26c23ff8908@github.com/RodneyWimberly/consul.git
echo " --> Pulling changed items from source control"
git pull --force --progress https://rodneywimberly:b606a0781f57605d4e5b00b753a6f26c23ff8908@github.com/RodneyWimberly/consul.git

echo " --> Executing update-stack.sh on Worker1"
start "Worker1 Update" /B putty.exe -load Worker1
echo " --> Executing update-stack.sh on Manager1"
start "Manager1 Update" /B putty.exe -load Manager1
start /B http://ip172-18-0-125-c04qss9lo55000bvt83g-9000.direct.labs.play-with-docker.com/#/containers
