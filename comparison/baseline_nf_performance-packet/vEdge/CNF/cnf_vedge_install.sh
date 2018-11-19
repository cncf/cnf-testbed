#! /bin/bash

# Prepare files
cd /vEdge

apt-get update -y
apt-get install --allow-unauthenticated -y make wget gcc libcurl4-openssl-dev python-pip bridge-utils apt-transport-https ca-certificates vim
pip install jsonschema

# Install VPP
VPP_VERSION="18.10-release"
artifacts=()
vpp=(vpp vpp-dbg vpp-dev vpp-lib vpp-plugins)
if [ -z "${VPP_VERSION-}" ]; then
    artifacts+=(${vpp[@]})
else
    artifacts+=(${vpp[@]/%/=${VPP_VERSION-}})
fi
curl -s https://packagecloud.io/install/repositories/fdio/release/script.deb.sh | bash
apt-get install -y "${artifacts[@]}"
sleep 1

bash -c "cat > /etc/vpp/startup.conf" <<EOF

unix {
  nodaemon
  log /var/log/vpp/vpp.log
  full-coredump
  cli-listen /run/vpp/cli.sock
  gid vpp
  startup-config /etc/vpp/setup.gate
}

api-trace {
  on
}

api-segment {
  gid vpp
}

cpu {
  main-core 10
  corelist-workers 12,40
}

dpdk {
  no-pci
  # dev default {
    # num-rx-queues 2
    # num-tx-queues 3

    # num-rx-desc 1024
    # num-tx-desc 1024
  # }
  # dev 0000:18:00.2
  # uio-driver igb_uio
  no-multi-seg
  no-tx-checksum-offload
}

plugins {
  plugin default { disable }
  plugin dpdk_plugin.so { enable }
  plugin memif_plugin.so { enable }
}
EOF

# Create interface configuration for VPP
bash -c "cat > /etc/vpp/setup.gate" <<EOF
bin memif_socket_filename_add_del add id 1 filename /run/vpp/memif1.sock
bin memif_socket_filename_add_del add id 2 filename /run/vpp/memif2.sock
create interface memif id 1 socket-id 1 hw-addr 52:54:00:00:00:aa slave rx-queues 1 tx-queues 1
create interface memif id 2 socket-id 2 hw-addr 52:54:00:00:00:bb slave rx-queues 1 tx-queues 1
set int ip addr memif1/1 172.16.10.10/24
set int ip addr memif2/2 172.16.20.10/24
set int state memif1/1 up
set int state memif2/2 up

set ip arp static memif1/1 172.16.10.100 8a:fd:d5:d5:d6:b6
set ip arp static memif2/2 172.16.20.100 06:9c:b3:cc:f0:62

ip route add 172.16.64.0/18 via 172.16.10.100
ip route add 172.16.192.0/18 via 172.16.20.100
EOF

