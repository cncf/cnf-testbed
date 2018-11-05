#!/bin/bash
dir=$(pwd)
parentdir="$(dirname "$dir")"
parentdir2="$(dirname "$parentdir")"
parentdir3="$(dirname "$parentdir2")"
echo "DIR $dir"

docker run -v $(pwd)/ansible:/ansible -v ~/.ssh/id_rsa:/root/.ssh/id_rsa -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub -v "$dir"/terraform-ansible/:/terraform -e TF_VAR_packet_project_id=${PACKET_PROJECT_ID} -e TF_VAR_packet_api_key=${PACKET_AUTH_TOKEN} -e TF_VAR_playbook=/ansible/main.yml -ti terraform:latest destroy -force
