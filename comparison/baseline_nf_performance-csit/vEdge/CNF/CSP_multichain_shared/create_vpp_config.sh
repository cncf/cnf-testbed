#!/usr/bin/env bash

set -euo pipefail


function append_vpp_config () {
    # Append line to VPP configuration file.
    #
    # Arguments:
    # - ${1} - The text to append.
    # Variable read:
    # - ${VPP_CONF_FILE} - VPP configuration file.

    set -euo pipefail

    echo "${1-}" | sudo tee -a "${VPP_CONF_FILE}"
}


function clean_vpp_config () {
    # Cleanup VPP configuration.
    #
    # Variable set:
    # - ${VPP_CONF_FILE} - VPP configuration file.

    set -euo pipefail

    VPP_CONF_FILE="vEdge_csp_vpp.conf"
    if [ -f "${VPP_CONF_FILE}" ]; then
        rm "${VPP_CONF_FILE}" || die
        touch "${VPP_CONF_FILE}" || die
    fi
}


function detect_mellanox () {
    # Check presence of Mellanox card.
    #
    # Arguments:
    # - ${1} - Utility to check.
    # Returns:
    # - 0 - If Mellanox NIC is there.
    # - 1 - If Mellanox NIC is not there.

    set -euo pipefail

    lspci | grep Mellanox
}


function detect_xxv710 () {
    # Check presence of XXV710 card.
    #
    # Arguments:
    # - ${1} - Utility to check.
    # Returns:
    # - 0 - If XXV710 NIC is there.
    # - 1 - If XXV710 NIC is not there.

    set -euo pipefail

    lspci | grep XXV710
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

function generate_vpp_config_intel () {
    # Generate VPP multichain configs for Quad Intel.
    #
    # Variable set:
    # - ${CHAINS} - Number of parallel chains.
    # - ${NODES} - Number of NFs in chain.
    # - ${VLANS} - Base VLANs.
    # - ${VPP_INTERFACES} - Network interfaces in VPP.

    set -euo pipefail

    append_vpp_config "create bridge-domain 1"
    append_vpp_config "create bridge-domain 2"
    append_vpp_config ""
    sockets=$(( "${CHAINS}" *  2 ))
    for socket in $(seq 1 "${sockets}"); do
        append_vpp_config "bin memif_socket_filename_add_del add id ${socket} filename /etc/vpp/sockets/memif${socket}.sock"
        append_vpp_config "create interface memif id ${socket} socket-id ${socket} master"
    done
    append_vpp_config ""
    append_vpp_config "set int state ${VPP_INTERFACES[0]} up"
    append_vpp_config "set int state ${VPP_INTERFACES[1]} up"
    append_vpp_config ""
    if [ ${#VLANS[@]} -ne 0 ]; then
        append_vpp_config "create sub ${VPP_INTERFACES[0]} ${VLANS[0]}"
        append_vpp_config "create sub ${VPP_INTERFACES[1]} ${VLANS[1]}"
        append_vpp_config "set int state ${VPP_INTERFACES[0]}${VLANS[0]/#/.} up"
        append_vpp_config "set int state ${VPP_INTERFACES[1]}${VLANS[1]/#/.} up"
        append_vpp_config "set interface l2 tag-rewrite ${VPP_INTERFACES[0]}${VLANS[0]/#/.} pop 1"
        append_vpp_config "set interface l2 tag-rewrite ${VPP_INTERFACES[1]}${VLANS[1]/#/.} pop 1"
    fi
    append_vpp_config ""
    set +u
    append_vpp_config "set int l2 bridge ${VPP_INTERFACES[0]}${VLANS[0]/#/.} 1"
    for chain in $(seq 0 $(( "${CHAINS}" -1 ))); do
        mEth=$(( "${chain}" * 2 + 1 ))
        append_vpp_config "set int l2 bridge memif${mEth}/${mEth} 1"
        ((++mEth))
        append_vpp_config "set int l2 bridge memif${mEth}/${mEth} 2"
    done
    set +u
    append_vpp_config "set int l2 bridge ${VPP_INTERFACES[1]}${VLANS[1]/#/.} 2"
    append_vpp_config ""
    append_vpp_config "set int mtu 9200 ${VPP_INTERFACES[0]}"
    append_vpp_config "set int mtu 9200 ${VPP_INTERFACES[1]}"
    for meth in $(seq 1 "${sockets}"); do
        append_vpp_config "set int state memif${meth}/${meth} up"
    done
}


function generate_vpp_config_mlx () {
    # Generate VPP multichain configs for MLX.
    #
    # Variable set:
    # - ${CHAINS} - Number of parallel chains.
    # - ${NODES} - Number of NFs in chain.
    # - ${VLANS} - Base VLANs.
    # - ${VPP_INTERFACES} - Network interfaces in VPP.

    set -euo pipefail

    append_vpp_config "create bridge-domain 1"
    append_vpp_config "create bridge-domain 2"
    append_vpp_config ""
    sockets=$(( "${CHAINS}" *  2 ))
    for socket in $(seq 1 "${sockets}"); do
        append_vpp_config "bin memif_socket_filename_add_del add id ${socket} filename /etc/vpp/sockets/memif${socket}.sock"
        append_vpp_config "create interface memif id ${socket} socket-id ${socket} master"
    done
    append_vpp_config ""
    append_vpp_config "set int state ${VPP_INTERFACES[0]} up"
    append_vpp_config "create sub ${VPP_INTERFACES[0]} ${VLANS[0]}"
    append_vpp_config "create sub ${VPP_INTERFACES[0]} ${VLANS[1]}"
    append_vpp_config "set int state ${VPP_INTERFACES[0]}${VLANS[0]/#/.} up"
    append_vpp_config "set int state ${VPP_INTERFACES[0]}${VLANS[1]/#/.} up"
    append_vpp_config "set interface l2 tag-rewrite ${VPP_INTERFACES[0]}${VLANS[0]/#/.} pop 1"
    append_vpp_config "set interface l2 tag-rewrite ${VPP_INTERFACES[0]}${VLANS[1]/#/.} pop 1"
    append_vpp_config ""
    set +u
    append_vpp_config "set int l2 bridge ${VPP_INTERFACES[0]}${VLANS[0]/#/.} 1"
    for chain in $(seq 0 $(( "${CHAINS}" -1 ))); do
        mEth=$(( "${chain}" * 2 + 1 ))
        append_vpp_config "set int l2 bridge memif${mEth}/${mEth} 1"
        ((++mEth))
        append_vpp_config "set int l2 bridge memif${mEth}/${mEth} 2"
    done
    set +u
    append_vpp_config "set int l2 bridge ${VPP_INTERFACES[0]}${VLANS[1]/#/.} 2"
    append_vpp_config ""
    append_vpp_config "set int mtu 9200 ${VPP_INTERFACES[0]}"
    for meth in $(seq 1 "${sockets}"); do
        append_vpp_config "set int state memif${meth}/${meth} up"
    done
}


function validate_input() {
    # Validate script input.
    #
    # Arguments:
    # - ${@} - The text of the message.
    # Variable set:
    # - ${CHAINS} - Number of parallel chains.
    # - ${NODES} - Number of NFs in chain.
    # - ${OPERATION} - Operation bit [cleanup|baseline].

    set -euo pipefail

    if detect_mellanox && [[ "${#}" -lt "4" ]]; then
        warn "Usage: ${0} <Chains> <Node> <VLAN#1> <VLAN#2>"
        die "ERROR - At least four input arguments required"
    fi

    if ! detect_mellanox && [[ "${#}" -lt "2" ]]; then
        warn "Usage: ${0} <Chains> <Node> [<VLAN#1> <VLAN#2>]"
        die "ERROR - At least two input arguments required"
    fi

    for param in "${@}"; do
        if [[ -n ${param//[0-9]/} ]]; then
            die "ERROR: Inputs must be an integer values!"
        fi
    done

    CHAINS="${1}"
    NODES="${2}"
    VLANS=( ${3-} ${4-} )

    if [[ "${CHAINS}" -lt "1" ]] || [[ "${CHAINS}" -gt "10" ]]; then
        die "ERROR - DEBUG: Only supports up to 1-10 chains!"
    fi

    if [[ "${NODES}" -lt "1" ]] || [[ "${NODES}" -gt "10" ]]; then
        die "ERROR - DEBUG: Only supports up to 1-10 nodes per chain!"
    fi
}


function warn () {
    # Print the message to standard error.
    #
    # Arguments:
    # - ${@} - The text of the message.

    echo "$@" >&2
}

validate_input "${@}" || die
clean_vpp_config || die
if detect_mellanox; then
    # This is most probably Packet mlx env
    VPP_INTERFACES=( "TwentyFiveGigabitEthernet5e/0/1" )
    generate_vpp_config_mlx || die
else
    if detect_xxv710; then
        # This is most probably CSIT env
        VPP_INTERFACES=( "TwentyFiveGigabitEthernet3b/0/0"
                         "TwentyFiveGigabitEthernet3b/0/1" )
    else
        # This is most probably Packet quad intel env
        VPP_INTERFACES=( "TenGigabitEthernet1a/0/1"
                         "TenGigabitEthernet1a/0/2" )
    fi
    generate_vpp_config_intel || die
fi
