#! /bin/bash

mydir=$(dirname $0)
cd $mydir

if [ -z "$(docker image list | grep vbng)" ]; then
  docker build -t vbng .
else
  echo "Skipping build of container as it already exists.  Remove and rerun to build again"
fi
