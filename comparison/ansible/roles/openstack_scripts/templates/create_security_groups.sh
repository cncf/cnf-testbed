#!/bin/bash
source ~/openrc

admin_project=$(openstack project list | awk '/admin/ {print $2}')
admin_default=$(openstack security group list | grep $admin_project | awk '{print $2}')
openstack security group rule create --proto icmp ${admin_default}
openstack security group rule create --proto tcp --dst-port 22 ${admin_default}
openstack security group rule create --proto tcp --dst-port 80 ${admin_default}
openstack security group rule create --proto tcp --dst-port 443 ${admin_default}
