#!/usr/bin/env bash

input="${1}"

mydir=$(dirname $0)
cd ${mydir}

if [ "${input}" == "clean" ]; then
  if [ ! -z "$(docker inspect -f {{.State.Running}} vEdge)" ]; then
    echo "Remove container before removing image"
    exit 0
  fi
  # Only removes image
  echo "Removing 'vedge' docker image"
  docker image rm vedge_single
  exit 0
fi

if [ -z "$(docker image list | grep vedge_single)" ]; then
  docker build -t vedge_single .
else
  echo "Skipping build of container as it already exists.  Remove and rerun to build again"
fi
