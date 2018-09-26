#! /bin/bash

mydir=$(dirname $0)
cd $mydir

if [ -z "$(docker image list | grep v2bng)" ]; then
  docker build -t v2bng .
else
  echo "Skipping build of container as it already exists.  Remove and rerun to build again"
fi
