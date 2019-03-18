#! /bin/bash

docker run --privileged --tty --detach \
	--cpuset-cpus 0,2,4,30,32 \
	--device=/dev/hugepages/:/dev/hugepages/ \
	--volume "/etc/vpp/sockets/:/etc/vpp/sockets/" \
	--volume "/root/vSwitch/shared/:/tmp/shared" \
	--volume "/dev/:/dev/" \
	--name "VPPcontainer" vpp_image
