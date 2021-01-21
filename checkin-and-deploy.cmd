@echo off
cd d:\consul\soakes\consul

echo "Check-in and sync changes"
git commit -a Automated commit
git push --all
git pull --all

echo "Executing update-stack.sh on Worker1"
putty -load Worker1
echo "Executing update-stack.sh on Manager1"
putty -load Manager1
