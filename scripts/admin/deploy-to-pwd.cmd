@echo off
cls
cd d:\consul\soakes\consul

rem ==================================================
rem echo " --> Adding changed items to source control"
rem git add .

rem echo " --> Commiting changed items to source control"
rem git commit -m "<your message here>"

rem echo " --> Pushing changed items to source control"
rem git push --progress --all --repo=https://rodneywimberly:b606a0781f57605d4e5b00b753a6f26c23ff8908@github.com/RodneyWimberly/consul.git

rem echo " --> Pulling changed items from source control"
rem git pull --force --progress https://rodneywimberly:b606a0781f57605d4e5b00b753a6f26c23ff8908@github.com/RodneyWimberly/consul.git

rem ==================================================
echo " --> Executing update-stack.sh on Worker1"
start "Worker1 Update" /B putty.exe -m d:\consul\soakes\consul\scripts\admin\pwd-remote-cmd.sh ip172-18-0-7-c06icur6hnp000d51o6g@direct.labs.play-with-docker.com

echo " --> Executing update-stack.sh on Manager1"
start "Manager1 Update" /B putty.exe -m  d:\consul\soakes\consul\scripts\admin\pwd-remote-cmd.sh ip172-18-0-65-c06icur6hnp000d51o6g@direct.labs.play-with-docker.com
