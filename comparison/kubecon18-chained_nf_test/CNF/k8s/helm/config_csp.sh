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
    # - ${MAIN} - Main VPP thread
    # - ${WORKERS} - Worker VPP threads

    set -euo pipefail

    if [[ "${#}" -lt "5" ]]; then
        warn "  Usage: $0 <Chain ID> <Node ID> <Nodes per chain> <Main Thread> <Worker Threads>"
        die "ERROR - At least 5 input arguments required"
    fi

    CHAIN="${1}"
    NODE="${2}"
    NODENESS="${3}"
    MAIN="${4}"
    WORKERS="${5}"

    if [[ -n ${CHAIN//[0-9]/} ]] || [[ -n ${NODE//[0-9]/} ]] || [[ -n ${NODENESS//[0-9]/} ]]; then
        die "ERROR: Chain, node and nodeness must be an integer values!"
    fi

    if [[ "${CHAIN}" -lt "1" ]] || [[ "${CHAIN}" -gt "7" ]]; then
        die "ERROR: Chain must be an integer value between 1-7!"
    fi

    if [[ "${NODENESS}" -lt "1" ]] || [[ "${NODENESS}" -gt "7" ]]; then
        die "ERROR: Nodeness must be an integer value between 1-7!"
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

    trex_mac1=e4:43:4b:2e:b1:d1
    trex_mac2=e4:43:4b:2e:b1:d2

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


BASH_FUNCTION_DIR="$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")" || {
    die "Some error during localizing this source directory!"
}

cd "${BASH_FUNCTION_DIR}" || die

validate_input "${@}" || die
set_socket_names || die
set_memif_ids || die
set_macs || die
set_owners || die
set_subnets || die
set_remote_ips || die
set_remote_macs || die

QUEUES=2
SOCKETMEM="124,0"

## Remove this part and do through Helm
bash -c "cat > ${BASH_FUNCTION_DIR}/vedge/values.yaml" <<EOF
# Default values for vedge.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.

replicaCount: 1

image:
  repository: denverwilliams/cnfs
  tag: vedge_single
  pullPolicy: Always

nameOverride: ""
fullnameOverride: ""

resources:
  limits:
    cpu: "3"
    hugepages-2Mi: 200Mi

volumeMounts:
  vpp_sockets:
    mountPath: /var/run/cnfs/

mainCore: ${MAIN}
corelistWorkers: ${WORKERS}
socketMem: ${SOCKETMEM}

queues: ${QUEUES}

sock1: ${SOCK1}
sock2: ${SOCK2}

memid1: ${MEMID1}
memid2: ${MEMID2}

mac1: ${MAC1}
mac2: ${MAC2}

owner1: ${OWNER1}
owner2: ${OWNER2}

subnet1: ${SUBNET1}
subnet2: ${SUBNET2}

remip1: ${REMIP1}
remip2: ${REMIP2}

remmac1: ${REMMAC1}
remmac2: ${REMMAC2}
EOF
