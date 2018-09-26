#! /bin/bash

mydir=$(dirname $0)
cd $mydir

if [ -z "$(docker image list | grep vedge_chain)" ]; then
  docker build -t vedge_chain .
else
  echo "Skipping build of container as it already exists.  Remove and rerun to build again"
fi
