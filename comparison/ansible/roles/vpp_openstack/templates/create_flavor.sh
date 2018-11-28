#!/bin/bash
source ~/openrc
openstack flavor create --id 1 --ram 2048 --disk 10 --property hw:mem_page_size=2048 small
