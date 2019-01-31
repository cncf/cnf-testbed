#!/bin/bash
source ~/openrc
if [[ ! $(openstack flavor list | grep hp. | wc -l) -ge 2 ]]; then
  openstack flavor create --id 1 --ram 16384 --disk 10 hp.small
  openstack flavor create --id 2 --ram 32768 --disk 10 hp.large
fi
# --property hw:numa_nodes=1 --property hw:mem_page_size=2048
