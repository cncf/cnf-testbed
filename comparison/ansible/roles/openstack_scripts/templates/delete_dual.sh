#!/bin/bash

if [ $# -ne 1 ]; then
echo "Usage: $0 <server_name>"
exit 1
fi

openstack server delete $1
openstack port delete s${1}p1 s${1}p2

