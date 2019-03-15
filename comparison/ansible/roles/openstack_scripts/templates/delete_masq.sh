#!/bin/bash

set -e

if [ $# -lt 1 ]; then
  echo "you need to pass three parameters:"
  echo " internal vlan id (e.g. 1044)"
  exit 1
fi

source ~/openrc
openstack router remove subnet routerext subnet${1}
openstack router delete routerext
openstack network delete netext
openstack network delete vlan${1}
ip a d 10.20.30.1/24 dev uplink
