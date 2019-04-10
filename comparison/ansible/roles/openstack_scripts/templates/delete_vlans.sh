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
  if [ "$( openstack network list | grep vlan${vlan} | awk '{print $4}' )" == "vlan${vlan}" ] ;then
    openstack network delete vlan${vlan}
  fi
done