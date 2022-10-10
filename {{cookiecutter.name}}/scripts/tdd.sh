#!/bin/bash
while true
do
  watch -d -t -g ls -lR predict/src/{{cookiecutter.name}}/*.py predict/test/*.py > /dev/null 2>&1
  pytest
  sleep 1
done
