**Install the Mellanox drivers and prepare the host environment**

Download and install MLNX_OFED_LINUX-4.4-2.0.7.0:
```
cd /tmp
wget http://content.mellanox.com/ofed/MLNX_OFED-4.4-2.0.7.0/MLNX_OFED_LINUX-4.4-2.0.7.0-ubuntu18.04-x86_64.tgz
tar zxvf MLNX_OFED_LINUX-4.4-2.0.7.0-ubuntu18.04-x86_64.tgz
cd MLNX_OFED_LINUX-4.4-2*
./mlnxofedinstall --dpdk --upstream-libs --force
[when prompted] /etc/init.d/openibd restart
```

Update GRUB (`/etc/default/grub`) to include the following settings
```
"numa_balancing=disable intel_pstate=disable intel_iommu=on iommu=pt isolcpus=2,4,6,8,30,32,34,36 nohz_full=2-27,30-55 rcu_nocbs=2-27,30-55 hugepagesz=2M hugepages=4096"
```
The full content of the file should look similar the one below
```
GRUB_DEFAULT=0
GRUB_HIDDEN_TIMEOUT=0
GRUB_HIDDEN_TIMEOUT_QUIET=true
GRUB_TIMEOUT=10
GRUB_DISTRIBUTOR=Ubuntu
GRUB_CMDLINE_LINUX_DEFAULT="console=tty0 console=ttyS1,115200n8 biosdevname=0 net.ifnames=1"
GRUB_CMDLINE_LINUX="numa_balancing=disable intel_pstate=disable intel_iommu=on iommu=pt isolcpus=2,4,6,8,30,32,34,36 nohz_full=2-27,30-55 rcu_nocbs=2-27,30-55 hugepagesz=2M hugepages=4096"
GRUB_TERMINAL=serial
GRUB_SERIAL_COMMAND="serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1"
```
Once the GRUB file has been updated, run `update-grub2`

Run `cat /sys/class/net/bond0/bonding/slaves` and note down the second interface, e.g. `enp94s0f1`.
Create `/etc/rc.local` if it doesn't already exist, otherwise update the existing file. Ensure that the following lines are present with the interface found during the previous step
```
#!/bin/sh -e
echo "-enp94s0f1" > /sys/class/net/bond0/bonding/slaves
```
Run `chmod +x /etc/rc.local` to ensure the file has sufficient permissions

Once this is done the server can be restarted using `reboot`

**Install VPP**

Find the PCI devices that will be used for traffic
```
lspci | grep Eth
  - Run 'apt-get --no-install-recommends install -y pciutils' if lspci is not installed
  5e:00.0 Ethernet controller: Mellanox Technologies MT27710 Family [ConnectX-4 Lx]
  5e:00.1 Ethernet controller: Mellanox Technologies MT27710 Family [ConnectX-4 Lx]
```
By default the installation script will use `5e:00.1`. If a different device is to be used, the device needs to be updated in `VPP_configs/vEdge_startup.conf`. Locate the following line and update with correct PCI device, and make sure to include the 0000: prefix
```
dev 0000:5e:00.1
```

By default VLANs 1070 and 1064 are used. If your setup uses different VLANs run `./update_vlans.sh VLAN#1 VLAN#2`, replacing VLAN#1-2 with the VLANs configured for your environment.

Run the provided `install_vpp.sh` script that automates most of the installation. You will likely get prompted to install packages (dependencies) soon after running the script. Accept the download/installation and let the script run. 

Once complete, verify that VPP is running using `vppctl show ver`, which should show information about the build.

If VPP isn't running check `service vpp status` for errors. If this doesn't provide sufficient information try running VPP directly from the terminal using `/usr/bin/vpp -c /etc/vpp/startup.conf`.

**(Outdated) VPP vSwitch setup for the CNF Edge Througput comparison**

Pre-req:
- Install VPP software


Goal: Configure VPP for bridging traffic from public network (Layer-2 on Packet.net) to container over memif.


Configuration steps:
- Create / update the main VPP configuration file, `/etc/vpp/startup.conf`, using the content from [comparison/cnf_edge_router/vpp_vswitch/etc/vpp/startup.conf](https://github.com/cncf/cnfs/blob/master/comparison/cnf_edge_throughput/cnf_edge_router/vpp_vswitch/etc/vpp/startup.conf)
- Create / update the  VPP configuration file, `/etc/vpp/setup.gate`, using the content from [comparison/cnf_edge_router/vpp_vswitch/etc/vpp/setup.gate](https://github.com/cncf/cnfs/blob/master/comparison/cnf_edge_throughput/cnf_edge_router/vpp_vswitch/etc/vpp/setup.gate)
- Create a `/etc/vpp/sockets` folder


---

Additional example configuration are in  [comparison/cnf_edge_throughput/cnf_edge_router/vpp_vswitch/etc/vpp/examples](https://github.com/cncf/cnfs/tree/master/comparison/cnf_edge_throughput/cnf_edge_router/vpp_vswitch/etc/vpp/examples)
