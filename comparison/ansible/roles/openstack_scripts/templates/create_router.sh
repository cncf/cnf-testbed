#!/bin/bash

if [ $# -lt 4 ]; then
  echo "you need to pass three parameters:"
  echo " subnet start address (e.g. network address)"
  echo " subnet cidr (e.g. 24)"
  echo " gateway address (e.g. network address +1)"
  echo " internal vlan id (e.g. 1044)"
fi

source ~/openrc

subnet=$1
cidr=$2
gateway=$3
vlan=$4

if [ !  "$( openstack network list | awk '/netext/ {print $4}' )" == "netext" ] ;then
openstack network create --external --provider-network-type flat --provider-physical-network flat netext
openstack subnet create --network netext --subnet-range $subnet/$cidr --no-dhcp --gateway $gateway subnetext

openstack router create routerext
openstack router add subnet routerext subnet$vlan
openstack router set routerext --external-gateway netext --enable-snat
fi
