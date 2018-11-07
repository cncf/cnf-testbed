#!/bin/bash

myname=$(basename $0)
myfullpath=$(readlink -f $0)
mypath=$(dirname $myfullpath)
project_root=$(cd ../../../ ; pwd -P)
tool_path="${project_root}/tools"
deploy_tools_path="${tool_path}/deploy"

######  

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

pushd "$deploy_tools_path" 
docker build -t cnfdeploytools:latest .
popd

docker run -v $(pwd)/ansible:/ansible -v ~/.ssh/id_rsa:/root/.ssh/id_rsa -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub -v "${tool_path}/terraform-ansible/:/terraform" \
  -e TF_VAR_packet_project_id=${PACKET_PROJECT_ID} \
  -e TF_VAR_packet_api_key=${PACKET_AUTH_TOKEN} \
  -e TF_VAR_packet_facility=${PACKET_FACILITY} \
  -e TF_VAR_packet_master_device_plan=${PACKET_MASTER_DEVICE_PLAN} \
  -e TF_VAR_packet_operating_system=${PACKET_OPERATING_SYSTEM} \
  -e TF_VAR_playbook=/ansible/$PLAYBOOK_NAME \
  -ti cnfdeploytools:latest apply -auto-approve

# To drop to a shell:
#  --entrypoint /bin/bash \
#  -ti cnfdeploytools:latest

