#!/bin/bash

if [[ $# == '0' ]]; then
  vlans=({% for key,value in packet_vlans.iteritems() %}{{value.vid}} {% endfor %})
  if [ -z "${vlans}" ]; then
  echo "usage: $0 {vlan-id}"
  exit 1
  fi
fi
source ~/openrc
for vlan in ${vlans[@]}; do
 if [ !  "$( openstack network list | grep vlan${vlan} | awk '{print $4}' )" == "vlan${vlan}" ] ;then
 openstack network create --disable-port-security --provider-segment ${vlan} --provider-network-type vlan --provider-physical-network provider vlan${vlan}
 (( vlan_subnet = $RANDOM % 254 ))
 openstack subnet create --network vlan${vlan} --subnet-range 10.${vlan_subnet}.0.0/24 --no-dhcp --dns-nameserver 8.8.8.8 --dns-nameserver 8.8.4.4 subnet${vlan}
 fi
done
