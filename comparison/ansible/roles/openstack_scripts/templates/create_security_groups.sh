#!/bin/bash

openstack security group rule create --proto icmp default
openstack security group rule create --proto tcp --dst-port 22 default
openstack security group rule create --proto tcp --dst-port 80 default
openstack security group rule create --proto tcp --dst-port 443 default
