#!/bin/bash
dir=$(pwd)
parentdir="$(dirname "$dir")"

NODE_NAME=${NODE_NAME:-openstack}
NODE_COUNT=${NODE_COUNT:-4}
NODE_PLAN=${NODE_PLAN:-m2.xlarge.x86}
PACKET_OS=${PACKET_OS:-centos_7}
PACKET_FACILITY=${PACKET_FACILITY:-sjc1}
PACKET_PROJECT_NAME=${PACKET_PROJECT_NAME:-"CNCF CNFs"}

if [ ! -f ${parentdir}/comparison/ansible/inventory ]; then
echo "[all:vars]" > ${parentdir}/comparison/ansible/inventory
echo "ansible_ssh_extra_args='-o StrictHostKeyChecking=no'" >> ${parentdir}/comparison/ansible/inventory
echo "[all]" >> ${parentdir}/comparison/ansible/inventory

docker run \
  -v ${parentdir}/comparison/ansible:/ansible \
  -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
  -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
  -v ${parentdir}/tools/terraform-ansible/:/terraform \
  -e PACKET_API_TOKEN=${PACKET_AUTH_TOKEN} \
  -e TF_VAR_packet_project_id=${PACKET_PROJECT_ID} \
  -e TF_VAR_packet_api_key=${PACKET_AUTH_TOKEN} \
  -e TF_VAR_packet_node_count=${NODE_COUNT} \
  -e TF_VAR_packet_master_device_plan=${NODE_PLAN} \
  -e TF_VAR_packet_facility=${PACKET_FACILITY} \
  -e TF_VAR_name=${NODE_NAME} \
  -e TF_VAR_playbook=/ansible/openstack_infra_setup.yml \
  -e TF_VAR_packet_operating_system=${PACKET_OS} \
  -ti cnfdeploytools:latest apply -auto-approve \
  -state=/terraform/openstack.tfstate

echo "[etcd]" >> ${parentdir}/comparison/ansible/inventory
cat ${parentdir}/tools/terraform-ansible/openstack.tfstate | awk -F\" '/0.add/ {print $4}' >> ${parentdir}/comparison/ansible/inventory
fi
SERVER_LIST=`for ((n=1;n<$NODE_COUNT;n++)); do echo -n $NODE_NAME$n,;done;echo -n $NODE_NAME$NODE_COUNT`
time docker run \
  -v ${parentdir}/comparison/ansible:/ansible \
  -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
  -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
  -v ${parentdir}/tools/terraform-ansible/:/terraform \
  -v ${parentdir}/comparison/ansible/inventory:/etc/ansible/hosts \
  -e PACKET_API_TOKEN=${PACKET_AUTH_TOKEN} \
  -e PACKET_FACILITY=${PACKET_FACILITY} \
  -e PROJECT_NAME="${PACKET_PROJECT_NAME}" \
  -e SERVER_LIST=${SERVER_LIST} \
  --entrypoint ansible-playbook -ti cnfdeploytools:latest ${ANSIBLE_ARGS} /ansible/openstack_chef_install.yml
if [[ $? != 0 ]]; then

echo -e '=================================================\n Retrying the ansible run'
time docker run \
  -v ${parentdir}/comparison/ansible:/ansible \
  -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
  -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
  -v ${parentdir}/tools/terraform-ansible/:/terraform \
  -v ${parentdir}/comparison/ansible/inventory:/etc/ansible/hosts \
  -e PACKET_API_TOKEN=${PACKET_AUTH_TOKEN} \
  -e PACKET_FACILITY=${PACKET_FACILITY} \
  -e PROJECT_NAME="${PACKET_PROJECT_NAME}" \
  -e SERVER_LIST=${SERVER_LIST} \
  --entrypoint ansible-playbook -ti cnfdeploytools:latest ${ANSIBLE_ARGS} /ansible/openstack_chef_install.yml
fi
