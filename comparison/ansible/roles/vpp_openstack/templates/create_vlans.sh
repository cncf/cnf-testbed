#!/bin/bash

if [[ $# == '0' ]]; then
  echo "usage: $0 {vlan-id}"
  exit 1
fi
source ~/openrc
openstack network create --provider-segment ${1} --provider-network-type vlan --provider-physical-network physnet vlan${1}
openstack subnet create --network vlan${1} --subnet-range 10.61.0.0/24 --dhcp subnet${1}
