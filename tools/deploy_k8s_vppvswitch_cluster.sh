#!/bin/bash

project_root=$(cd ../ ; pwd -P)

## Deploy k8s
## load/set configuration
SECONDS=0
$(project_root)/tools/deploy_k8s_cluster.sh
sudo chown $(whoami):$(whoami) $(pwd)/data/kubeconfig 
export KUBECONFIG=$(pwd)/data/kubeconfig
worker_hostnames=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="Hostname")].address}')
worker_ips=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}')
K8S_ELAPSED_TIME=$SECONDS

## Deploy VPP vSwitch
SECONDS=0
docker run \
       -v "${project_root}/comparison/ansible:/ansible" \
       -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
       -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
       -e PACKET_API_TOKEN=${PACKET_AUTH_TOKEN} \
       -e ANSIBLE_HOST_KEY_CHECKING=False \
       --entrypoint=ansible-playbook \
       -ti cnfdeploytools:latest -i "$worker_ips," -e deploy_env=${NAME} -e server_list=${worker_hostnames} /ansible/$PLAYBOOK
VSWITCH_ELAPSED_TIME=$SECONDS

echo "$(($K8S_ELAPSED_TIME / 60)) minutes and $(($K8S_ELAPSED_TIME % 60)) seconds elapsed - K8s Deploy."
echo "$(($VSWITCH_ELAPSED_TIME / 60)) minutes and $(($VSWITCH_ELAPSED_TIME % 60)) seconds elapsed - vSwitch Deploy."
