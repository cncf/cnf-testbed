#!/bin/bash

DEPLOY_NAME=${DEPLOY_NAME:-cnftestbed}
USE_RESERVED=${USE_RESERVED:-false}
STATE_FILE=${STATE_FILE:-$(pwd)/data/$DEPLOY_NAME/terraform.tfstate}
NODE_FILE=${NODE_FILE:-$(pwd)/data/$DEPLOY_NAME/kubernetes.env}

NODE_GROUP_ONE_NAME=${NODE_GROUP_ONE_NAME:-$DEPLOY_NAME-master}
NODE_GROUP_TWO_NAME=${NODE_GROUP_TWO_NAME:-$DEPLOY_NAME-worker}
NODE_GROUP_ONE_COUNT=${NODE_GROUP_ONE_COUNT:-1}
NODE_GROUP_TWO_COUNT=${NODE_GROUP_TWO_COUNT:-1}
FACILITY=${FACILITY:-sjc1}
NODE_GROUP_ONE_DEVICE_PLAN=${NODE_GROUP_ONE_DEVICE_PLAN:-m2.xlarge.x86}
NODE_GROUP_TWO_DEVICE_PLAN=${NODE_GROUP_TWO_DEVICE_PLAN:-n2.xlarge.x86}
OPERATING_SYSTEM=${OPERATING_SYSTEM:-ubuntu_16_04}


SECONDS=0
HARDWARE_INFRA_DEPLOY=0

mkdir -p "$(pwd)/data/$DEPLOY_NAME"

if [ -f "$NODE_FILE" ]; then
    echo 'a node file for this deployment already exists, exiting'
    exit 1
fi
touch "$NODE_FILE"

if [ -f "$STATE_FILE" ]; then
    echo 'a state file for this deployment already exists, exiting'
    exit 1
fi
touch "$STATE_FILE"

if [ "$USE_RESERVED" == "true" ]; then
   RESERVED_CONFIG="-v $(pwd)/hardware-provisioning.reserved:/terraform/override.tf"
else
   RESERVED_CONFIG=""
fi

docker run \
        --rm \
        -e TF_VAR_packet_auth_token=${PACKET_AUTH_TOKEN} \
        -e TF_VAR_node_group_one_project_id=${PROJECT_ID} \
        -e TF_VAR_node_group_two_project_id=${PROJECT_ID} \
        -e TF_VAR_node_group_one_name=${NODE_GROUP_ONE_NAME} \
        -e TF_VAR_node_group_two_name=${NODE_GROUP_TWO_NAME} \
        -e TF_VAR_node_group_one_count=${NODE_GROUP_ONE_COUNT} \
        -e TF_VAR_node_group_two_count=${NODE_GROUP_TWO_COUNT} \
        -e TF_VAR_node_group_one_facility=${FACILITY} \
        -e TF_VAR_node_group_two_facility=${FACILITY} \
        -e TF_VAR_node_group_one_device_plan=${NODE_GROUP_ONE_DEVICE_PLAN} \
        -e TF_VAR_node_group_two_device_plan=${NODE_GROUP_TWO_DEVICE_PLAN} \
        -e TF_VAR_node_group_one_operating_system=${OPERATING_SYSTEM} \
        -e TF_VAR_node_group_two_operating_system=${OPERATING_SYSTEM} \
        -v $STATE_FILE:/terraform/terraform.tfstate \
        ${RESERVED_CONFIG} \
        -ti cnfdeploytools:latest apply -auto-approve
         HARDWARE_INFRA_DEPLOY=$SECONDS

docker run \
       --rm \
       -v $STATE_FILE:/terraform/terraform.tfstate \
       -v $NODE_FILE:/terraform/nodes.env \
       --entrypoint=/terraform/create_nodes.sh -ti cnfdeploytools:latest



