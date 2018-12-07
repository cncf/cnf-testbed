#!/bin/bash

admin_default=$(openstack project list | awk '/admin/ {print $2}')
openstack security group rule create --proto icmp ${admin_default}
openstack security group rule create --proto tcp --dst-port 22 ${admin_default}
openstack security group rule create --proto tcp --dst-port 80 ${admin_default}
openstack security group rule create --proto tcp --dst-port 443 ${admin_default}
