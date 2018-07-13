#!/bin/bash

mydir=$(dirname $0)

cd $mydir

./build/build_container.sh

if [ -z "$(docker network ls | grep dns-net)" ]; then
  echo "Creating dns network"
  docker network create --subnet=40.30.20.0/24 dns-net
fi

if [ -z "$(docker ps | grep -v vDNSgen | grep vDNS)" ]; then
  echo "Creating container"
  docker create --privileged --cpus 4 --name vDNS -t vdns

  echo "Connecting second interface to container"
  docker network connect dns-net --ip 40.30.20.110 vDNS
  echo "Starting vDNS container"
  docker start vDNS
else
  echo "vDNS container running"
fi
