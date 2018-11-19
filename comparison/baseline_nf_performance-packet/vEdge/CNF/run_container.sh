#! /bin/bash

input="$1"

mydir=$(dirname $0)

cd $mydir

if [ "$input" == "clean" ]; then
  # Only removes container, not image
  docker rm vEdge -f
  exit 0
fi

if [ ! -z "$(docker inspect -f {{.State.Running}} vEdge)" ]; then
  exit 0
fi

chmod +x ./build_container.sh && ./build_container.sh

# Below 'if running' Should not be needed, but keeping for now
if [ -z "$(docker inspect -f {{.State.Running}} vEdge)" ]; then
  docker run --privileged --cpus 3 --cpuset-cpus 10,12,40 --device=/dev/hugepages/:/dev/hugepages/ -v "/etc/vpp/sockets/:/run/vpp/" -t -d --name vEdge vedge_single /usr/bin/vpp -c /etc/vpp/startup.conf
fi
echo "vEdge container running"
