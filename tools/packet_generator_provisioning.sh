#!/bin/bash
PROJECT_ROOT=${PROJECT_ROOT:-$(cd ../ ; pwd -P)}
DEPLOY_NAME=${DEPLOY_NAME:-cnftestbed}
NODE_FILE=${NODE_FILE:-$(pwd)/data/$DEPLOY_NAME/packet_gen.env}

NIC_TYPE=${NIC_TYPE:--e quad_intel=true}
FACILITY=${FACILITY:-sjc1}
VLAN_SEGMENT=${VLAN_SEGMENT:-$DEPLOY_NAME}
PLAYBOOK=${PLAYBOOK:-packet_generator.yml}

if ! [ -z ${PKTGEN_HOSTS+x} ]; then
    HOSTS="$PKTGEN_HOSTS,"
    PKTGEN_IPS_ARRAY=($(echo $PKTGEN_HOSTS | tr ',' ' '))
elif ! [ -z ${NODE_FILE+x} ]; then
    PKTGEN_IPS_ARRAY=($(yq r $NODE_FILE nodes.[*].addr | tr -d '\n''-'))
    HOSTS="$(printf "%s," "${PKTGEN_IPS_ARRAY[@]}")"
else
    echo 'No hosts were found, exiting'
fi


PKTGEN_HOSTNAMES="$(for ((n=1;n<"${#PKTGEN_IPS_ARRAY[@]}";n++)); do echo -n $DEPLOY_NAME-pktgen$n,;done;echo -n $DEPLOY_NAME-pktgen"${#PKTGEN_IPS_ARRAY[@]}")"

docker run \
       --rm \
       -v "${PROJECT_ROOT}/comparison/ansible:/ansible" \
       -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
       -e PACKET_API_TOKEN=${PACKET_AUTH_TOKEN} \
       -e PROJECT_NAME="${PACKET_PROJECT_NAME}" \
       -e PACKET_FACILITY=${FACILITY} \
       -e DEPLOY_ENV=${VLAN_SEGMENT} \
       -e SERVER_LIST=${PKTGEN_HOSTNAMES} \
       -e ANSIBLE_HOST_KEY_CHECKING=False \
       --entrypoint=ansible-playbook \
       -ti cnfdeploytools:latest -i $HOSTS /ansible/$PLAYBOOK $NIC_TYPE

#Fetch NFVBench Macs
PKTGEN_ETH2=$(docker run \
       --rm \
       -e PACKET_API_TOKEN=${PACKET_AUTH_TOKEN} \
       -e ANSIBLE_HOST_KEY_CHECKING=False \
       --entrypoint=ruby \
       -ti cnfdeploytools:latest /packet_api/l2_packet_networking.rb --show-server-ports $PKTGEN_HOSTNAMES --project-name="$PACKET_PROJECT_NAME" --packet-url='api.packet.net' --facility="$FACILITY" | jq -r '.[] | select(.name=="eth2") | .data.mac')

PKTGEN_ETH3=$(docker run \
       --rm \
       -e PACKET_API_TOKEN=${PACKET_AUTH_TOKEN} \
       -e ANSIBLE_HOST_KEY_CHECKING=False \
       --entrypoint=ruby \
       -ti cnfdeploytools:latest /packet_api/l2_packet_networking.rb --show-server-ports $PKTGEN_HOSTNAMES --project-name="$PACKET_PROJECT_NAME" --packet-url='api.packet.net' --facility="$FACILITY" | jq -r '.[] | select(.name=="eth3") | .data.mac')
