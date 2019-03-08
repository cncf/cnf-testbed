#!/usr/bin/env bash

set -euxo pipefail

KERNEL_PATH="/opt/nested"

if [ ! -d "${KERNEL_PATH}"/boot ] ; then
  PKG=$(apt-cache depends -i linux-image-kvm | grep Depends: | cut -d: -f2 | tr -d '[:space:]')
  apt-get -y download ${PKG}
  sudo dpkg --extract ${PKG}_*.deb "${KERNEL_PATH}"
  rm ${PKG}_*.deb
fi

KERNEL_BIN="$(ls ${KERNEL_PATH}/boot/vmlinuz-*-kvm)"

INIT=$(mktemp)
VPP_STARTUP="/etc/thinvm_vpp_startup_${2}.conf"
VPP_SETUP="/etc/thinvm_vpp_setup_${2}.conf"

cat > ${VPP_SETUP} << __EOF__
sh ver
set interface state GigabitEthernet0/6/0 up
set interface state GigabitEthernet0/7/0 up
__EOF__

cat > ${VPP_STARTUP} << __EOF__
unix {
  cli-listen /run/vpp/cli-vm.sock
  startup-config ${VPP_SETUP}
  nodaemon
}
cpu
{
  corelist-workers 1
  main-core 0
}
dpdk {
  dev 0000:00:06.0
  dev 0000:00:07.0
  uio-driver vfio_pci
  log-level debug
  dev default {
    num-rx-queues 1
  }
  no-tx-checksum-offload
  no-multi-seg
}
plugins
{
  plugin default
  {
    disable
  }
  plugin dpdk_plugin.so
  {
    enable
  }
  plugin memif_plugin.so
  {
    enable
  }
}
__EOF__

if [ "${1}" == 'vpp' ]; then
    NF_BIN="/usr/bin/vpp -c ${VPP_STARTUP}"
elif [ "${1}" == 'testpmd' ]; then
    NF_BIN="/opt/dpdk-18.11/x86_64-native-linuxapp-gcc/app/testpmd --in-memory --master-lcore 1 -l 0-1 -- --forward-mode=io --burst=64 --txd=1024 --rxd=1024 --txq=1 --rxq=1"
else
    echo "Usage: ./${0} <testpmd|vpp> <id>"
    exit 1
fi

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
${NF_BIN}
poweroff -f
__EOF__

chmod +x ${INIT}
#-chardev stdio,mux=on,id=char0 \

sudo qemu-system-x86_64 \
  -name ${2} \
  -daemonize \
  -nodefaults \
  -no-user-config \
  -monitor none \
  -display none \
  -vga none \
  -object memory-backend-file,id=mem,size=2G,mem-path=/dev/huge,share=on \
  -m 2G \
  -numa node,memdev=mem \
  -balloon none \
  -cpu host \
  -smp 2,sockets=1,cores=2,threads=1 \
  -machine pc,accel=kvm,usb=off,mem-merge=off \
  -chardev file,id=char0,path=${2}.log \
  -device isa-serial,chardev=char0 \
  -kernel ${KERNEL_BIN} \
  -fsdev local,id=root9p,path=/,security_model=none \
  -device virtio-9p-pci,fsdev=root9p,mount_tag=/dev/root \
  -device virtio-net-pci,netdev=net0,mac=52:54:00:00:04:01,bus=pci.0,addr=6.0,mq=on,tx_queue_size=1024,rx_queue_size=1024,csum=off,gso=off,guest_tso4=off,guest_tso6=off,guest_ecn=off,mrg_rxbuf=off \
  -chardev socket,id=socket0,path=/var/run/vpp/sock_${2}_1.sock,server \
  -netdev vhost-user,id=net0,chardev=socket0,queues=1 \
  -device virtio-net-pci,netdev=net1,mac=52:54:00:00:04:02,bus=pci.0,addr=7.0,mq=on,tx_queue_size=1024,rx_queue_size=1024,csum=off,gso=off,guest_tso4=off,guest_tso6=off,guest_ecn=off,mrg_rxbuf=off \
  -chardev socket,id=socket1,path=/var/run/vpp/sock_${2}_2.sock,server \
  -netdev vhost-user,id=net1,chardev=socket1,queues=1 \
  -pidfile /tmp/qemu_${1}.pid \
  -append "ro rootfstype=9p rootflags=trans=virtio console=ttyS0 tsc=reliable hugepages=256 init=${INIT}"

#rm ${INIT}
#rm ${VPP_SETUP}
#rm ${VPP_STARTUP}
