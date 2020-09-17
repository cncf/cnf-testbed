#!/bin/bash
set -o xtrace  # print commands during script execution

#sudo apt-get update -y
#sudo apt-get --no-install-recommends install -y --allow-unauthenticated make wget gcc libcurl4-openssl-dev python-pip bridge-utils apt-transport-https ca-certificates
#pip install jsonschema

#sudo apt-get --no-install-recommends install -y linux-headers-$(uname -r)

# Install VPP
#export UBUNTU="xenial"
#export RELEASE=".stable.1804"
#sudo rm /etc/apt/sources.list.d/99fd.io.list
#sudo echo "deb [trusted=yes] https://nexus.fd.io/content/repositories/fd.io$RELEASE.ubuntu.$UBUNTU.main/ ./" | sudo tee -a /etc/apt/sources.list.d/99fd.io.list
#sudo apt-get update
#sudo apt-get --no-install-recommends install -y vpp vpp-dpdk-dkms vpp-lib vpp-dbg vpp-plugins vpp-dev
#sleep 1

#sudo sed -i 's/^.*\(net.ipv4.ip_forward\).*/\1=1/g' /etc/sysctl.conf
#sudo sysctl -p /etc/sysctl.conf

#get_nic_pci_list() {
#  while read -r line ; do
#    if [ "$line" != "${line#*network device}" ]; then
#      echo -n "${line%% *} "
#    fi
#  done < <(lspci)
#}

#sudo sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="isolcpus=1,2 nohz_full=1,2 rcu_nocbs=1,2 biosdevname=0"/g' /etc/default/grub
#sudo update-grub2

# Stop the VPP service before changing the configuration
sudo service vpp stop

## Bring interfaces down to prepare for VPP (DPDK)
#sudo ifconfig eth1 down
#sudo ifconfig eth2 down
#sudo ip addr flush dev eth1
#sudo ip addr flush dev eth2

pci_search="Intel Corporation Ethernet Controller"
pci_devs=($(lspci | grep "$pci_search" | awk '{print $1}'))
dev_list=""
if [ ! "${#pci_devs[@]}" == "0" ]; then
  for dev in ${pci_devs[@]}; do
    dev_list+="dev 0000:$dev "
  done
fi

/vagrant/dpdk-devbind.py -b igb_uio ${pci_devs[@]}

# Overwrite default VPP configuration 
sudo bash -c "cat > /etc/vpp/startup.conf" <<EOF

unix {
  nodaemon
  log /var/log/vpp/vpp.log
  full-coredump
  cli-listen /run/vpp/cli.sock
  gid vpp
  startup-config /etc/vpp/setup.gate
}

api-trace {
## This stanza controls binary API tracing. Unless there is a very strong reason,
## please leave this feature enabled.
  on
## Additional parameters:
##
## To set the number of binary API trace records in the circular buffer, configure nitems
##
## nitems <nnn>
##
## To save the api message table decode tables, configure a filename. Results in /tmp/<filename>
## Very handy for understanding api message changes between versions, identifying missing
## plugins, and so forth.
##
## save-api-table <filename>
}

api-segment {
  gid vpp
}

cpu {
        ## In the VPP there is one main thread and optionally the user can create worker(s)
        ## The main thread and worker thread(s) can be pinned to CPU core(s) manually or automatically

        ## Manual pinning of thread(s) to CPU core(s)

        ## Set logical CPU core where main thread runs
        main-core 0

        ## Set logical CPU core(s) where worker threads are running
        corelist-workers 1-2

        ## Automatic pinning of thread(s) to CPU core(s)

        ## Sets number of CPU core(s) to be skipped (1 ... N-1)
        ## Skipped CPU core(s) are not used for pinning main thread and working thread(s).
        ## The main thread is automatically pinned to the first available CPU core and worker(s)
        ## are pinned to next free CPU core(s) after core assigned to main thread
        # skip-cores 4

        ## Specify a number of workers to be created
        ## Workers are pinned to N consecutive CPU cores while skipping "skip-cores" CPU core(s)
        ## and main thread's CPU core
        # workers 2

        ## Set scheduling policy and priority of main and worker threads

        ## Scheduling policy options are: other (SCHED_OTHER), batch (SCHED_BATCH)
        ## idle (SCHED_IDLE), fifo (SCHED_FIFO), rr (SCHED_RR)
        # scheduler-policy fifo

        ## Scheduling priority is used only for "real-time policies (fifo and rr),
        ## and has to be in the range of priorities supported for a particular policy
        # scheduler-priority 50
}

dpdk {
        ## Change default settings for all intefaces
        # dev default {
                ## Number of receive queues, enables RSS
                ## Default is 1
                # num-rx-queues 3

                ## Number of transmit queues, Default is equal
                ## to number of worker threads or 1 if no workers treads
                # num-tx-queues 3

                ## Number of descriptors in transmit and receive rings
                ## increasing or reducing number can impact performance
                ## Default is 1024 for both rx and tx
                # num-rx-desc 512
                # num-tx-desc 512

                ## VLAN strip offload mode for interface
                ## Default is off
                # vlan-strip-offload on
        # }

        ## Whitelist specific interface by specifying PCI address
        ${dev_list}

        ## Whitelist specific interface by specifying PCI address and in
        ## addition specify custom parameters for this interface
        # dev 0000:02:00.1 {
        #       num-rx-queues 2
        # }

        ## Specify bonded interface and its slaves via PCI addresses
        ##
        ## Bonded interface in XOR load balance mode (mode 2) with L3 and L4 headers
        # vdev eth_bond0,mode=2,slave=0000:02:00.0,slave=0000:03:00.0,xmit_policy=l34
        # vdev eth_bond1,mode=2,slave=0000:02:00.1,slave=0000:03:00.1,xmit_policy=l34
        ##
        ## Bonded interface in Active-Back up mode (mode 1)
        # vdev eth_bond0,mode=1,slave=0000:02:00.0,slave=0000:03:00.0
        # vdev eth_bond1,mode=1,slave=0000:02:00.1,slave=0000:03:00.1

        ## Change UIO driver used by VPP, Options are: igb_uio, vfio-pci,
        ## uio_pci_generic or auto (default)
        # uio-driver vfio-pci

        ## Disable mutli-segment buffers, improves performance but
        ## disables Jumbo MTU support
        no-multi-seg

        ## Increase number of buffers allocated, needed only in scenarios with
        ## large number of interfaces and worker threads. Value is per CPU socket.
        ## Default is 16384
        # num-mbufs 128000

        ## Change hugepages allocation per-socket, needed only if there is need for
        ## larger number of mbufs. Default is 256M on each detected CPU socket
        # socket-mem 2048,2048

        ## Disables UDP / TCP TX checksum offload. Typically needed for use
        ## faster vector PMDs (together with no-multi-seg)
        # no-tx-checksum-offload
}


# plugins {
        ## Adjusting the plugin path depending on where the VPP plugins are
        #       path /home/bms/vpp/build-root/install-vpp-native/vpp/lib64/vpp_plugins

        ## Disable all plugins by default and then selectively enable specific plugins
        # plugin default { disable }
        # plugin dpdk_plugin.so { enable }
        # plugin acl_plugin.so { enable }

        ## Enable all plugins by default and then selectively disable specific plugins
        # plugin dpdk_plugin.so { disable }
        # plugin acl_plugin.so { disable }
# }

        ## Alternate syntax to choose plugin path
        # plugin_path /home/bms/vpp/build-root/install-vpp-native/vpp/lib64/vpp_plugins
EOF

sudo service vpp start
sleep 10

# Pre-heating the API so that the following works (workaround?)
sudo vppctl show int

intfs=($(sudo vppctl show int | grep TenGig | awk '{print $1}'))
if [ ! "${#intfs[@]}" == "2" ]; then
  echo "ERROR: Number of interfaces should be 2 (is ${#intfs[@]})"
  exit 1
fi

# Create interface configuration for VPP
sudo bash -c "cat > /etc/vpp/setup.gate" <<EOF

set int state ${intfs[0]} up
set interface ip address ${intfs[0]} 10.3.0.10/24

set int state ${intfs[1]} up
set interface ip address ${intfs[1]} 10.1.0.10/24

set ip arp static ${intfs[0]} 10.3.0.120 3c:fd:fe:a8:ab:98
set ip arp static ${intfs[1]} 10.1.0.120 3c:fd:fe:a8:ab:99

##set int state ${BNG_GMUX_NIC} up
##set interface ip address ${BNG_GMUX_NIC} ${BNG_GMUX_NET_IPADDR}/${BNG_GMUX_NET_CIDR#*/}

##set vbng dhcp4 remote 10.4.0.1 local ${CPE_SIGNAL_NET_IPADDR}
##set vbng aaa config /etc/vpp/vbng-aaa.cfg nas-port 5060

##tap connect tap0 address 192.168.40.40/24
##set int state tapcli-0 up
##set int ip address tapcli-0 192.168.40.41/24
##ip route add ${SDNC_IP_ADDR}/32 via 192.168.40.40 tapcli-0
EOF

service vpp restart
