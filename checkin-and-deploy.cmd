@echo off
cd d:\consul\soakes\consul

echo "Check-in and sync changes"
git add .
git commit -m "<your message here>"
git push --progress --all --repo=https://rodneywimberly:b606a0781f57605d4e5b00b753a6f26c23ff8908@github.com/RodneyWimberly/consul.git
git pull --force --progress https://rodneywimberly:b606a0781f57605d4e5b00b753a6f26c23ff8908@github.com/RodneyWimberly/consul.git

echo "Executing update-stack.sh on Worker1"
putty -load Worker1
echo "Executing update-stack.sh on Manager1"
putty -load Manager1
