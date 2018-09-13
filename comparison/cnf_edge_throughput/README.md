# CNF/VNF - Edge Network Max Throughput Comparison



## Quick start with deployment code:


Steps to Deploy.

1. Clone Repo ```git clone git@github.com:cncf/cnfs.git```
2. Enter terraform dir ```cnfs/comparison/cnf_edge_throughput/```
3. Run Docker container with API/Token vars set ```docker run -v $(pwd):/packet -e TF_VAR_packet_api_key=PACKET-API-KEY -e TF_VAR_packet_project_id=PACKET-PROJECT-ID --entrypoint=/bin/bash -ti hashicorp/terraform:full```
4. cd to packet dir ```cd /packet```
5. Terraform provision ``` terraform init && terraform apply```



## Long version: Provisioning, installs, configuration and testing

### Provision and setup Packet.net machine with Layer-2 networking

#### Instructions for deploying new machines from Packet.net web ui**

1. Log into the Packet.net dashboard at app.packet.net.  Select the org and project. (eg. CNCF, CNCF CNFs)
2. Click Servers
3. Click + New Servers button
4. Choose a hostname eg. cnf-edge-m2xl-04.
5. Choose Location
6. Choose m1.xlarge.x86 as Type
7. Choose Ubuntu 18.04 LTS as OS
8. Select desired SSH keys
9. Click Deploy Servers


#### Enable IOMMU and SR-IOV on the machines

Reference: [NSM Notes for configuring VPP with Mellanox Connectx-4 (PFs and VFs)](https://github.com/ligato/networkservicemesh/issues/270#issue-355769450)

1. SSH into the server
2. `sed -i.bak 's/\(GRUB_CMDLINE_LINUX=\"\)/\1iommu=pt intel_iommu=on hugepagesz=2M hugepages=10240 isolcpus=2,4,6 nohz_full=2,4,6 rcu_nocbs=2,4,6 /' /etc/default/grub`
3. `update-grub2`
4. `reboot`


#### Setting up layer-2 networking for a Layer 3 provisioned Packet.net machines

**Add VLANs to the layer-2 network from Packet.net web ui**

If you need VLANs you can add them to the network.  For the CNF Edge Throughput comparison we are using two VLANS.

From the Packet.net web portal

1. Go to IPS & NETWORK tab
1. Click on Layer 2 on the left
1. Click Add VLAN
1. Select correct Facility/Location eg. SJC1
1. Choose a descriptive name eg. "1st sjc1 CNF testing dataplane network"
1. Click Add button

**Covert network from layer-3 to a hybrid (layer-2 + layer-3) network from the Packet web ui**

For each server that will be part of the same layer 2 network.  Eg. cnf-edge-m2xl-04 and cnf-pktgen-m2xl-04

1. Go to the server in question eg. 
1. Click on Network in the left column
1. Click on the CONVERT TO OTHER NETWORK TYPE button in the LAYER 3 network box.
1. Click Mixed/Hybrid
1. Click Convert to Mixed Networking
  * Wait for conversion to complete

**Add VLAN(s) to the server**
  
1. Click Network screen for server (left column)
1. Sroll to bottom of screen to find Layer 2 section
1. Click ADD NEW VLAN
1. Select eth1 from the Interface drop-down
1. Select the VLAN to add
1. Click ADD button


**Setup machine for the layer-2 network**

1. Find the second interface which is part of the bonded interface. Eg. `awk '{print $2}' /sys/class/net/bond0/bonding/slaves`
1. Update /etc/network/interfaces to remove the second device from the bond configuration.
  * Delete device from bond-slaves on the bond0 device: bond-slaves enp2s0 enp2s0d1
  * Delete the bond-master bond0 line from the iface configuration for the device. Example change:
```
iface enp2s0d1 inet manual
    pre-up sleep 4
    bond-master bond0
```
to
```
iface enp2s0d1 inet manual
    pre-up sleep 4
    bond-master bond0
```
1. restart the network or reboot

Test:
- Set IPs on both machines.  Eg. First machine `ip addr add 172.16.99.31/24 dev enp2s0d1`, second machine `ip addr add 172.16.99.32/24 dev enp2s0d1`
  * If you have more than one VLAN be sure and set a VLAN id when setting an IP.  Eg. 
```
ip link add name enp2s0d1.1030 link enp2s0d1 type vlan id 1030 
ip addr add 172.16.99.31/24 dev enp2s0d1.1030
ifconfig enp2s0d1.1030 up
```
- ping from one machine to another using the new IP.  eg. `ping 172.16.99.31` from the 172.16.99.32 machine.



