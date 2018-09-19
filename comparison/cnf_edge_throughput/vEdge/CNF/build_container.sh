#! /bin/bash

input="$1"

mydir=$(dirname $0)
cd $mydir

if [ "$input" == "clean" ]; then
  if [ ! -z "$(docker ps | grep vEdge)" ]; then
    echo "Remove container before removing image"
    exit 0
  fi
  # Only removes image
  echo "Removing 'vedge' docker image"
  docker image rm vedge
  exit 0
fi

if [ -z "$(docker image list | grep vedge)" ]; then
  docker build -t vedge .
else
  echo "Skipping build of container as it already exists.  Remove and rerun to build again"
fi
