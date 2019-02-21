#! /bin/bash

openstack server list | grep vnf.3c | awk '{print $4}' | xargs -n1 openstack server delete
echo ""
echo ""
echo "Show server list:"
openstack server list
