#!/bin/bash
source ~/openrc
if [[ ! $(openstack flavor list | grep c0. | wc -l) -ge 2 ]]; then
  openstack flavor create --id 1 --ram 8192 --disk 10 --property hw:numa_nodes=1 --property hw:mem_page_size=2048 --property hw:numa_cpus.0=0 --property hw:numa_mem.0=8192 c0.small
  openstack flavor create --id 2 --ram 8192 --disk 10 --property hw:numa_nodes=1 --property hw:mem_page_size=2048 --property hw:numa_cpus.1=0 --property hw:numa_mem.1=8192 c1.small

  openstack flavor create --id 4 --ram 16384 --vcpus 2 --disk 10 --property hw:numa_nodes=2 --property hw:mem_page_size=2048 --property hw:numa_cpus.0=0,1 --property hw:numa_mem.0=16384 c0.med
  openstack flavor create --id 5 --ram 16384 --vcpus 2 --disk 10 --property hw:numa_nodes=2 --property hw:mem_page_size=2048 --property hw:numa_cpus.1=0,1 --property hw:numa_mem.1=16384 c1.med
fi
