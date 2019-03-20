#!/bin/bash

if [[ $# == '0' ]]; then
  echo "usage: $0 {vlan-id}"
  exit 1
fi

source ~/openrc
if [ !  "$( openstack network list | grep vlan${1} | awk '{print $4}' )" == "vlan${1}" ] ;then
openstack network create --disable-port-security --provider-segment ${1} --provider-network-type vlan --provider-physical-network provider vlan${1}
(( vlan_subnet = $RANDOM % 254 ))
openstack subnet create --network vlan${1} --subnet-range 10.${vlan_subnet}.0.0/24 --no-dhcp --dns-nameserver 8.8.8.8 --dns-nameserver 8.8.4.4 subnet${1}
fi
