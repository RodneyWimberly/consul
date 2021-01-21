@echo off
cd d:\consul\soakes\consul

echo "Check-in and sync changes"
git add .
echo "1"
git commit -m "<your message here>"
echo "2"
git push --progress --all --repo=https://rodneywimberly:b606a0781f57605d4e5b00b753a6f26c23ff8908@github.com/RodneyWimberly/consul.git
echo "3"
git pull --force --progress https://rodneywimberly:b606a0781f57605d4e5b00b753a6f26c23ff8908@github.com/RodneyWimberly/consul.git

echo "Executing update-stack.sh on Worker1"
start "putty.exe" "-load Worker1"
echo "Executing update-stack.sh on Manager1"
start "putty.exe" "-load Manager1"
