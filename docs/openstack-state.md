Currently, in the comparison directory:


1) set your environment, principally this is:

export NODE_NAME=openstack-
export NODE_COUNT=3
export NODE_PLAN=m2.xlarge.x86
export PACKET_OS=centos_7
export PACKET_FACILITY=nrt1
#export PACKET_AUTH_TOKEN=yourauthtoken
#export PACKET_PROJECT_ID=yourprojectid

2) launch the deploy cluster script:
../tools/deploy_openstack_cluster.sh

3) If everyting runs through successfully, then the first node (cat ansible/inventory and use the first address under the [all] parameters) has a script to create networks with a VLAN parameter.  This process currently still uses manual procesess:
 - 1 Set the network type in the packet UI to hybrid for each of the crated nodes
 - 2 Create two vlans in the PACKET_FACILITY defined above if they don't already exist
 - 3 Run the /root/create_vlans.sh script to create Neutron VLAN networks via the VPP driver
 - 4 Launch nodes (an example create_instance.sh script in /root is there to help).

--
Troubleshooting:
1) If nodes are not accessible to Ansible, reboot the nodes via the Packet UI, and ensure you can log in (ansible/inventory will have a list of the nodes that shoudl be reachable).
2) If rerunning the ../tools/deploy_openstack_cluster.sh script still fails, run the ../tools/destroy_openstack_cluster.sh script and try again.


