#!/usr/bin/env bash

set -euo pipefail

chain=${1}
node=${2}
nodes=${3}

sudo service vpp stop

pci_search=":1000:0200"
pci_devs=($(lspci -d "${pci_search}" | awk '{print $1}' | grep -v "00:05.0"))
if [ "${#pci_devs[@]}" == "0" ]; then
    echo "ERROR: No PCI devices detected!"
    exit 1
fi

chmod +x /vagrant/dpdk-devbind.py && \
    sudo /vagrant/dpdk-devbind.py -b uio_pci_generic ${pci_devs[@]} || true

# Overwrite default VPP configuration
sudo bash -c "cat > /etc/vpp/startup.conf" <<EOF

unix {
  nodaemon
  log /var/log/vpp/vpp.log
  full-coredump
  cli-listen /run/vpp/cli.sock
  gid vpp
  startup-config /etc/vpp/setup.gate
  cli-prompt c${chain}v${node}Edge:
}
api-trace {
  on
}
api-segment {
  gid vpp
}
cpu {
  main-core 0
  corelist-workers 1-2
}
dpdk {
  ${pci_devs[@]/#/dev 0000:}
  no-multi-seg
  no-tx-checksum-offload
}
plugins {
  plugin default { disable }
  plugin dpdk_plugin.so { enable }
}
EOF

sudo service vpp start
sleep 5

chmod +x ./configure.sh && sudo ./configure.sh ${chain} ${node} ${nodes}
chmod +x ./update_hostname.sh && sudo ./update_hostname.sh ${chain} ${node}
