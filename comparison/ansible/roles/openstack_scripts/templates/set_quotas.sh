#!/bin/bash

admin_project=$(openstack project list | awk '/admin/ {print $2}')
openstack quota set ${admin_project} --instances 50 --cores 200 --ram 512000 --injected-files 100 --ports 500 --volumes 100
# Check:
# openstack quota show  ${admin_project}
