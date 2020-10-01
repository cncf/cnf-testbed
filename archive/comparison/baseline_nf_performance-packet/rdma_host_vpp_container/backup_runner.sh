#! /bin/bash

docker run --privileged --tty --detach \
	--cpuset-cpus 0,2,4,30,32 \
	--device=/dev/hugepages/:/dev/hugepages/ \
        --volume "${PWD}/shared/:/etc/vpp/" \
	--volume "/etc/vpp/sockets/:/etc/vpp/sockets/" \
	--volume "/dev/:/dev/" \
	--volume "/lib/modules/4.15.0-20-generic/:/lib/modules/4.15.0-20-generic/" \
	--name "VPPcontainer" rdma_vpp_image
