#!/bin/bash
dir=$(pwd)
parentdir="$(dirname "$dir")"
parentdir2="$(dirname "$parentdir")"

NODE_NAME=${NODE_NAME:-openstack}
NODE_COUNT=${NODE_COUNT:-4}
NODE_PLAN=${NODE_PLAN:-m2.xlarge.x86}
PACKET_OS=${PACKET_OS:-centos_7}
PACKET_FACILITY=${PACKET_FACILITY:-sjc1}

if [ ! -f ${parentdir}/ansible/inventory ]; then
echo "[all:vars]" > ${parentdir}/ansible/inventory
echo "ansible_ssh_extra_args='-o StrictHostKeyChecking=no'" >> ${parentdir}/ansible/inventory
echo "[all]" >> ${parentdir}/ansible/inventory

docker run \
  -v ${parentdir}/ansible:/ansible \
  -v ${parentdir}/ansible/inventory:/ansible/inventory \
  -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
  -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
  -v ${parentdir2}/tools/terraform-ansible/:/terraform \
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

echo "[etcd]" >> ${parentdir}/ansible/inventory
cat ${parentdir2}/tools/terraform-ansible/openstack.tfstate | awk -F\" '/0.add/ {print $4}' >> ${parentdir}/ansible/inventory

fi

time docker run \
  -v ${parentdir}/ansible:/ansible \
  -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
  -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
  -v "${parentdir2}"/tools/terraform-ansible/:/terraform \
  -v ${parentdir}/ansible/inventory:/etc/ansible/hosts \
  --entrypoint ansible-playbook -ti cnfdeploytools:latest /ansible/openstack_chef_install.yml

if [[ $? != 0 ]]; then

echo -e '=================================================\n Retrying the ansible run'
time docker run \
  -v ${parentdir}/ansible:/ansible \
  -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
  -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
  -v "${parentdir2}"/tools/terraform-ansible/:/terraform \
  -v ${parentdir}/ansible/inventory:/etc/ansible/hosts \
  --entrypoint ansible-playbook -ti cnfdeploytools:latest /ansible/openstack_chef_install.yml

fi
