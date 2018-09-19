**Install the Mellanox drivers, libs, tools and dependencies**

Note: We are using an older version of the Mellanox_OFED to work with Ubuntu 16.04 (what's needed by the TRex NFVbench uses).


```
cd /tmp
wget http://content.mellanox.com/ofed/MLNX_OFED-4.1-1.0.2.0/MLNX_OFED_LINUX-4.1-1.0.2.0-ubuntu16.04-x86_64.tgz
tar zxvf MLNX_OFED_LINUX-4.1-1.0.2.0-ubuntu16.04-x86_64.tgz
cd MLNX_OFED_LINUX-4.1-1*
./mlnxofedinstall --dpdk --upstream-libs --force
[when prompted] /etc/init.d/openibd restart
```

**Configure server to prepare for NFVbench**

Start by ensuring that Virtual Functions (VFs) are configured in the firmware
```
mst start
mst status
  - Note down the MST Device path, e.g. '/dev/mst/mt4117_pciconf0'
mlxconfig -d /dev/mst/mt4117_pciconf0 set SRIOV_EN=1 NUM_OF_VFS=2
  - Use device path collected during the previous step
```

Update GRUB (`/etc/default/grub`) to include the following settings
```
"numa_balancing=disable intel_pstate=disable intel_iommu=on iommu=pt isolcpus=2-55 nohz_full=2-55 rcu_nocbs=2-55
hugepagesz=2M hugepages=8096"
```
The full content of the file should look similar the one below
```
GRUB_DEFAULT=0
GRUB_HIDDEN_TIMEOUT=0
GRUB_HIDDEN_TIMEOUT_QUIET=true
GRUB_TIMEOUT=10
GRUB_DISTRIBUTOR=Ubuntu
GRUB_CMDLINE_LINUX_DEFAULT="console=tty0 console=ttyS1,115200n8 biosdevname=0 net.ifnames=1"
GRUB_CMDLINE_LINUX="numa_balancing=disable intel_pstate=disable intel_iommu=on iommu=pt isolcpus=2-55 nohz_full=2-55 rcu_nocbs=2-55
hugepagesz=2M hugepages=8096"
GRUB_TERMINAL=serial
GRUB_SERIAL_COMMAND="serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1"
```
Once the GRUB file has been updated, run `update-grub2`

Run `cat /sys/class/net/bond0/bonding/slaves` and note down the second interface, e.g. `enp94s0f1`.
Create `/etc/rc.local` if it doesn't already exist, otherwise update the existing file. Ensure that the following lines are present with the interface found during the previous step
```
#!/bin/sh -e
echo "-enp94s0f1" > /sys/class/net/bond0/bonding/slaves
echo 2 > /sys/class/net/enp94s0f1/device/sriov_numvfs
exit 0
```
Run `chmod +x /etc/rc.local` to ensure the file has sufficient permissions

Once this is done the server can be restarted using `reboot`

