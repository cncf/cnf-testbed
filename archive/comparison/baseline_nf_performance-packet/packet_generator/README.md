**Deploy the Packet Generator to an existing Packet.net node**

Start by ensuring that your system ssh keys are availiable under ~/.ssh/id_rsa and you have added the matching publickey to your packet.net account. Create an ansible inventory file with the desired hosts to provisioned, see ansible-inventory.example.

Example usage:
```
git clone --depth 1 https://github.com/cncf/cnfs.git
cd cnfs/comparison/cnf_edge_throughput/packet_generator
- Update ansible-inventory.example with desired nodes
./deploy_packet_generator.sh dual_mellanox ansible-inventory.example
```



**Deploy the Packet Generator to Packet.net using Terraform**

Start by ensuring that your system ssh keys are availiable under ~/.ssh/id_rsa and you have added the matching public key to your packet.net account. Set the environment variables for the project id (PACKET_PROJECT_ID), API key (PACKET_AUTH_TOKEN), facility (PACKET_FACILITY), machine type (PACKET_MASTER_DEVICE_PLAN) and OS (PACKET_OPERATING_SYSTEM).

Example usage:

```
git clone --depth 1 https://github.com/cncf/cnfs.git
cd cnfs/comparison/cnf_edge_throughput/packet_generator
export PACKET_PROJECT_ID=YOUR_PACKET_PROJECT_ID 
export PACKET_AUTH_TOKEN=YOUR_PACKET_API_KEY
export PACKET_FACILITY="sjc1"
export PACKET_MASTER_DEVICE_PLAN="x1.small.x86"
export PACKET_OPERATING_SYSTEM="ubuntu_16_04"
./terraform.sh
```


Running the ansible provisioning on an existing system:
```
docker run -v $(pwd)/ansible:/ansible -v ~/.ssh/id_rsa:/root/.ssh/id_rsa  --entrypoint /bin/bash -ti cnfdeploytools:latest
cd /ansible
ansible-playbook -i "IP_OF_PACKET_MACHINE," main.yml
```

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
hugepagesz=2M hugepages=8192"
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

**Install NFVbench**

Start by installing the docker prerequisites using the provided `install_docker_prereqs.sh` script which can be found in [comparison/cnf_edge_throughput](https://github.com/cncf/cnfs/tree/master/comparison/cnf_edge_throughput).

Once completed, run the provided `run_container.sh` script that pulls NFVbench and runs the container.

To simplify use of NFVbench, ass the following line to `~/.bashrc`
```
alias nfvbench="sudo docker exec -it nfvbench nfvbench -c /tmp/nfvbench/nfvbench_config.cfg"
```
Run `source ~/.bashrc` to apply the alias.

Find the PCI devices that will be used for traffic
```
lspci | grep Eth
  - Run 'apt-get --no-install-recommends install -y pciutils' if lspci is not installed
  5e:00.0 Ethernet controller: Mellanox Technologies MT27710 Family [ConnectX-4 Lx]
  5e:00.1 Ethernet controller: Mellanox Technologies MT27710 Family [ConnectX-4 Lx]
  5e:00.4 Ethernet controller: Mellanox Technologies MT27710 Family [ConnectX-4 Lx Virtual Function] (*)
  5e:00.5 Ethernet controller: Mellanox Technologies MT27710 Family [ConnectX-4 Lx Virtual Function] (*)
  - Note the IDs of the two virtual functions (in the above case the ones marked with *)
```

In `nfvbench_config.cfg`, update the "generator_profile" to match the PCI IDs collected in the previous step
```
generator_profile:
    - name: trex-local
      tool: TRex
      ip: 127.0.0.1
      cores: 7
      software_mode: false
      interfaces:
        - port: 0
          switch_port:
          pci: "5e:00.4"
        - port: 1
          switch_port:
          pci: "5e:00.5"
      intf_speed: 10Gbps
```
In the same file, also update "vlans" to match the network configuration between the servers
```
vlans: [1070, 1064]
```

Verify that NFVbench is running using `nfvbench --status`. Output should be similar to what can be seen below
```
INFO Loading configuration file: /tmp/nfvbench/nfvbench_config.cfg
INFO EXT chain with OpenStack mode disabled
INFO Version: 0.0.0
INFO Status: idle
```

The run specific settings for NFVbench can be changed in the configuration file, or it can be added as options through the command line.
A few of the most useful options can be found below, while the full list is available using `nfvbench --help`. Take note that several options might not be relevant with the setup used here (external)
```
  --rate <rate>           Rate in pps (Kpps, Mpps) or bps (Kbps, Gbps). Also supports pdr, ndr and ndr_pdr.
  --flow-count <flows>    Number of different flows to use for traffic. Useful when setup is configured with multiple queues (RSS)
  --duration <sec>        Number of seconds that traffic will run. For pdr, ndr and ndr_pdr this is for each step of the binary search
```

