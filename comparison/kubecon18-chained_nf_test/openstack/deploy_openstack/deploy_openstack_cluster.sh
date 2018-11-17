#!/bin/bash

myname=$(basename $0)
myfullpath=$(readlink -f $0)
mypath=$(dirname $myfullpath)
project_root=$(cd ../../../../ ; pwd -P)
tool_path="${project_root}/tools"
deploy_tools_path="${tool_path}/deploy"

######  

echo $myname

if [ "$myname" = "deploy_openstack_cluster.sh" -o "$1" = "deploy" ] ; then
  CMD="apply -auto-approve"
elif [ "$myname" = "destroy_openstack_cluster.sh" -o "$1" = "destroy" ] ; then
  CMD="destroy -force"
else
  echo "Unknown command"
  exit 1
fi

pushd "$deploy_tools_path" 
docker build -t cnfdeploytools:latest .
popd

docker run \
  -v "$(pwd):/workspace" \
  -v "${project_root}/comparison/ansible:/ansible" \
  -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
  -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
  -v "${mypath}/terraform-ansible/:/terraform" \
  -e TF_VAR_packet_project_id=${PACKET_PROJECT_ID} \
  -e TF_VAR_packet_api_key=${PACKET_AUTH_TOKEN} \
  -e TF_VAR_playbook=/ansible/openstack_chef_deploy.yml \
  -ti cnfdeploytools:latest $CMD -auto-approve -state=/workspace/terraform.tfstate
