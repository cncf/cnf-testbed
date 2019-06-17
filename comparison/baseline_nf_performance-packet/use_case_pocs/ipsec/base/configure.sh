#!/usr/bin/env bash

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
    # - ${CPUSET} - CPU Set.

    set -euo pipefail

    if [ ! -e "/vEdge/in_container" ]; then
        die "ERROR - Looks like script is being run outside of container!"
    fi

    if [[ "${#}" -lt "4" ]]; then
        warn "  Usage: $0 <Chain ID> <Node ID> <Number NFs in chain> <CPU Set>"
        die "ERROR - At least 4 input arguments required"
    fi

    CHAIN="${1}"
    NODE="${2}"
    NODES="${3}"
    CPUSET="${4}"

    if [[ -n ${CHAIN//[0-9]/} ]] || [[ -n ${NODE//[0-9]/} ]] || [[ -n ${NODES//[0-9]/} ]]; then
        die "ERROR: Chain, node and nodes must be an integer values!"
    fi

    if [[ "${CHAIN}" -lt "1" ]] || [[ "${CHAIN}" -gt "8" ]]; then
        die "ERROR: Chain must be an integer value between 1-8!"
    fi

    if [[ "${NODES}" -lt "1" ]] || [[ "${NODES}" -gt "8" ]]; then
        die "ERROR: Nodes must be an integer value between 1-8!"
    fi
}


function warn () {
    # Print the message to standard error.
    #
    # Arguments:
    # - ${@} - The text of the message.

    echo "$@" >&2
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

    if [[ "${NODE}" == "1" ]] && [[ "${CHAIN}" == "1" ]]; then
      # 1/4 (regular start)
      MAC1=52:54:00:00:00:aa
      MAC2=52:54:00:00:01:bb
    elif [[ "${CHAIN}" == "1" ]]; then
      # 2/4 (IPsec Right)
      MAC1=52:54:00:00:02:aa
      MAC2=52:54:00:00:02:bb
    elif [[ "${NODE}" == "1" ]]; then
      # 3/4 (IPsec Left)
      MAC1=52:54:00:00:03:aa
      MAC2=52:54:00:00:03:bb
    else
      # 4/4 (regular end)
      MAC1=52:54:00:00:04:aa
      MAC2=52:54:00:00:00:bb
    fi
}


function set_memif_ids () {
    # Set memif IDs.
    #
    # Variable read:
    # - ${NODE} - Node ID.
    # - ${CHAIN} - Chain ID.
    # - ${NODES} - Number of NFs in chain.
    # Variable set:
    # - ${MEMID1} - East memifID.
    # - ${MEMID2} - West memifID.

    set -euo pipefail

    if [[ "${NODE}" == "1" ]] && [[ "${CHAIN}" == "1" ]]; then
      # 1/4 (regular start)
      MEMID1=1
      MEMID2=10
    elif [[ "${CHAIN}" == "1" ]]; then
      # 2/4 (IPsec Right)
      MEMID1=10
      MEMID2=2
    elif [[ "${NODE}" == "1" ]]; then
      # 3/4 (IPsec Left)
      MEMID1=3
      MEMID2=11
    else
      # 4/4 (regular end)
      MEMID1=11
      MEMID2=4
    fi
}


function set_owners () {
    # Set memif IDs.
    #
    # Variable read:
    # - ${NODE} - Node ID.
    # - ${NODES} - Number of NFs in chain.
    # Variable set:
    # - ${OWNER1} - East memif role.
    # - ${OWNER2} - West memif role.

    set -euo pipefail

    if [[ "${NODE}" == "1" ]]; then
      # 1/4 (regular start), 3/4 (IPsec Left)
      OWNER1=slave
      OWNER2=master
    else
      # 2/4 (IPsec Right), 4/4 (regular end)
      OWNER1=slave
      OWNER2=slave
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

    if [[ "${NODE}" == "1" ]] && [[ "${CHAIN}" == "1" ]]; then
      # 1/4 (regular start)
      REMIP1=172.16.10.100
      REMIP2=172.16.31.11
    elif [[ "${CHAIN}" == "1" ]]; then
      # 2/4 (IPsec Right)
      REMIP1=172.16.31.10
      REMIP2=172.16.32.11
    elif [[ "${NODE}" == "1" ]]; then
      # 3/4 (IPsec Left)
      REMIP1=172.16.32.10
      REMIP2=172.16.33.11
    else
      # 4/4 (regular end)
      REMIP1=172.16.33.10
      REMIP2=172.16.20.100
    fi
}

function set_remote_macs () {
    # Set ARP MACs.
    #
    # Variable read:
    # - ${NODE} - Node ID.
    # - ${CHAIN} - Chain ID.
    # - ${NODES} - Number of NFs in chain.
    # Variable set:
    # - ${REMMAC1} - East MAC.
    # - ${REMMAC2} - West MAC.

    set -euo pipefail

    trex_macs=( e4:43:4b:2e:9f:e2 e4:43:4b:2e:9f:e3 )

    if [[ "${NODE}" == "1" ]] && [[ "${CHAIN}" == "1" ]]; then
      # 1/4 (regular start)
      REMMAC1=${trex_macs[0]}
      REMMAC2=52:54:00:00:02:aa
    elif [[ "${CHAIN}" == "1" ]]; then
      # 2/4 (IPsec Right)
      REMMAC1=52:54:00:00:01:bb
      REMMAC2=52:54:00:00:03:aa
    elif [[ "${NODE}" == "1" ]]; then
      # 3/4 (IPsec Left)
      REMMAC1=52:54:00:00:02:bb
      REMMAC2=52:54:00:00:04:aa
    else
      # 4/4 (regular end)
      REMMAC1=52:54:00:00:03:bb
      REMMAC2=${trex_macs[1]}
    fi
}


function set_socket_names () {
    # Set socket names.
    #
    # Variable read:
    # - ${NODE} - Node ID.
    # - ${CHAIN} - Chain ID.
    # - ${NODES} - Number of NFs in chain.
    # Variable set:
    # - ${SOCK1} - East socket.
    # - ${SOCK2} - West socket.

    set -euo pipefail

    if [[ "${NODE}" == "1" ]] && [[ "${CHAIN}" == "1" ]]; then
      # 1/4 (regular start)
      SOCK1=memif1
      SOCK2=int11
    elif [[ "${CHAIN}" == "1" ]]; then
      # 2/4 (IPsec Right)
      SOCK1=int11
      SOCK2=memif2
    elif [[ "${NODE}" == "1" ]]; then
      # 3/4 (IPsec Left)
      SOCK1=memif3
      SOCK2=int21
    else
      # 4/4 (regular end)
      SOCK1=int21
      SOCK2=memif4
    fi
}


function set_subnets () {
    # Set subnets.
    #
    # Variable read:
    # - ${NODE} - Node ID.
    # - ${CHAIN} - Chain ID.
    # - ${NODES} - Number of NFs in chain.
    # Variable set:
    # - ${SUBNET1} - East subnet.
    # - ${SUBNET2} - West subnet.

    set -euo pipefail

    if [[ "${NODE}" == "1" ]] && [[ "${CHAIN}" == "1" ]]; then
      # 1/4 (regular start)
      SUBNET1=172.16.10.10/24
      SUBNET2=172.16.31.10/24
    elif [[ "${CHAIN}" == "1" ]]; then
      # 2/4 (IPsec Right)
      SUBNET1=172.16.31.11/24
      SUBNET2=172.16.32.10/24
    elif [[ "${NODE}" == "1" ]]; then
      # 3/4 (IPsec Left)
      SUBNET1=172.16.32.11/24
      SUBNET2=172.16.33.10/24
    else
      # 4/4 (regular end)
      SUBNET1=172.16.33.11/24   
      SUBNET2=172.16.20.10/24
    fi
}


function set_startup_vals () {
    # Create core lists and number of queues.
    #
    # Variable read:
    # - ${NODE} - Node ID.
    # - ${OPERATION} - Operation bit [baseline].
    # Variable set:
    # - ${QUEUES} - Number of memif queues.
    # - ${MAIN_CORE} - Main core list.
    # - ${WORKERS} - Workers core list.

    set -euo pipefail

    QUEUES=1
    IFS=', ' read -r -a array <<< "${CPUSET}"
    MAIN_CORE="${array[0]}"
    WORKERS="${array[1]},${array[2]}"
}

function set_keys () {

    # TODO: Make this less static
    set -euo pipefail

    if [[ "${CHAIN}" == "1" ]]; then
      KEY1="714c7a456b41476442585353474b586c78796d45"
      KEY2="47505069546a6461647565786163726865757346"
    else
      KEY1="47505069546a6461647565786163726865757346"
      KEY2="714c7a456b41476442585353474b586c78796d45"
    fi
}

ipv6=false

validate_input "${@}" || die
set_startup_vals || die
set_socket_names || die
set_memif_ids || die
set_macs || die
set_owners || die
set_subnets || die
set_remote_ips || die
set_remote_macs || die
set_keys || die

bash -c "cat > /etc/vpp/startup.conf" <<EOF
unix {
  nodaemon
  log /var/log/vpp/vpp.log
  full-coredump
  cli-listen /run/vpp/cli.sock
  gid vpp
  startup-config /etc/vpp/setup.gate
  cli-prompt CNF#${NODE}:
}

api-trace {
  on
}

api-segment {
  gid vpp
}

cpu {
  main-core ${MAIN_CORE}
  corelist-workers ${WORKERS}
}

dpdk {
  no-pci
  no-multi-seg
  no-tx-checksum-offload
}

plugins {
  plugin default { disable }
  plugin memif_plugin.so { enable }
  plugin dpdk_plugin.so { enable }
  plugin crypto_ia32_plugin.so { enable }
  plugin crypto_ipsecmb_plugin.so { enable }
  plugin crypto_openssl_plugin.so { enable }
}
EOF

output_file="/etc/vpp/setup.gate"

if $ipv6; then
bash -c "cat > ${output_file}" <<EOF
bin memif_socket_filename_add_del add id 1 filename /root/sockets/${SOCK1}.sock
bin memif_socket_filename_add_del add id 2 filename /root/sockets/${SOCK2}.sock
create interface memif id ${MEMID1} socket-id 1 hw-addr ${MAC1} ${OWNER1} rx-queues ${QUEUES} tx-queues ${QUEUES}
create interface memif id ${MEMID2} socket-id 2 hw-addr ${MAC2} ${OWNER2} rx-queues ${QUEUES} tx-queues ${QUEUES}
set int ip addr memif1/${MEMID1} ${SUBNET1}
set int ip addr memif2/${MEMID2} ${SUBNET2}
enable ip6 interface memif1/${MEMID1}
enable ip6 interface memif2/${MEMID2}

set ip6 neighbor memif1/${MEMID1} ${REMIP1} ${REMMAC1} static
set ip6 neighbor memif2/${MEMID2} ${REMIP2} ${REMMAC2} static

ip route add fde5::1:0:0/96 via ${REMIP1}
ip route add fde5::2:0:0/96 via ${REMIP2}

set int state memif1/${MEMID1} up
set int state memif2/${MEMID2} up
EOF
else
if [[ "${CHAIN}" == "${NODE}" ]]; then
bash -c "cat > ${output_file}" <<EOF
bin memif_socket_filename_add_del add id 1 filename /root/sockets/${SOCK1}.sock
bin memif_socket_filename_add_del add id 2 filename /root/sockets/${SOCK2}.sock
create interface memif id ${MEMID1} socket-id 1 hw-addr ${MAC1} ${OWNER1} rx-queues ${QUEUES} tx-queues ${QUEUES}
create interface memif id ${MEMID2} socket-id 2 hw-addr ${MAC2} ${OWNER2} rx-queues ${QUEUES} tx-queues ${QUEUES}
set int ip addr memif1/${MEMID1} ${SUBNET1}
set int ip addr memif2/${MEMID2} ${SUBNET2}
set int state memif1/${MEMID1} up
set int state memif2/${MEMID2} up

set ip arp static memif1/${MEMID1} ${REMIP1} ${REMMAC1}
set ip arp static memif2/${MEMID2} ${REMIP2} ${REMMAC2}

ip route add 172.16.64.0/18 via ${REMIP1}
ip route add 172.16.192.0/18 via ${REMIP2}
EOF
elif [[ "${NODE}" == "1" ]]; then
## IPsec to the left (chain 2)
bash -c "cat > ${output_file}" <<EOF
create memif socket id 1 filename /root/sockets/${SOCK1}.sock
create interface memif id ${MEMID1} socket-id 1 hw-addr ${MAC1} ${OWNER1} rx-queues ${QUEUES} tx-queues ${QUEUES}
set interface ip address memif1/${MEMID1} ${SUBNET1}
set interface state memif1/${MEMID1} up
create memif socket id 2 filename /root/sockets/${SOCK2}.sock
create interface memif id ${MEMID2} socket-id 2 hw-addr ${MAC2} ${OWNER2} rx-queues ${QUEUES} tx-queues ${QUEUES}
set interface ip address memif2/${MEMID2} ${SUBNET2}
set interface state memif2/${MEMID2} up

set ip arp static memif1/${MEMID1} ${REMIP1} ${REMMAC1}
set ip arp static memif2/${MEMID2} ${REMIP2} ${REMMAC2}

ip route add 172.16.192.0/18 via ${REMIP2}

create ipsec tunnel local-ip $(echo "${SUBNET1}" | cut -f1 -d"/") remote-ip ${REMIP1} local-spi 100000 remote-spi 200000 local-crypto-key ${KEY1} remote-crypto-key ${KEY2} crypto-alg aes-gcm-128

set interface unnumbered ipsec0 use memif1/${MEMID1}
set interface state ipsec0 up
ip route add  172.16.64.0/18 via ${REMIP1} ipsec0
EOF
else
## IPsec to the right (chain 1)
bash -c "cat > ${output_file}" <<EOF
create memif socket id 1 filename /root/sockets/${SOCK1}.sock
create interface memif id ${MEMID1} socket-id 1 hw-addr ${MAC1} ${OWNER1} rx-queues ${QUEUES} tx-queues ${QUEUES}
set interface ip address memif1/${MEMID1} ${SUBNET1}
set interface state memif1/${MEMID1} up

create memif socket id 2 filename /root/sockets/${SOCK2}.sock
create interface memif id ${MEMID2} socket-id 2 hw-addr ${MAC2} ${OWNER2} rx-queues ${QUEUES} tx-queues ${QUEUES}
set interface ip address memif2/${MEMID2} ${SUBNET2}
set interface state memif2/${MEMID2} up

set ip arp static memif1/${MEMID1} ${REMIP1} ${REMMAC1}
set ip arp static memif2/${MEMID2} ${REMIP2} ${REMMAC2}

ip route add 172.16.64.0/18 via ${REMIP1}

create ipsec tunnel local-ip $(echo "${SUBNET2}" | cut -f1 -d"/") remote-ip ${REMIP2} local-spi 200000 remote-spi 100000 local-crypto-key ${KEY1} remote-crypto-key ${KEY2} crypto-alg aes-gcm-128

set interface unnumbered ipsec0 use memif2/${MEMID2}
set interface state ipsec0 up
ip route add 172.16.192.0/18 via ${REMIP2} ipsec0 
EOF
fi
fi

if $ipv6; then
  /usr/bin/vpp -c /etc/vpp/startup.conf &

  sleep 5

  vppctl set int state memif1/${MEMID1} up
  vppctl set int state memif2/${MEMID2} up

  while true; do
      sleep 60
  done
else
  /usr/bin/vpp -c /etc/vpp/startup.conf
fi
