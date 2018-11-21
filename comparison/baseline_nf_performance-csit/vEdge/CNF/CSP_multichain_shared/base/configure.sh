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
    # - ${NODENESS} - Number of NFs in chain.

    set -euo pipefail

    if [ ! -e "/vEdge/in_container" ]; then
        die "ERROR - Looks like script is being run outside of container!"
    fi

    if [[ "${#}" -lt "3" ]]; then
        warn "  Usage: $0 <Chain ID> <Node ID> <Total Chains> [baseline]"
        die "ERROR - At least 3 input arguments required"
    fi

    CHAIN="${1}"
    NODE="${2}"
    NODENESS="${3}"

    if [[ -n ${CHAIN//[0-9]/} ]] || [[ -n ${NODE//[0-9]/} ]] || [[ -n ${NODENESS//[0-9]/} ]]; then
        die "ERROR: Chain, node and nodeness must be an integer values!"
    fi

    if [[ "${CHAIN}" -lt "1" ]] || [[ "${CHAIN}" -gt "8" ]]; then
        die "ERROR: Chain must be an integer value between 1-8!"
    fi

    if [[ "${NODENESS}" -lt "1" ]] || [[ "${NODENESS}" -gt "8" ]]; then
        die "ERROR: Nodeness must be an integer value between 1-8!"
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
    # - ${NODENESS} - Number of NFs in chain.
    # Variable set:
    # - ${MAC1} - East MAC.
    # - ${MAC2} - West MAC.

    set -euo pipefail

    if [[ "${NODE}" == "1" ]] && [[ "${NODENESS}" == "1" ]]; then
        MAC1=52:54:0$(( ${CHAIN} - 1 )):00:00:aa
        MAC2=52:54:0$(( ${CHAIN} - 1 )):00:00:bb
    elif [[ "${NODE}" == "1" ]]; then
        MAC1=52:54:0$(( ${CHAIN} - 1 )):00:00:aa
        MAC2=52:54:0$(( ${CHAIN} - 1 )):00:01:bb
    elif [[ "${NODE}" == "${NODENESS}" ]]; then
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
    # - ${NODENESS} - Number of NFs in chain.
    # Variable set:
    # - ${MEMID1} - East memifID.
    # - ${MEMID2} - West memifID.

    set -euo pipefail

    if [[ "${NODE}" == "1" ]] && [[ "${NODENESS}" == "1" ]]; then
        MEMID1=$(((${CHAIN} - 1)  * 2 + 1))
        MEMID2=$(((${CHAIN} - 1)  * 2 + 2))
    elif [[ "${NODE}" == "1" ]] && [[ "${NODENESS}" != "1" ]]; then
        MEMID1=$(((${CHAIN} - 1)  * 2 + 1))
        MEMID2=10
    elif [[ "${NODE}" == "${NODENESS}" ]]; then
        MEMID1=$((${NODE} + 8))
        MEMID2=$(((${CHAIN} - 1)  * 2 + 2))
    else
        MEMID1=$((${NODE} + 8))
        MEMID2=$((${NODE} + 9))
    fi
}


function set_owners () {
    # Set memif IDs.
    #
    # Variable read:
    # - ${NODE} - Node ID.
    # - ${NODENESS} - Number of NFs in chain.
    # Variable set:
    # - ${OWNER1} - East memif role.
    # - ${OWNER2} - West memif role.

    set -euo pipefail

    if [[ "${NODE}" == "${NODENESS}" ]]; then
        OWNER1=slave
        OWNER2=slave
    else
        OWNER1=slave
        OWNER2=master
    fi
}


function set_remote_ips () {
    # Set remote IPs.
    #
    # Variable read:
    # - ${NODE} - Node ID.
    # - ${CHAIN} - Chain ID.
    # - ${NODENESS} - Number of NFs in chain.
    # Variable set:
    # - ${REMIP1} - East IP.
    # - ${REMIP2} - West IP.

    set -euo pipefail

    if [[ "${NODE}" == "1" ]] && [[ "${NODENESS}" == "1" ]]; then
        REMIP1=172.16.10.10$(( ${CHAIN} - 1 ))
        REMIP2=172.16.20.10$(( ${CHAIN} - 1 ))
    elif [[ "${NODE}" == "1" ]]; then
        REMIP1=172.16.10.10$(( ${CHAIN} - 1 ))
        REMIP2=172.16.31.11
    elif [[ "${NODE}" == "${NODENESS}" ]]; then
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
    # - ${NODE} - Node ID.
    # - ${CHAIN} - Chain ID.
    # - ${NODENESS} - Number of NFs in chain.
    # Variable set:
    # - ${REMMAC1} - East MAC.
    # - ${REMMAC2} - West MAC.

    set -euo pipefail

    trex_mac1=3c:fd:fe:bd:f8:60
    trex_mac2=3c:fd:fe:bd:f8:61

    if [[ "${NODE}" == "1" ]] && [[ "${NODENESS}" == "1" ]]; then
        REMMAC1=${trex_mac1}
        REMMAC2=${trex_mac2}
    elif [[ "${NODE}" == "1" ]]; then
        REMMAC1=${trex_mac1}
        REMMAC2=52:54:0$(( ${CHAIN} - 1 )):00:02:aa
    elif [[ "${NODE}" == "${NODENESS}" ]]; then
        REMMAC1=52:54:0$(( ${CHAIN} - 1 )):00:0$(($NODE - 1)):bb
        REMMAC2=${trex_mac2}
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
    # - ${NODENESS} - Number of NFs in chain.
    # Variable set:
    # - ${SOCK1} - East socket.
    # - ${SOCK2} - West socket.

    set -euo pipefail

    if [[ "${NODE}" == "1" ]] && [[ "${NODENESS}" == "1" ]]; then
        SOCK1=memif$(((${CHAIN} - 1)  * 2 + 1))
        SOCK2=memif$(((${CHAIN} - 1)  * 2 + 2))
    elif [[ "${NODE}" == "1" ]] && [[ "${NODENESS}" != "1" ]]; then
        SOCK1=memif$(((${CHAIN} - 1)  * 2 + 1))
        SOCK2=int${CHAIN}1
    elif [[ "${NODE}" == "${NODENESS}" ]]; then
        SOCK1=int${CHAIN}$((${NODE} - 1))
        SOCK2=memif$(((${CHAIN} - 1)  * 2 + 2))
    else
        SOCK1=int${CHAIN}$((${NODE} - 1))
        SOCK2=int${CHAIN}${NODE}
    fi
}


function set_subnets () {
    # Set subnets.
    #
    # Variable read:
    # - ${NODE} - Node ID.
    # - ${CHAIN} - Chain ID.
    # - ${NODENESS} - Number of NFs in chain.
    # Variable set:
    # - ${SUBNET1} - East subnet.
    # - ${SUBNET2} - West subnet.

    set -euo pipefail

    if [[ "${NODE}" == "1" ]] && [[ "${NODENESS}" == "1" ]]; then
        SUBNET1=172.16.10.1$(( ${CHAIN} - 1 ))/24
        SUBNET2=172.16.20.1$(( ${CHAIN} - 1 ))/24
    elif [[ "${NODE}" == "1" ]]; then
        SUBNET1=172.16.10.1$(( ${CHAIN} - 1 ))/24
        SUBNET2=172.16.31.10/24
    elif [[ "${NODE}" == "${NODENESS}" ]]; then
        SUBNET1=172.16.$(($NODE + 29)).11/24
        SUBNET2=172.16.20.1$(( ${CHAIN} - 1 ))/24
    else
        SUBNET1=172.16.$(($NODE + 29)).11/24
        SUBNET2=172.16.$(($NODE + 30)).10/24
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
    # The same list is required in the 'run_container.sh' script
    main_cores=( 0 5 61 8 64 11 67 14 70 )
    # The same list is required in the 'run_container.sh' script
    worker_cores=( 0 6,62 7,63 9,65 10,66 12,68 13,69 15,71 16,72 )

    MAIN_CORE=${main_cores[${NODE}]}
    WORKERS=${worker_cores[${NODE}]}
}


validate_input "${@}" || die
set_startup_vals || die
set_socket_names || die
set_memif_ids || die
set_macs || die
set_owners || die
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

dpdk {
  no-pci
    # dev default {
        # num-rx-queues 2
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

bash -c "cat > /etc/vpp/setup.gate" <<EOF
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

/usr/bin/vpp -c /etc/vpp/startup.conf
