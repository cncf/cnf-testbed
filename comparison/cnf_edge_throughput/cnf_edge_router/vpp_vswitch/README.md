# VPP vSwitch setup for the CNF Edge Througput comparison

Pre-req:
- Install VPP software


Goal: Configure VPP for bridging traffic from public network (Layer-2 on Packet.net) to container over memif.


Configuration steps:
- Create / update the main VPP configuration file, `/etc/vpp/startup.conf`, using the content from [comparison/cnf_edge_router/vpp_vswitch/etc/vpp/startup.conf](https://github.com/cncf/cnfs/blob/master/comparison/cnf_edge_throughput/cnf_edge_router/vpp_vswitch/etc/vpp/startup.conf)
- Create / update the  VPP configuration file, `/etc/vpp/setup.gate`, using the content from [comparison/cnf_edge_router/vpp_vswitch/etc/vpp/setup.gate](https://github.com/cncf/cnfs/blob/master/comparison/cnf_edge_throughput/cnf_edge_router/vpp_vswitch/etc/vpp/setup.gate)
- Create a `/etc/vpp/sockets` folder


---

Additional example configuration are in  [comparison/cnf_edge_throughput/cnf_edge_router/vpp_vswitch/etc/vpp/examples](https://github.com/cncf/cnfs/tree/master/comparison/cnf_edge_throughput/cnf_edge_router/vpp_vswitch/etc/vpp/examples)


## Provision and setup Packet.net machine with Layer-2 networking

### Instructions for deploying new machines from Packet.net web ui**

1. Log into the Packet.net dashboard at app.packet.net.  Select the org and project. (eg. CNCF, CNCF CNFs)
2. Click Servers
3. Click + New Servers button
4. Choose a hostname eg. cnf-edge-m2xl-04.
5. Choose Location
6. Choose m1.xlarge.x86 as Type
7. Choose Ubuntu 18.04 LTS as OS
8. Select desired SSH keys
9. Click Deploy Servers

### Setting up layer-2 networking for a Layer 3 provisioned Packet.net machines

**Add VLANs to the layer-2 network**

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
  

**Add VLAN(s) to the server **
  
1. Click Network screen for server (left column)
1. Sroll to bottom of screen to find Layer 2 section
1. Click ADD NEW VLAN
1. Select eth1 from the Interface drop-down
1. Select the VLAN to add
1. Click ADD button
