#!/bin/bash
dir=$(pwd)
parentdir="$(dirname "$dir")"
parentdir2="$(dirname "$parentdir")"
parentdir3="$(dirname "$parentdir2")"


if [ "$1" = "dual_mellanox" ] ; then
  PACKET_MASTER_DEVICE_PLAN="m2.xlarge.x86"
  PLAYBOOK_NAME="packet_generator_dual_mellanox.yml"
elif [ "$1" = "quad_intel" ] ; then
  PACKET_MASTER_DEVICE_PLAN="m2.xlarge.x86"
  PLAYBOOK_NAME="packet_generator_quad_intel.yml"
else
  echo "Usage: $0 <dual_mellanox|quad_intel>"
  exit 1
fi

docker build -t cnfdeploytools:latest .

docker run -v $(pwd)/ansible:/ansible -v ~/.ssh/id_rsa:/root/.ssh/id_rsa -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub -v "$parentdir3"/tools/terraform-ansible/:/terraform \
  -e TF_VAR_packet_project_id=${PACKET_PROJECT_ID} \
  -e TF_VAR_packet_api_key=${PACKET_AUTH_TOKEN} \
  -e TF_VAR_packet_facility=${PACKET_FACILITY} \
  -e TF_VAR_packet_master_device_plan=${PACKET_MASTER_DEVICE_PLAN} \
  -e TF_VAR_packet_operating_system=${PACKET_OPERATING_SYSTEM} \
  -e TF_VAR_playbook=/ansible/$PLAYBOOK_NAME -ti cnfdeploytools:latest apply -auto-approve
