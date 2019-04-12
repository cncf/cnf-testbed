#!/bin/bash

project_root=$(cd ../ ; pwd -P)

if [ -z "$1" ] ; then
  echo "$0 <path_to_kubeconfig>"
  exit 1
fi

## load/set configuration

#export KUBECONFIG=$(pwd)/data/kubeconfig
export KUBECONFIG="$1"

if [ ! -f "$KUBECONFIG" ] ; then
   echo "Could not find kubeconfig $KUBECONFIG"
   exit 1
fi

sudo chown $(whoami):$(whoami) $(pwd)/data/kubeconfig 

worker_hostnames=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="Hostname")].address}')
worker_ips=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}')
K8S_ELAPSED_TIME=$SECONDS

## Deploy VPP vSwitch
#SECONDS=0
docker run \
       -v "${project_root}/comparison/ansible:/ansible" \
       -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
       -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
       -e PACKET_API_TOKEN=${PACKET_AUTH_TOKEN} \
       -e PROJECT_NAME="${PACKET_PROJECT_NAME}" \
       -e PACKET_FACILITY=${PACKET_FACILITY} \
       -e ANSIBLE_HOST_KEY_CHECKING=False \
       --entrypoint=ansible-playbook \
       -ti cnfdeploytools:latest -i "${worker_ips// /,}," -e deploy_env=${K8S_DEPLOY_ENV} -e server_list="${worker_hostnames// /,}" /ansible/$PLAYBOOK

#VSWITCH_ELAPSED_TIME=$SECONDS

#echo "$(($K8S_ELAPSED_TIME / 60)) minutes and $(($K8S_ELAPSED_TIME % 60)) seconds elapsed - K8s Deploy."
#echo "$(($VSWITCH_ELAPSED_TIME / 60)) minutes and $(($VSWITCH_ELAPSED_TIME % 60)) seconds elapsed - vSwitch Deploy."
