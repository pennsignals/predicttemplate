#!/bin/bash
while true
do
  watch -d -t -g ls -lR predict/src/{{cookiecotter.name}}/*.py predict/test/*.py > /dev/null 2>&1
  py.test
  sleep 5
done
