#!/bin/bash
dir=$(pwd)
parentdir="$(dirname "$dir")"
parentdir2="$(dirname "$parentdir")"

docker run \
  -v ${parentdir}/ansible:/ansible \
  -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
  -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
  -v ${parentdir2}/tools/terraform-ansible/:/terraform \
  -e TF_VAR_packet_project_id=${PACKET_PROJECT_ID} \
  -e TF_VAR_packet_api_key=${PACKET_AUTH_TOKEN} \
  -e TF_VAR_playbook=/ansible/openstack_infra_setup.yml \
  -ti cnfdeploytools:latest destroy -force \
  -state=/terraform/openstack.tfstate
rm ${parentdir}/ansible/inventory
