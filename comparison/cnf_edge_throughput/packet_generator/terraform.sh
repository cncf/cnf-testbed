#!/bin/bash
dir=$(pwd)
parentdir="$(dirname "$dir")"
parentdir2="$(dirname "$parentdir")"
parentdir3="$(dirname "$parentdir2")"
echo "DIR $parentdir3"

docker build -t cnfdeploytools:latest .
docker run -v $(pwd)/ansible:/ansible -v ~/.ssh/id_rsa:/root/.ssh/id_rsa -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub -v "$parentdir3"/tools/terraform-ansible/:/terraform \
  -e TF_VAR_packet_project_id=${PACKET_PROJECT_ID} \
  -e TF_VAR_packet_api_key=${PACKET_AUTH_TOKEN} \
  -e TF_VAR_packet_facility=${PACKET_FACILITY} \
  -e TF_VAR_packet_master_device_plan=${PACKET_MASTER_DEVICE_PLAN} \
  -e TF_VAR_packet_operating_system=${PACKET_OPERATING_SYSTEM} \
  -e TF_VAR_playbook=/ansible/main.yml -ti cnfdeploytools:latest apply -auto-approve
