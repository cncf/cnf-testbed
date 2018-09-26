#! /bin/bash

input="$1"

mydir=$(dirname $0)

cd $mydir

if [ "$input" == "clean" ]; then
  # Only removes container, not image
  docker rm v1BNG -f
  exit 0
fi

if [ ! -z "$(docker ps | grep v1BNG)" ]; then
  exit 0
fi

./build_container.sh

# Below 'if running' Should not be needed, but keeping for now
if [ -z "$(docker ps | grep v1BNG)" ]; then
  #docker run --privileged --cpus 3 --cpuset-cpus 14,16,18 --device=/dev/hugepages/:/dev/hugepages/ -v "/etc/vpp/sockets/:/run/vpp/" -t -d --name vBNG vbng /usr/bin/vpp -c /etc/vpp/startup.conf
  docker run --privileged --cpus 3 --cpuset-cpus 14,16,44 --device=/dev/hugepages/:/dev/hugepages/ -v "/etc/vpp/sockets/:/root/sockets/" -t -d --name v1BNG v1bng /usr/bin/vpp -c /etc/vpp/startup.conf
fi
echo "v1BNG container running"
