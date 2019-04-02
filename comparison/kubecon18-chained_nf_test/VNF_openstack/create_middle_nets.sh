#! /bin/bash
openstack network create --disable-port-security --provider-network-type vlan --provider-physical-network provider middle1
openstack subnet create submiddle1 --subnet-range 10.90.0.0/24 --network middle1 --gateway 10.90.0.254 --no-dhcp

openstack network create --disable-port-security --provider-network-type vlan --provider-physical-network provider middle2
openstack subnet create submiddle2 --subnet-range 10.91.0.0/24 --network middle2 --gateway 10.91.0.254 --no-dhcp
