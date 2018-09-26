#! /bin/bash

mydir=$(dirname $0)
cd $mydir

if [ -z "$(docker image list | grep v1bng)" ]; then
  docker build -t v1bng .
else
  echo "Skipping build of container as it already exists.  Remove and rerun to build again"
fi
