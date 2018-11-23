#!/bin/bash

## Deploy OpenStack
## load/set configuration
#../../tools/deploy_openstack_cluster.sh

## Deploy chained VNFs
# ./deploy_chained_vnfs.sh

## Deploy traffic generator
pushd ./packet_generator/
./deploy_packet_generator.sh

# Run tests
popd

## Collect and summarize results

# ../../tools/destroy_openstack_cluster.sh
