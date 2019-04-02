#!/bin/bash
source ~/openrc
if [[ ! "$(openstack flavor list | grep vnf.3c | wc -l)" -ge "1" ]]; then
  openstack flavor create --id 10 --vcpus 3 --ram 8192 --disk 10 --property hw:cpu_policy=dedicated --property hw:cpu_thread_policy=isolate --property hw:mem_page_size=2048 --property hw:numa_cpus.0=0,1,2 --property hw:numa_mem.0=8192 --property hw:numa_nodes=1 vnf.3c
  openstack flavor create --id 1 --ram 8192 --disk 10 --property hw:numa_nodes=1 --property hw:mem_page_size=2048 --property hw:numa_cpus.0=0 --property hw:numa_mem.0=8192 c0.small
  openstack flavor create --id 2 --ram 8192 --disk 10 --property hw:numa_nodes=1 --property hw:mem_page_size=2048 --property hw:numa_cpus.1=0 --property hw:numa_mem.1=8192 c1.small
fi
