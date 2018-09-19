#! /bin/bash

input="$1"

mydir=$(dirname $0)

cd $mydir

if [ "$input" == "clean" ]; then
  # Only removes container, not image
  docker rm vBNG -f
  exit 0
fi

if [ ! -z "$(docker ps | grep vBNG)" ]; then
  exit 0
fi

./build_container.sh

# Below 'if running' Should not be needed, but keeping for now
if [ -z "$(docker ps | grep vBNG)" ]; then
  docker run --privileged --cpus 3 --cpuset-cpus 14,16,18 --device=/dev/hugepages/:/dev/hugepages/ -v "/etc/vpp/sockets/:/run/vpp/" -t -d --name vBNG vbng /usr/bin/vpp -c /etc/vpp/startup.conf
fi
echo "vBNG container running"
