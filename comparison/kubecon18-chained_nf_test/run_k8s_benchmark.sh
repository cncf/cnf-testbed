#!/bin/bash

project_root=$(cd ../../ ; pwd -P)
worker_hostname=$NAME-worker-1.$NAME.packet.local
worker_ip=$(dig worker.$NAME.packet.local @147.75.69.23 +short)
## Deploy k8s
## load/set configuration
../../tools/deploy_k8s_cluster.sh

docker run \
       -v "${project_root}/comparison/ansible:/ansible" \
       -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
       -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
       -e PACKET_API_TOKEN=${PACKET_AUTH_TOKEN} \
       --entrypoint=ansible-playbook \
       -ti cnfdeploytools:latest -i "$worker_ip," -e 'host_key_checking=False' -e deploy_env=$NAME -e server_list=$NAME-worker-1.$NAME.packet.local /ansible/$PLAYBOOK

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
# pushd ./packet_generator/
# ./deploy_packet_generator.sh

# Run tests
# ...

# popd

## Collect and summarize results
# ...
