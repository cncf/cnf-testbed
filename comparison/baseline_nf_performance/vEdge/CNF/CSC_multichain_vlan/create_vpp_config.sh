#!/usr/bin/env bash

set -exuo pipefail


function append_vpp_config () {
    # Append line to VPP configuration file.
    #
    # Arguments:
    # - ${1} - The text to append.
    # Variable read:
    # - ${VPP_CONF_FILE} - VPP configuration file.

    set -exuo pipefail

    echo "${1-}" | sudo tee -a "${VPP_CONF_FILE}"
}


function clean_vpp_config () {
    # Cleanup VPP configuration.
    #
    # Variable set:
    # - ${VPP_CONF_FILE} - VPP configuration file.

    set -exuo pipefail

    VPP_CONF_FILE="vEdge_csc_vpp.conf"
    if [ -f "${VPP_CONF_FILE}" ]; then
        rm "${VPP_CONF_FILE}" || die
        touch "${VPP_CONF_FILE}" || die
    fi
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

function generate_vpp_config () {
    # Generate VPP multichain configs.
    #
    # Variable set:
    # - ${CHAINS} - Number of parallel chains.
    # - ${NODENESS} - Number of NFs in chain.
    # - ${VLANS} - Base VLANs.

    set -exuo pipefail

    domains=$(( "${CHAINS}" * ("${NODENESS}" + 1 ) ))
    for domain in $(seq 1 ${domains}); do
        append_vpp_config "create bridge-domain ${domain}"
    done
    append_vpp_config ""
    sockets=$(( "${CHAINS}" * ("${NODENESS}" * 2) ))
    for socket in $(seq 1 "${sockets}"); do
        append_vpp_config "bin memif_socket_filename_add_del add id ${socket} filename /etc/vpp/sockets/memif${socket}.sock"
        append_vpp_config "create interface memif id ${socket} socket-id ${socket} master"
    done
    append_vpp_config ""
    append_vpp_config "set int state TwentyFiveGigabitEthernet3b/0/0 up"
    append_vpp_config "set int state TwentyFiveGigabitEthernet3b/0/1 up"
    append_vpp_config ""
    for chain in $(seq 0 $(( "${CHAINS}" -1 ))); do
        vlan_e=$(("${VLANS[0]}" + "${chain}"))
        vlan_w=$(("${VLANS[1]}" + "${chain}"))
        offset=$(("${chain}" * ("${NODENESS}" + 1 )))

        append_vpp_config "create sub TwentyFiveGigabitEthernet3b/0/0 ${vlan_e}"
        append_vpp_config "create sub TwentyFiveGigabitEthernet3b/0/1 ${vlan_w}"
        append_vpp_config ""
        append_vpp_config "set int l2 bridge TwentyFiveGigabitEthernet3b/0/0.${vlan_e} $(( ${offset} + 1 )) "
        mEth=$(( "${chain}" * ("${NODENESS}" * 2) + 1 ))
        append_vpp_config "set int l2 bridge memif${mEth}/${mEth} $(( ${offset} + 1 ))"
        ((++mEth))
        for bridge in $(seq 2 $(( ("${domains}"/"${CHAINS}") - 1 ))); do
            append_vpp_config "set int l2 bridge memif${mEth}/${mEth} $(( ${offset} + ${bridge} ))"
            ((++mEth))
            append_vpp_config "set int l2 bridge memif${mEth}/${mEth} $(( ${offset} + ${bridge} ))"
            ((++mEth))
        done
        append_vpp_config "set int l2 bridge memif${mEth}/${mEth} $((${offset} + (${NODENESS} + 1 )))"
        append_vpp_config "set int l2 bridge TwentyFiveGigabitEthernet3b/0/1.${vlan_w} $((${offset} + (${NODENESS} + 1 )))"
        append_vpp_config ""
        append_vpp_config "set int state TwentyFiveGigabitEthernet3b/0/0.${vlan_e} up"
        append_vpp_config "set interface l2 tag-rewrite TwentyFiveGigabitEthernet3b/0/0.${vlan_e} pop 1"
        append_vpp_config "set int state TwentyFiveGigabitEthernet3b/0/1.${vlan_w} up"
        append_vpp_config "set interface l2 tag-rewrite TwentyFiveGigabitEthernet3b/0/1.${vlan_w} pop 1"
    done
    append_vpp_config ""
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
    # - ${NODENESS} - Number of NFs in chain.
    # - ${OPERATION} - Operation bit [cleanup|baseline].

    set -exuo pipefail

    if [[ "${#}" -lt "3" ]]; then
        warn "Usage: ${0} <Chains> <Nodeness> <VLAN#1> <VLAN#2>"
        die "ERROR - At least three input arguments required"
    fi

    for param in "${@}"; do
        if [[ -n ${param//[0-9]/} ]]; then
            die "ERROR: Inputs must be an integer values!"
        fi
    done

    CHAINS="${1}"
    NODENESS="${2}"
    VLANS=( "${3-}" "${4-}" )

    if [[ "${CHAINS}" -lt "1" ]] || [[ "${CHAINS}" -gt "8" ]]; then
        die "ERROR - DEBUG: Only supports up to 1-8 chains!"
    fi

    if [[ "${NODENESS}" -lt "1" ]] || [[ "${NODENESS}" -gt "8" ]]; then
        die "ERROR - DEBUG: Only supports up to 1-8 nodes per chain!"
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
generate_vpp_config || die
