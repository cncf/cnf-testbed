#!/bin/bash
dir=$(pwd)
parentdir="$(dirname "$dir")"
parentdir2="$(dirname "$parentdir")"
parentdir3="$(dirname "$parentdir2")"
echo "DIR $parentdir3"
docker run -v $(pwd)/ansible:/ansible -v ~/.ssh/id_rsa:/root/.ssh/id_rsa -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub -v "$dir"/terraform-ansible/:/terraform -e TF_VAR_packet_project_id=${PACKET_PROJECT_ID} -e TF_VAR_packet_api_key=${PACKET_AUTH_TOKEN} -e TF_VAR_playbook=/ansible/main.yml -ti terraform:latest apply -auto-approve

echo "[all]" > ansible/inventory
cat terraform-ansible/terraform.tfstate | awk -F\" '/0.add/ {print $4}' >> ansible/inventory
echo "[all:vars]" >> ansible/inventory
echo "ansible_ssh_extra_args='-o StrictHostKeyChecking=no'" >> ansible/inventory

docker run -v $(pwd)/ansible:/ansible -v ~/.ssh/id_rsa:/root/.ssh/id_rsa -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub -v "$dir"/terraform-ansible/:/terraform -v $(pwd)/ansible/inventory:/etc/ansible/hosts --entrypoint ansible-playbook -ti terraform:latest /ansible/openstack.yml
