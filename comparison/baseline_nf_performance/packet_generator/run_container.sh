#! /bin/bash

input="$1"

TREX_VER='v2.32'

mydir=$(dirname $0)
cd $mydir

if [ "$input" == "clean" ]; then
  docker rm nfvbench -f
  echo "NFVbench container removed"
  exit 0
fi

sudo docker pull opnfv/nfvbench:1.5.2

state="$(docker ps | grep nfvbench)"
if [ -z "$state" ]; then
  sudo docker run --detach --net=host --privileged -v $PWD:/tmp/nfvbench -v /dev:/dev \
     -v /lib/modules/$(uname -r):/lib/modules/$(uname -r) -v /usr/src:/usr/src -v /usr/bin/ofed_info:/usr/bin/ofed_info \
     -v /etc/libibverbs.d:/etc/libibverbs.d -v /usr/lib:/tmp/lib -v /dev/mst:/dev/mst \
     -v /usr/lib:/usr/lib -v /lib:/lib --name nfvbench opnfv/nfvbench:1.5.2
  #  sudo docker exec
  echo "Remember to update nfvbench_config.cfg with correct PCI addresses"
  # Below command updates the number of hugepages available for TRex, allowing more cores to be used
  sudo docker exec -it nfvbench sed -i -e "s/512 /2048 /" -e "s/512\"/2048\"/" /opt/trex/$TREX_VER/trex-cfg
  # Also change the mbuf factor to further reduce the memory usage
  sudo docker exec -it nfvbench sed -i -e "s/--cfg {} \&>/--cfg {} --mbuf-factor 0.2 \&>/g" /nfvbench/nfvbench/traffic_server.py
fi

echo "NFVbench container running"


