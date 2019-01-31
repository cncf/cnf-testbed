#!/bin/bash
dir=$(pwd)
parentdir="$(dirname "$dir")"

docker run \
  -v ${parentdir}/comparison/ansible:/ansible \
  -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
  -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
  -v ${parentdir}/tools/terraform-ansible/:/terraform \
  -e TF_VAR_packet_project_id="${PACKET_PROJECT_ID}" \
  -e TF_VAR_packet_api_key=${PACKET_AUTH_TOKEN} \
  -e TF_VAR_playbook=/ansible/openstack_infra_setup.yml \
  -ti cnfdeploytools:latest destroy -force \
  -state=/terraform/openstack.tfstate
rm ${parentdir}/comparison/ansible/inventory
