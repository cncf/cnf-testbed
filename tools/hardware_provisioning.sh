#!/bin/bash

USE_RESERVED=${USE_RESERVED:-false}
DEPLOY_NAME=${DEPLOY_NAME:-cnftestbed}
PACKET_FACILITY=${PACKET_FACILITY:-sjc1}
PACKET_OS=${PACKET_OS:-ubuntu_16_04}
MASTER_COUNT=${MASTER_COUNT:-1}
MASTER_PLAN=${MASTER_PLAN:-m2.xlarge.x86}
WORKER_COUNT=${WORKER_COUNT:-2}
WORKER_PLAN=${WORKER_PLAN:-m2.xlarge.x86}

SECONDS=0
HARDWARE_INFRA_DEPLOY=0

if [ "$USE_RESERVED" == "true" ]; then
   RESERVED_CONFIG="-v $(pwd)/hardware-provisioning.reserved:/terraform/override.tf"
else
   RESERVED_CONFIG=""
fi

docker run \
        --rm \
        -e TF_VAR_name=${DEPLOY_NAME} \
        -e TF_VAR_packet_api_key=${PACKET_AUTH_TOKEN} \
        -e TF_VAR_packet_project_id=${PACKET_PROJECT_ID} \
        -e TF_VAR_packet_facility=${PACKET_FACILITY} \
        -e TF_VAR_packet_operating_system=${PACKET_OS} \
        -e TF_VAR_packet_master_node_count=${MASTER_COUNT} \
        -e TF_VAR_packet_master_device_plan=${MASTER_PLAN} \
        -e TF_VAR_packet_worker_node_count=${WORKER_COUNT} \
        -e TF_VAR_packet_worker_device_plan=${WORKER_PLAN} \
        -v $(pwd)/$DEPLOY_NAME:/$DEPLOY_NAME \
        ${RESERVED_CONFIG} \
        -ti cnfdeploytools:latest apply -auto-approve \
        -state=/$DEPLOY_NAME/terraform.tfstate
         HARDWARE_INFRA_DEPLOY=$SECONDS

touch $(pwd)/"$DEPLOY_NAME"_nodes.env
docker run \
       --rm \
       -v $(pwd)/$DEPLOY_NAME/terraform.tfstate:/terraform/terraform.tfstate \
       -v $(pwd)/"$DEPLOY_NAME"_nodes.env:/terraform/nodes.env \
       --entrypoint=/terraform/create_nodes.sh -ti cnfdeploytools:latest



