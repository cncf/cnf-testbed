#!/bin/bash
dir=$(pwd)
parentdir="$(dirname "$dir")"
parentdir2="$(dirname "$parentdir")"
parentdir3="$(dirname "$parentdir2")"
echo "DIR $parentdir3"
docker run \
  -v ${parentdir2}/ansible:/ansible \
  -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
  -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
  -v ${parentdir3}/tools/terraform-ansible/:/terraform \
  -e TF_VAR_packet_project_id=${PACKET_PROJECT_ID} \
  -e TF_VAR_packet_api_key=${PACKET_AUTH_TOKEN} \
  -e TF_VAR_packet_operating_system=centos_7 \
  -e TF_VAR_packet_node_count=4 \
  -e TF_VAR_name=openstack \
  -e TF_VAR_playbook=/ansible/openstack_infra_setup.yml \
  -ti terraform:latest apply -auto-approve \
  -state=/terraform/openstack.tfstate

echo "[etcd]" > ${parentdir2}/ansible/inventory
cat ${parentdir3}/tools/terraform-ansible/openstack.tfstate | awk -F\" '/0.add/ {print $4}' >> ${parentdir2}/ansible/inventory
echo "[all:vars]" >> ${parentdir2}/ansible/inventory
echo "ansible_ssh_extra_args='-o StrictHostKeyChecking=no'" >> ${parentdir2}/ansible/inventory

docker run \
  -v ${parentdir2}/ansible:/ansible \
  -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
  -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
  -v "$dir"/terraform-ansible/:/terraform \
  -v ${parentdir2}/ansible/inventory:/etc/ansible/hosts \
  --entrypoint ansible-playbook -ti terraform:latest /ansible/openstack_chef_install.yml
