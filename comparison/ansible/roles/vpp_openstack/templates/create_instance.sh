#!/bin/bash
source ~/openrc
network=`openstack network list | awk '/vlan/ {print $4}'`
openstack  server create --flavor 1 --image cirros --nic net-id=${network} test

