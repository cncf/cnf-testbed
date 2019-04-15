#!/bin/bash
dir=$(pwd)
parentdir="$(dirname "$dir")"

SECONDS=0
OPENSTACK_VM_CREATE_TIME=0

time docker run --rm \
  -v ${parentdir}/comparison/ansible:/ansible \
  -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
  -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
  -v ${parentdir}/comparison/ansible/inventory:/etc/ansible/hosts \
  --entrypoint ansible-playbook -ti cnfdeploytools:latest /ansible/openstack_test_create.yml
OPENSTACK_VM_CREATE_TIME=$SECONDS

echo "$(($OPENSTACK_VM_CREATE_TIME / 60)) minutes and $(($OPENSTACK_VM_CREATE_TIME % 60)) seconds elapsed - Openstack VM Create."


