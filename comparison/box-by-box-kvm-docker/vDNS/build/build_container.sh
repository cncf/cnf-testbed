#! /bin/bash

mydir=$(dirname $0)

cd $mydir

if [ -z "$(docker image list | grep -v vdnsgen | grep vdns)" ]; then
  echo "Building container"
  docker build -t vdns .
fi
