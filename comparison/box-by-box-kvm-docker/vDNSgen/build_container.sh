#! /bin/bash

mydir=$(dirname $0)
cd $mydir

if [ -z "$(docker image list | grep vdnsgen)" ]; then
  docker build -t vdnsgen .
else
  echo "Skipping build of container as it already exists.  Remove and rerun to build again"
fi
