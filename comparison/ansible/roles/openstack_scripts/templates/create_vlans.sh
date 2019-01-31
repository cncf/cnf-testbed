#!/bin/bash

if [[ $# == '0' ]]; then
  echo "usage: $0 {vlan-id}"
  exit 1
fi
source ~/openrc
openstack network create --provider-segment ${1} --provider-network-type vlan --provider-physical-network provider vlan${1}
(( vlan_subnet = $1 - 1000 ))
openstack subnet create --network vlan${1} --subnet-range 10.${vlan_subnet}.0.0/24 --no-dhcp --gateway none subnet${1}

