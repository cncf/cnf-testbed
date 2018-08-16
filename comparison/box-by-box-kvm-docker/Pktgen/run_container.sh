#! /bin/bash

input="$1"

mydir=$(dirname $0)
cd $mydir

if [ "$input" == "clean" ]; then
  docker rm nfvbench -f
  echo "NFVbench container removed"
  exit 0
fi

state="$(docker ps | grep nfvbench)"
if [ -z "$state" ]; then
  sudo docker run --detach --net=host --privileged -v $PWD/nfvbench:/tmp/nfvbench -v /dev:/dev \ 
      -v /lib/modules/$(uname -r):/lib/modules/$(uname -r) -v /usr/src:/usr/src --name nfvbench opnfv/nfvbench
  sudo docker exec 
  echo "Remember to update nfvbench_config.cfg with correct PCI addresses"
  # Below command updates the number of hugepages available for TRex, allowing more cores to be used
  sudo docker exec -it nfvbench sed -i -e "s/512 /1024 /" -e "s/512\"/1024\"/" /opt/trex/$TREX_VER/trex-cfg
fi

echo "NFVbench container running"


