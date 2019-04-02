#!/bin/bash
dir=$(pwd)
parentdir="$(dirname "$dir")"

MASTER_NAME=${MASTER_NAME:-openstack}
NODE_NAME=${NODE_NAME:-openstack}
MASTER_COUNT=${MASTER_COUNT:-4}
NODE_COUNT=${NODE_COUNT:-4}
MASTER_PLAN=${MASTER_PLAN:-m2.xlarge.x86}
NODE_PLAN=${NODE_PLAN:-m2.xlarge.x86}
PACKET_OS=${PACKET_OS:-ubuntu_18.04}
PACKET_FACILITY=${PACKET_FACILITY:-sjc1}
PACKET_PROJECT_NAME=${PACKET_PROJECT_NAME:-"CNCF CNFs"}

SECONDS=0
if [ ! -f ${parentdir}/comparison/ansible/inventory ]; then
echo "[all]" >> ${parentdir}/comparison/ansible/inventory

time docker run --rm \
  -v ${parentdir}/comparison/ansible:/ansible \
  -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
  -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
  -v ${parentdir}/tools/terraform-ansible/:/terraform \
  -e PACKET_API_TOKEN=${PACKET_AUTH_TOKEN} \
  -e TF_VAR_packet_project_id=${PACKET_PROJECT_ID} \
  -e TF_VAR_packet_api_key=${PACKET_AUTH_TOKEN} \
  -e TF_VAR_packet_master_count=${MASTER_COUNT} \
  -e TF_VAR_packet_master_device_plan=${MASTER_PLAN} \
  -e TF_VAR_master_name=${MASTER_NAME} \
  -e TF_VAR_packet_node_count=${NODE_COUNT} \
  -e TF_VAR_packet_node_device_plan=${NODE_PLAN} \
  -e TF_VAR_name=${NODE_NAME} \
  -e TF_VAR_packet_facility=${PACKET_FACILITY} \
  -e TF_VAR_playbook=/ansible/openstack_infra_setup.yml \
  -e TF_VAR_packet_operating_system=${PACKET_OS} \
  -ti cnfdeploytools:latest apply -auto-approve \
  -state=/terraform/openstack.tfstate
PACKET_SERVER_DEPLOY=$SECONDS
echo "[etcd]" >> ${parentdir}/comparison/ansible/inventory
cat ${parentdir}/tools/terraform-ansible/openstack.tfstate | awk -F\" '/0.add/ {print $4}' >> ${parentdir}/comparison/ansible/inventory
else
time docker run --rm \
  -v ${parentdir}/comparison/ansible:/ansible \
  -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
  -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
  -v ${parentdir}/tools/terraform-ansible/:/terraform \
  -v ${parentdir}/comparison/ansible/inventory:/etc/ansible/hosts \
  -e PACKET_API_TOKEN=${PACKET_AUTH_TOKEN} \
  -e PACKET_FACILITY=${PACKET_FACILITY} \
  -e PROJECT_NAME="${PACKET_PROJECT_NAME}" \
  -e SERVER_LIST=${SERVER_LIST} \
  -e DEPLOY_ENV=${DEPLOY_ENV} \
  -e TF_VAR_packet_project_id=${PACKET_PROJECT_ID} \
  -e TF_VAR_packet_api_key=${PACKET_AUTH_TOKEN} \
  -e TF_VAR_packet_project_id=${PACKET_PROJECT_ID} \
  -e TF_VAR_packet_api_key=${PACKET_AUTH_TOKEN} \
  -e TF_VAR_packet_master_count=${MASTER_COUNT} \
  -e TF_VAR_packet_master_device_plan=${MASTER_PLAN} \
  -e TF_VAR_master_name=${MASTER_NAME} \
  -e TF_VAR_packet_node_count=${NODE_COUNT} \
  -e TF_VAR_packet_device_plan=${NODE_PLAN} \
  -e TF_VAR_name=${NODE_NAME} \
  -e TF_VAR_packet_facility=${PACKET_FACILITY} \
  -e TF_VAR_packet_operating_system=${PACKET_OS} \
  --entrypoint ansible-playbook -ti cnfdeploytools:latest ${ANSIBLE_ARGS} /ansible/openstack_infra_setup.yml
PACKET_SERVER_DEPLOY=$SECONDS
fi
SECONDS=0
MASTER_LIST=`for ((n=1;n<$MASTER_COUNT;n++)); do echo -n $MASTER_NAME$n,;done;echo -n $MASTER_NAME$MASTER_COUNT`
SERVER_LIST=$MASTER_LIST,`for ((n=1;n<$NODE_COUNT;n++)); do echo -n $NODE_NAME$n,;done;echo -n $NODE_NAME$NODE_COUNT`
time docker run --rm \
  -v ${parentdir}/comparison/ansible:/ansible \
  -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
  -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
  -v ${parentdir}/tools/terraform-ansible/:/terraform \
  -v ${parentdir}/comparison/ansible/inventory:/etc/ansible/hosts \
  -e PACKET_API_TOKEN=${PACKET_AUTH_TOKEN} \
  -e PACKET_FACILITY=${PACKET_FACILITY} \
  -e PROJECT_NAME="${PACKET_PROJECT_NAME}" \
  -e SERVER_LIST=${SERVER_LIST} \
  -e DEPLOY_ENV=${DEPLOY_ENV} \
  --entrypoint ansible-playbook -ti cnfdeploytools:latest ${ANSIBLE_ARGS} /ansible/openstack_chef_install.yml
OPENSTACK_DEPLOY_TIME=$SECONDS

echo "$(($PACKET_SERVER_DEPLOY / 60)) minutes and $(($PACKET_SERVER_DEPLOY % 60)) seconds elapsed - Packet.net Infra Setup."
echo "$(($OPENSTACK_DEPLOY_TIME / 60)) minutes and $(($OPENSTACK_DEPLOY_TIME % 60)) seconds elapsed - Openstack Deploy."
