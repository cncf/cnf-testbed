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
        warn "  Usage: $0 <Chain ID> <Node ID> <Number NFs in chains> <CPU Set>"
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
    # - ${NODE} - Node ID.
    # - ${CHAIN} - Chain ID.
    # - ${NODES} - Number of NFs in chain.
    # Variable set:
    # - ${MAC1} - East MAC.
    # - ${MAC2} - West MAC.

    set -euo pipefail

    if [[ "${NODE}" == "1" ]] && [[ "${NODES}" == "1" ]]; then
        MAC1=52:54:0$(( ${CHAIN} - 1 )):00:00:aa
        MAC2=52:54:0$(( ${CHAIN} - 1 )):00:00:bb
    elif [[ "${NODE}" == "1" ]]; then
        MAC1=52:54:0$(( ${CHAIN} - 1 )):00:00:aa
        MAC2=52:54:0$(( ${CHAIN} - 1 )):00:01:bb
    elif [[ "${NODE}" == "${NODES}" ]]; then
        MAC1=52:54:0$(( ${CHAIN} - 1 )):00:0${NODE}:aa
        MAC2=52:54:0$(( ${CHAIN} - 1 )):00:00:bb
    else
        MAC1=52:54:0$(( ${CHAIN} - 1 )):00:0${NODE}:aa
        MAC2=52:54:0$(( ${CHAIN} - 1 )):00:0${NODE}:bb
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

    MEMID1=$(((${CHAIN} - 1) * ${NODES} * 2 + (${NODE} * 2 - 1)))
    MEMID2=$(((${CHAIN} - 1) * ${NODES} * 2 + (${NODE} * 2)))
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

    trex_macs=( e4:43:4b:2e:b1:d1 e4:43:4b:2e:b1:d2 )

    if [[ "${NODE}" == "1" ]] && [[ "${NODES}" == "1" ]]; then
        REMMAC1=${trex_macs[0]}
        REMMAC2=${trex_macs[1]}
    elif [[ "${NODE}" == "1" ]]; then
        REMMAC1=${trex_macs[0]}
        REMMAC2=52:54:0$(( ${CHAIN} - 1 )):00:02:aa
    elif [[ "${NODE}" == "${NODES}" ]]; then
        REMMAC1=52:54:0$(( ${CHAIN} - 1 )):00:0$(($NODE - 1)):bb
        REMMAC2=${trex_macs[1]}
    else
        REMMAC1=52:54:0$(( ${CHAIN} - 1 )):00:0$(($NODE - 1)):bb
        REMMAC2=52:54:0$(( ${CHAIN} - 1 )):00:0$(($NODE + 1)):aa
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

    SOCK1=memif$(((${CHAIN} - 1) * ${NODES} * 2 + (${NODE} * 2 - 1)))
    SOCK2=memif$(((${CHAIN} - 1) * ${NODES} * 2 + (${NODE} * 2)))
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


function set_startup_vals () {
    # Create core lists and number of queues.
    #
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

ipv6=false

validate_input "${@}" || die
set_startup_vals || die
set_socket_names || die
set_memif_ids || die
set_macs || die
set_subnets || die
set_remote_ips || die
set_remote_macs || die

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

plugins {
  plugin default { disable }
  plugin memif_plugin.so { enable }
}
EOF

if $ipv6; then
bash -c "cat > /etc/vpp/setup.gate" <<EOF
bin memif_socket_filename_add_del add id 1 filename /root/sockets/${SOCK1}.sock
bin memif_socket_filename_add_del add id 2 filename /root/sockets/${SOCK2}.sock
create interface memif id ${MEMID1} socket-id 1 hw-addr ${MAC1} slave rx-queues ${QUEUES} tx-queues ${QUEUES}
create interface memif id ${MEMID2} socket-id 2 hw-addr ${MAC2} slave rx-queues ${QUEUES} tx-queues ${QUEUES}
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
bash -c "cat > /etc/vpp/setup.gate" <<EOF
bin memif_socket_filename_add_del add id 1 filename /root/sockets/${SOCK1}.sock
bin memif_socket_filename_add_del add id 2 filename /root/sockets/${SOCK2}.sock
create interface memif id ${MEMID1} socket-id 1 hw-addr ${MAC1} slave rx-queues ${QUEUES} tx-queues ${QUEUES}
create interface memif id ${MEMID2} socket-id 2 hw-addr ${MAC2} slave rx-queues ${QUEUES} tx-queues ${QUEUES}
set int ip addr memif1/${MEMID1} ${SUBNET1}
set int ip addr memif2/${MEMID2} ${SUBNET2}
set int state memif1/${MEMID1} up
set int state memif2/${MEMID2} up

set ip arp static memif1/${MEMID1} ${REMIP1} ${REMMAC1}
set ip arp static memif2/${MEMID2} ${REMIP2} ${REMMAC2}

ip route add 172.16.64.0/18 via ${REMIP1}
ip route add 172.16.192.0/18 via ${REMIP2}
EOF
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
