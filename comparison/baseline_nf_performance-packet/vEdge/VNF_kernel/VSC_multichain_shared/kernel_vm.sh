#!/usr/bin/env bash

set -euo pipefail


function boot_vm () {
    # Boot VM by runnign QEMU.
    #
    # Variable read:
    # - ${VM_ID} - VM ID.
    # - ${MAC1} - East side MAC.
    # - ${MAC2} - West side MAC.
    # - ${SOCK_OFFSET} - Socket offset.
    # - ${NODE} - Node ID.

    set -euxo pipefail

    sudo qemu-system-x86_64 \
        -name vnf"${VM_ID}",debug-threads=on \
        -daemonize \
        -nodefaults \
        -no-user-config \
        -monitor none \
        -display none \
        -vga none \
        -object memory-backend-file,id=mem,size=4096M,mem-path=/dev/hugepages,share=on \
        -m 4096M \
        -numa node,memdev=mem \
        -balloon none \
        -cpu host \
        -smp 3,cores=3,sockets=1,threads=1 \
        -machine pc,accel=kvm,usb=off,mem-merge=off \
        -chardev file,id=char0,path=/tmp/serial_"${VM_ID}".log \
        -device isa-serial,chardev=char0 \
        -kernel $(readlink -m /opt/boot/* | tail -1) \
        -fsdev local,id=root9p,path=/,security_model=none \
        -device virtio-9p-pci,fsdev=root9p,mount_tag=/dev/root \
        -device virtio-net-pci,netdev=net0,mac="${MAC1}",bus=pci.0,addr=6.0,mq=on,tx_queue_size=1024,rx_queue_size=1024,csum=off,gso=off,guest_tso4=off,guest_tso6=off,guest_ecn=off,mrg_rxbuf=off \
        -chardev socket,id=socket0,path=/etc/vpp/sockets/sock$((${SOCK_OFFSET} + (${NODE} * 2 - 1))).sock \
        -netdev vhost-user,id=net0,chardev=socket0,queues=1 \
        -device virtio-net-pci,netdev=net1,mac="${MAC2}",bus=pci.0,addr=7.0,mq=on,tx_queue_size=1024,rx_queue_size=1024,csum=off,gso=off,guest_tso4=off,guest_tso6=off,guest_ecn=off,mrg_rxbuf=off \
        -chardev socket,id=socket1,path=/etc/vpp/sockets/sock$((${SOCK_OFFSET} + (${NODE} * 2))).sock \
        -netdev vhost-user,id=net1,chardev=socket1,queues=1 \
        -pidfile /var/run/qemu_"${VM_ID}".pid \
        -append "ro rootfstype=9p rootflags=trans=virtio console=ttyS0 tsc=reliable hugepages=256 init=${INIT}"

    set +x
}


function check_booted_vm () {
    # Check if kernel image exists.
    #
    # Variable read:
    # - ${VM_ID} - VM ID.

    set -euo pipefail

    vpp_ver=$(sudo vppctl show version)
    for i in {1..60}; do
        vm_vpp_ver=$(sudo tail -1 /tmp/serial_"${VM_ID}".log)
        if [[ "${vpp_ver}" == "${vm_vpp_ver}" ]]; then
            warn "VNF ${VM_ID} booted!"
            exit 0
        fi
        sleep 1
    done
}

function check_kernel_image () {
    # Check if kernel image exists.

    set -euo pipefail

    kernel_path="/opt/"

    if [ ! -d "${kernel_path}"/boot ] ; then
        pkg=$(apt-cache depends -i linux-image-kvm | grep Depends: | cut -d' ' -f4)
        apt-get -y download ${pkg}
        sudo dpkg --extract ${pkg}_*.deb "${kernel_path}"
        rm ${pkg}_*.deb
    fi
}


function die () {
    # Print the message to standard error end exit with error code specified
    # by the second argument.
    #
    # Hardcoded values:
    # - The default error message.
    # Arguments:
    # - ${1} - The whole error message, be sure to quote. Optional
    # - ${2} - the code to exit with, default: 1.

    set -x
    set +eu
    warn "${1:-Unspecified run-time error occurred!}"
    exit "${2:-1}"
}


function set_remote_ips () {
    # Set remote IPs.
    #
    # Variable read:
    # - ${NODE} - Node ID.
    # - ${CHAIN} - Chain ID.
    # - ${NODES} - Number of NFs in chain.
    # Variable set:
    # - ${REMIP1} - East IP.
    # - ${REMIP2} - West IP.

    set -euo pipefail

    if [[ "${NODE}" == "1" ]] && [[ "${NODES}" == "1" ]]; then
        REMIP1=172.16.10.10$(( ${CHAIN} - 1 ))
        REMIP2=172.16.20.10$(( ${CHAIN} - 1 ))
    elif [[ "${NODE}" == "1" ]]; then
        REMIP1=172.16.10.10$(( ${CHAIN} - 1 ))
        REMIP2=172.16.31.11
    elif [[ "${NODE}" == "${NODES}" ]]; then
        REMIP1=172.16.$(($NODE + 29)).10
        REMIP2=172.16.20.10$(( ${CHAIN} - 1 ))
    else
        REMIP1=172.16.$(($NODE + 29)).10
        REMIP2=172.16.$(($NODE + 30)).11
    fi
}


function set_remote_macs () {
    # Set ARP MACs.
    #
    # Variable read:
    # - ${CHAIN} - Chain ID.
    # - ${NODE} - Node ID.
    # - ${NODES} - Number of NFs in chain.
    # Variable set:
    # - ${REMMAC1} - East MAC.
    # - ${REMMAC2} - West MAC.

    set -euo pipefail

    trex_mac1=3c:fd:fe:a8:ab:98
    trex_mac2=3c:fd:fe:a8:ab:99

    if [[ "${NODE}" == "1" ]] && [[ "${NODES}" == "1" ]]; then
        REMMAC1=${trex_mac1}
        REMMAC2=${trex_mac2}
    elif [[ "${NODE}" == "1" ]]; then
        REMMAC1=${trex_mac1}
        REMMAC2=52:54:0$(( ${CHAIN} - 1 )):00:02:aa
    elif [[ "${NODE}" == "${NODES}" ]]; then
        REMMAC1=52:54:0$(( ${CHAIN} - 1 )):00:0$(($NODE - 1)):bb
        REMMAC2=${trex_mac2}
    else
        REMMAC1=52:54:0$(( ${CHAIN} - 1 )):00:0$(($NODE - 1)):bb
        REMMAC2=52:54:0$(( ${CHAIN} - 1 )):00:0$(($NODE + 1)):aa
    fi
}


function set_subnets () {
    # Set subnets.
    #
    # Variable read:
    # - ${CHAIN} - Chain ID.
    # - ${NODE} - Node ID.
    # - ${NODES} - Number of NFs in chain.
    # Variable set:
    # - ${SUBNET1} - East subnet.
    # - ${SUBNET2} - West subnet.

    set -euo pipefail

    if [[ "${NODE}" == "1" ]] && [[ "${NODES}" == "1" ]]; then
        SUBNET1=172.16.10.1$(( ${CHAIN} - 1 ))/24
        SUBNET2=172.16.20.1$(( ${CHAIN} - 1 ))/24
    elif [[ "${NODE}" == "1" ]]; then
        SUBNET1=172.16.10.1$(( ${CHAIN} - 1 ))/24
        SUBNET2=172.16.31.10/24
    elif [[ "${NODE}" == "${NODES}" ]]; then
        SUBNET1=172.16.$(($NODE + 29)).11/24
        SUBNET2=172.16.20.1$(( ${CHAIN} - 1 ))/24
    else
        SUBNET1=172.16.$(($NODE + 29)).11/24
        SUBNET2=172.16.$(($NODE + 30)).10/24
    fi
}


function set_macs () {
    # Set interface MACs.
    #
    # Variable read:
    # - ${CHAIN} - Chain ID.
    # - ${NODE} - Node ID.
    # - ${NODES} - Number of NFs in chain.
    # Variable set:
    # - ${MAC1} - East MAC.
    # - ${MAC2} - West MAC.

    set -euo pipefail

    if [[ "${NODE}" == "1" ]] && [[ "${NODES}" == "1" ]]; then
        MAC1=52:54:0$((${CHAIN} - 1)):00:00:aa
        MAC2=52:54:0$((${CHAIN} - 1)):00:00:bb
    elif [[ "${NODE}" == "1" ]]; then
        MAC1=52:54:0$((${CHAIN} - 1)):00:00:aa
        MAC2=52:54:0$((${CHAIN} - 1)):00:01:bb
    elif [[ "${NODE}" == "${NODES}" ]]; then
        MAC1=52:54:0$((${CHAIN} - 1)):00:0$((${NODE} - 1)):aa
        MAC2=52:54:0$((${CHAIN} - 1)):00:00:bb
    else
        MAC1=52:54:0$((${CHAIN} - 1)):00:0$((${NODE} - 1)):aa
        MAC2=52:54:0$((${CHAIN} - 1)):00:0$((${NODE} + 1)):bb
    fi
}


function validate_input() {
    # Validate script input.
    #
    # Arguments:
    # - ${@} - Script parameters.
    # Variable set:
    # - ${CHAIN} - Chain ID.
    # - ${NODE} - Node ID.
    # - ${NODES} - Number of NFs in chain.
    # - ${OPERATION} - Operation bit [baseline].

    set -euo pipefail

    if [[ "${#}" -lt "3" ]]; then
        warn "  Usage: ${0} <Chain ID> <Node ID> <Total Nodes in Chain>"
        die "ERROR - Exactly 3 input arguments required!"
    fi

    CHAIN="${1}"
    NODE="${2}"
    NODES="${3}"

    if [[ -n ${CHAIN//[0-9]/} ]] || [[ -n ${NODE//[0-9]/} ]] || [[ -n ${NODES//[0-9]/} ]]; then
        die "ERROR: Chain, node and nodes must be an integer values!"
    fi

    if [[ "${CHAIN}" -lt "1" ]] || [[ "${CHAIN}" -gt "8" ]]; then
        die "ERROR: Chain must be an integer value between 1-8!"
    fi

    if [[ "${NODE}" -lt "1" ]] || [[ "${NODE}" -gt "10" ]]; then
        die "ERROR: Node must be an integer value between 1-8!"
    fi
}


function warn () {
    # Print the message to standard error.
    #
    # Arguments:
    # - ${@} - The text of the message.

    echo "$@" >&2
}


check_kernel_image || die
validate_input "${@}" || die
set_subnets || die
set_remote_ips || die
set_remote_macs || die
set_macs || die

VM_ID="$(( (${CHAIN} - 1) * ${NODES} + ${NODE} ))"
SOCK_OFFSET="$(( (${CHAIN} - 1) * ${NODES} * 2 ))"

INIT="/etc/thinvm_init_${VM_ID}.conf"
VPP_STARTUP="/etc/thinvm_vpp_startup_${VM_ID}.conf"
VPP_SETUP="/etc/thinvm_vpp_setup_${VM_ID}.conf"

cat > ${VPP_SETUP} << __EOF__
set int state GigabitEthernet0/6/0 up
set interface ip address GigabitEthernet0/6/0 ${SUBNET1}

set int state  GigabitEthernet0/7/0 up
set interface ip address GigabitEthernet0/7/0 ${SUBNET2}

set ip arp static GigabitEthernet0/6/0 ${REMIP1} ${REMMAC1}
set ip arp static GigabitEthernet0/7/0 ${REMIP2} ${REMMAC2}

ip route add 172.16.64.0/18 via ${REMIP1}
ip route add 172.16.192.0/18 via ${REMIP2}
show version
__EOF__

cat > ${VPP_STARTUP} << __EOF__
unix {
  nodaemon
  log /tmp/log-vm.log
  startup-config ${VPP_SETUP}
  cli-listen /tmp/cli-vm.sock
}
cpu {
  main-core 0
  corelist-workers 1-2
}
dpdk {
  dev 0000:00:06.0
  dev 0000:00:07.0
  log-level debug
  no-multi-seg
  no-tx-checksum-offload
}
plugins {
  plugin default { disable }
  plugin dpdk_plugin.so { enable }
}
__EOF__

cat > ${INIT} << __EOF__
#!/bin/bash
mount -t sysfs -o "nodev,noexec,nosuid" sysfs /sys
mount -t proc -o "nodev,noexec,nosuid" proc /proc
mkdir /dev/pts
mount -t devpts -o "rw,noexec,nosuid,gid=5,mode=0620" devpts /dev/pts || true
mount -t tmpfs -o "rw,noexec,nosuid,size=10%,mode=0755" tmpfs /run
mount -t tmpfs -o "rw,noexec,nosuid,size=10%,mode=0755" tmpfs /tmp
echo 0000:00:06.0 > /sys/bus/pci/devices/0000:00:06.0/driver/unbind
echo 0000:00:07.0 > /sys/bus/pci/devices/0000:00:07.0/driver/unbind
echo uio_pci_generic > /sys/bus/pci/devices/0000:00:06.0/driver_override
echo uio_pci_generic > /sys/bus/pci/devices/0000:00:07.0/driver_override
echo 0000:00:06.0 > /sys/bus/pci/drivers/uio_pci_generic/bind
echo 0000:00:07.0 > /sys/bus/pci/drivers/uio_pci_generic/bind
/usr/bin/vpp -c ${VPP_STARTUP}
poweroff -f
__EOF__

chmod +x ${INIT}

boot_vm || die
check_booted_vm || die

die "Failed to boot VNF ${VM_ID}!"
