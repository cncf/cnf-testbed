#!/bin/bash

if [[ $# == '0' ]]; then
    echo "usage: $0 {vlan-id,vlan-id...}"
    exit 1
fi

IFS=',' read -r -a vlans <<< "$1"

for element in ${vlans[@]}
do
openstack network create --provider-segment ${element} --provider-network-type vlan --provider-physical-network provider vlan${element}
(( vlan_subnet = $element - 1000 ))
openstack subnet create --network vlan${element} --subnet-range 10.${vlan_subnet}.0.0/24 --no-dhcp --gateway 10.${vlan_subnet}.0.254 subnet${element}
done
