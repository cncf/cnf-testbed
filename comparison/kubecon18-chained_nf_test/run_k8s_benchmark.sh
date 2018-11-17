#!/bin/bash

## Deploy k8s
## load/set configuration
#./deploy_k8s_cluster.sh
#   - cross-cloud (terraform) => run ansible playbook k8s_cluster.yml 
#   - include playbooks to setup k8s cluster
# PACKET
#   - create vlans (ansible)
#   - remove ports from bond (ansible)
#   - assign vlans to ports (ansible)
# HOST
#   - removes ports from bond on worker nodes (ansible)
#   - sets up vpp on worker node (ansible)


# NOTE: Run the tests for eitehr snake or pipeline to get the total time of each

## Deploy snake CNF topology
# ./deploy_snake_cnf_topology.sh

## Deploy pipeline CNF topology
# ./deploy_pipeline_cnf_topology.sh

## Deploy traffic generator
pushd ./packet_generator/
./deploy_packet_generator.sh

# Run tests
# ...

popd

## Collect and summarize results
# ...
