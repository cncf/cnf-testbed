#! /bin/bash

openstack port list | grep ip_address | awk '{print $4}' | grep -e _l -e _r -e _e | xargs -n1 openstack port delete
echo ""
echo ""
echo "Show port list:"
openstack port list
