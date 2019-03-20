#!/bin/bash
dir=$(pwd)
parentdir="$(dirname "$dir")"

NODE_NAME=${NODE_NAME:-openstack}
NODE_COUNT=${NODE_COUNT:-4}
NODE_PLAN=${NODE_PLAN:-m2.xlarge.x86}
PACKET_OS=${PACKET_OS:-centos_7}
PACKET_FACILITY=${PACKET_FACILITY:-sjc1}

docker run --rm \
  -v ${parentdir}/comparison/ansible:/ansible \
  -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
  -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
  -v ${parentdir}/tools/terraform-ansible/:/terraform \
  -e PROJECT_NAME="${PACKET_PROJECT_NAME}" \
  -e PACKET_API_TOKEN=${PACKET_AUTH_TOKEN} \
  -e PACKET_FACILITY=${PACKET_FACILITY} \
  -e TF_VAR_packet_project_id=${PACKET_PROJECT_ID} \
  -e TF_VAR_packet_api_key=${PACKET_AUTH_TOKEN} \
  -e TF_VAR_packet_node_count=${NODE_COUNT} \
  -e TF_VAR_packet_master_device_plan=${NODE_PLAN} \
  -e TF_VAR_packet_facility=${PACKET_FACILITY} \
  -e TF_VAR_name=${NODE_NAME} \
  -e TF_VAR_playbook=/ansible/openstack_infra_setup.yml \
  -e TF_VAR_packet_operating_system=${PACKET_OS} \
  --entrypoint /bin/bash -ti cnfdeploytools:latest $*

