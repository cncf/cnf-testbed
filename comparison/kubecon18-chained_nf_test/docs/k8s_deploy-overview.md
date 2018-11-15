## Deploy k8s

#./deploy_k8s_cluster.sh

VLAN assignments
quad port intel:
  vlan1 => eth1 (req)
  vlan2 => eth2 (req)
  vlan3 => eth3 (cluster mgmt)

dual port Mellanox:
   vlan1 => eth1
   vlan2 => eth1


1. cross-cloud (terraform)
2. terraform-ansible runs the playbook k8s_cluster.yml 
3. k8s_cluster.yml playbook include playbooks to setup k8s cluster
4. quad_intel_workers.yml (set interfaces var to Packet interfaces)

# PACKET
#   - create vlans (ansible)
#   - remove ports from bond (ansible)
#   - assign vlans to ports (ansible)

# HOST
#   - removes ports from bond on worker nodes (ansible)
#   - sets up vpp on worker node (ansible)
