# Setup Packet.net machine with Layer-2 networking

### Setting up layer-2 networking for a Layer 3 provisioned Packet.net machines

**Add VLANs to the layer-2 network from Packet.net web ui**

If you need VLANs you can add them to the network.  For the CNF Edge Throughput comparison we are using two VLANS.

From the Packet.net web portal

1. Go to IPS & NETWORK tab
1. Click on Layer 2 on the left
1. Click Add VLAN
1. Select correct Facility/Location eg. SJC1
1. Choose a descriptive name eg. "1st sjc1 CNF testing dataplane network"
1. Click Add button

**Convert network from layer-3 to a hybrid (layer-2 + layer-3) network from the Packet web ui**

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
