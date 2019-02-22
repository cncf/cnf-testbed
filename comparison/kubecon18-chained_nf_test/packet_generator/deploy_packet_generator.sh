#!/bin/bash

myname=$(basename $0)
myfullpath=$(readlink -f $0)
mypath=$(dirname $myfullpath)
project_root=$(cd ../../../ ; pwd -P)
tool_path="${project_root}/tools"
deploy_tools_path="${tool_path}/deploy"

######  


if [ "$myname" = "deploy_packet_generator.sh" ] ; then
  CMD="apply -auto-approve"
elif [ "$myname" = "destroy_packet_generator.sh" ] ; then
  CMD="destroy -force"
else
  echo "Unknown command"
  exit 1
fi


if [ "$1" = "dual_mellanox" ] ; then
  PACKET_MASTER_DEVICE_PLAN="m2.xlarge.x86"
  PLAYBOOK_NAME="packet_generator_dual_mellanox.yml"
  TF_OVERRIDE="-v $(pwd)/dual_mellanox_override.tf:/terraform/override.tf"
elif [ "$1" = "quad_intel" ] ; then
  PACKET_MASTER_DEVICE_PLAN="m2.xlarge.x86"
  PLAYBOOK_NAME="packet_generator_quad_intel.yml"
  TF_OVERRIDE="-v $(pwd)/quad_intel_reserved_override.tf:/terraform/override.tf"
else
  echo "Usage: $0 <dual_mellanox|quad_intel> [ansible-inventory-file]"
  exit 1
fi

pushd "$deploy_tools_path"
docker build -t cnfdeploytools:latest .
popd

if [ -z "$2" ] ; then
  docker run \
    -v "$(pwd):/workspace" \
    -v "${project_root}/comparison/ansible:/ansible" \
    -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
    -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
    -v "${tool_path}/terraform-ansible/:/terraform" \
    ${TF_OVERRIDE} \
    -e TF_VAR_name=${NODE_NAME} \
    -e TF_VAR_packet_node_count=${NODE_COUNT} \
    -e TF_VAR_packet_project_id=${PACKET_PROJECT_ID} \
    -e TF_VAR_packet_api_key=${PACKET_AUTH_TOKEN} \
    -e TF_VAR_packet_facility=${PACKET_FACILITY} \
    -e TF_VAR_packet_master_device_plan=${PACKET_MASTER_DEVICE_PLAN} \
    -e TF_VAR_packet_operating_system=${PACKET_OPERATING_SYSTEM} \
    -e TF_VAR_playbook=/ansible/openstack_infra_setup.yml \
    -ti cnfdeploytools:latest apply -auto-approve -state=/workspace/packet_generator.tfstate

  echo "[all:vars]" > $(pwd)/inventory
  echo "ansible_ssh_extra_args='-o StrictHostKeyChecking=no'" >> $(pwd)/inventory
  echo "[all]" >> $(pwd)/inventory
  cat $(pwd)/packet_generator.tfstate | awk -F\" '/0.add/ {print $4}' >> $(pwd)/inventory
  SERVER_LIST=`for ((n=1;n<$NODE_COUNT;n++)); do echo -n $NODE_NAME$n,;done;echo -n $NODE_NAME$NODE_COUNT`

  docker run \
    -v "$(pwd):/workspace" \
    -v "${project_root}/comparison/ansible:/ansible" \
    -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
    -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
    -e PACKET_API_TOKEN=${PACKET_AUTH_TOKEN} \
    -e PACKET_FACILITY=${PACKET_FACILITY} \
    -e DEPLOY_ENV=${DEPLOY_ENV} \
    -e PROJECT_NAME="${PROJECT_NAME}" \
    -e SERVER_LIST=${SERVER_LIST} \
    --entrypoint=ansible-playbook -ti cnfdeploytools:latest /ansible/$PLAYBOOK_NAME --inventory-file="/workspace/inventory"
else
  docker run \
    -v "$(pwd):/workspace" \
    -v "${project_root}/comparison/ansible:/ansible" \
    -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
    -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
    -e PACKET_API_TOKEN=${PACKET_AUTH_TOKEN} \
    --entrypoint=ansible-playbook -ti cnfdeploytools:latest /ansible/$PLAYBOOK_NAME --inventory-file="/workspace/$2"
fi
# To drop to a shell:
#  --entrypoint /bin/bash \
#  -ti cnfdeploytools:latest
