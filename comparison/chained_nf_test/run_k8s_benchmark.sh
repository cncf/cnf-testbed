#!/bin/bash

## Deploy k8s
## load/set configuration
#../../tools/deploy_k8s_cluster.sh

## Deploy chained CNFs
# ./deploy_chained_cnfs.sh

## Deploy traffic generator
pushd ./packet_generator/
./deploy_packet_generator.sh

# Run tests
popd

## Collect and summarize results
