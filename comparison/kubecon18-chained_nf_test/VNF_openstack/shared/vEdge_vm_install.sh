#!/bin/bash

set -euo pipefail


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

    CHAIN="${1}"
    NODE="${2}"
    NODES="${3}"
    REMMAC1="${4}"
    REMMAC2="${5}"

    if [[ -n ${CHAIN//[0-9]/} ]] || [[ -n ${NODE//[0-9]/} ]] || [[ -n ${NODES//[0-9]/} ]]; then
        die "ERROR: Chain, node and nodeness must be an integer values!"
    fi

    if [[ "${CHAIN}" -lt "1" ]] || [[ "${CHAIN}" -gt "8" ]]; then
        die "ERROR: Chain must be an integer value between 1-8!"
    fi

    if [[ "${NODE}" -lt "1" ]] || [[ "${NODE}" -gt "8" ]]; then
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
      if $ipv6; then
        SUBNET1=fde5::3:0:10$(( ${CHAIN} - 1 ))/96
        SUBNET2=fde5::4:0:10$(( ${CHAIN} - 1 ))/96
      else
        SUBNET1=172.16.10.1$(( ${CHAIN} - 1 ))/24
        SUBNET2=172.16.20.1$(( ${CHAIN} - 1 ))/24
      fi
    elif [[ "${NODE}" == "1" ]]; then
      if $ipv6; then
        SUBNET1=fde5::3:0:10$(( ${CHAIN} - 1 ))/96
        SUBNET2=fde5::31:0:10/96
      else
        SUBNET1=172.16.10.1$(( ${CHAIN} - 1 ))/24
        SUBNET2=172.16.31.10/24
      fi
    elif [[ "${NODE}" == "${NODES}" ]]; then
      if $ipv6; then
        SUBNET1=fde5::$(($NODE + 29)):0:11/96
        SUBNET2=fde5::4:0:10$(( ${CHAIN} - 1 ))/96
      else
        SUBNET1=172.16.$(($NODE + 29)).11/24
        SUBNET2=172.16.20.1$(( ${CHAIN} - 1 ))/24
      fi
    else
      if $ipv6; then
        SUBNET1=fde5::$(($NODE + 29)):0:11/96
        SUBNET2=fde5::$(($NODE + 30)):0:10/96
      else
        SUBNET1=172.16.$(($NODE + 29)).11/24
        SUBNET2=172.16.$(($NODE + 30)).10/24
      fi
    fi
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
      if $ipv6; then
        REMIP1=fde5::3:0:100$(( ${CHAIN} - 1 ))
        REMIP2=fde5::4:0:100$(( ${CHAIN} - 1 ))
      else
        REMIP1=172.16.10.10$(( ${CHAIN} - 1 ))
        REMIP2=172.16.20.10$(( ${CHAIN} - 1 ))
      fi
    elif [[ "${NODE}" == "1" ]]; then
      if $ipv6; then
        REMIP1=fde5::3:0:100$(( ${CHAIN} - 1 ))
        REMIP2=fde5::31:0:11
      else
        REMIP1=172.16.10.10$(( ${CHAIN} - 1 ))
        REMIP2=172.16.31.11
      fi
    elif [[ "${NODE}" == "${NODES}" ]]; then
      if $ipv6; then
        REMIP1=fde5::$(($NODE + 29)):0:10
        REMIP2=fde5::4:0:100$(( ${CHAIN} - 1 ))
      else
        REMIP1=172.16.$(($NODE + 29)).10
        REMIP2=172.16.20.10$(( ${CHAIN} - 1 ))
      fi
    else
      if $ipv6; then
        REMIP1=fde5::$(($NODE + 29)):0:10
        REMIP2=fde5::$(($NODE + 30)):0:11
      else
        REMIP1=172.16.$(($NODE + 29)).10
        REMIP2=172.16.$(($NODE + 30)).11
      fi
    fi
}

ipv6=false

validate_input "${@}" || die
set_subnets || die
set_remote_ips || die

sudo service vpp stop

pci_search="Ethernet"
pci_devs=($(lspci | grep "$pci_search" | awk '{print $1}' | grep -v "00:05.0"))
dev_list=""
if [ ! "${#pci_devs[@]}" == "0" ]; then
  for dev in ${pci_devs[@]}; do
    dev_list+="dev 0000:$dev "
  done
fi

sudo /opt/dpdk-devbind.py -b uio_pci_generic ${pci_devs[@]}

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
  ${dev_list}
  no-multi-seg
  no-tx-checksum-offload
}
plugins {
  plugin default { disable }
  plugin dpdk_plugin.so { enable }
}

EOF

sudo service vpp start
sleep 10

# Pre-heating the API so that the following works (workaround?)
sudo vppctl show int

intfs=($(sudo vppctl show int | grep Ethernet | awk '{print $1}'))
if [ ! "${#intfs[@]}" == "2" ]; then
  echo "ERROR: Number of interfaces should be 2 (is ${#intfs[@]})"
  exit 1
fi

# Create interface configuration for VPP
if $ipv6; then
sudo bash -c "cat > /etc/vpp/setup.gate" <<EOF
set int state ${intfs[0]} up
set interface ip address ${intfs[0]} ${SUBNET1}

set int state ${intfs[1]} up
set interface ip address ${intfs[1]} ${SUBNET2}

enable ip6 interface ${intfs[0]}
enable ip6 interface ${intfs[1]}

set ip6 neighbor ${intfs[0]} ${REMIP1} ${REMMAC1} static
set ip6 neighbor ${intfs[1]} ${REMIP2} ${REMMAC2} static

ip route add fde5::1:0:0/96 via ${REMIP1}
ip route add fde5::2:0:0/96 via ${REMIP2}
EOF
else
sudo bash -c "cat > /etc/vpp/setup.gate" <<EOF
set int state ${intfs[0]} up
set interface ip address ${intfs[0]} ${SUBNET1}

set int state ${intfs[1]} up
set interface ip address ${intfs[1]} ${SUBNET2}

set ip arp static ${intfs[0]} ${REMIP1} ${REMMAC1}
set ip arp static ${intfs[1]} ${REMIP2} ${REMMAC2}

ip route add 172.16.64.0/18 via ${REMIP1}
ip route add 172.16.192.0/18 via ${REMIP2}
EOF
fi

sudo service vpp restart
