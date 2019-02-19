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

    if [[ "${CHAIN}" -lt "1" ]] || [[ "${CHAIN}" -gt "10" ]]; then
        die "ERROR: Chain must be an integer value between 1-10!"
    fi

    if [[ "${NODE}" -lt "1" ]] || [[ "${NODE}" -gt "10" ]]; then
        die "ERROR: Node must be an integer value between 1-10!"
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

validate_input "${@}" || die
set_subnets || die
set_remote_ips || die
set_remote_macs || die

## Pre-heating API (workaround)
sudo vppctl show int || true
intfs=($(sudo vppctl show int | grep Ethernet | awk '{print $1}'))
if [ ! "${#intfs[@]}" == "2" ]; then
  die "ERROR: Number of interfaces should be 2 (is ${#intfs[@]})!"
fi

# Create interface configuration for VPP
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

sudo service vpp restart || die "Failed to restart VPP!"

