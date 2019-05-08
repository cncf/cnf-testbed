#!/usr/bin/env bash

set -euo pipefail


function clean_tmp_files () {
    # Cleanup temporary files.

    set -euo pipefail

    config_files=(
                  /etc/thinvm_vpp_startup_*.conf
                  /etc/thinvm_vpp_setup_*.conf
                  /etc/thinvm_init_*.conf
                  /var/run/qemu_*.pid
                  /var/run/vpp/sock*
                  /tmp/serial_*.log
                 )
    sudo rm -f "${config_files[@]}"
}


function clean_vms () {
    # Destroy VagrantVM, not image.
    #
    # Variable reads:
    # - ${CHAINS} - Number of parallel chains.
    # - ${NODES} - Number of NFs in chain.

    set -euo pipefail

    sudo pkill qemu
    clean_tmp_files || die
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


function restart_vpp () {
    # Restarts VPP service.

    set -euo pipefail

    warn "Restarting of VPP ....."
    sudo service vpp restart || die "Service restart failed!"
    for i in $(seq 1 5); do
        sleep 5
        if [ -z "$(vppctl show ver | grep 'vpp v')" ]; then
            warn "VPP not running yet"
            if [ "${i}" == "5" ]; then
                die "ERROR, VPP still not running"
            fi
        else
            warn "VPP running"
            break
        fi
    done
}


function update_cpu_pinning () {
    # Update CPU pinning for each VM via virsh.
    #
    # Arguments:
    # - ${1} - Chain ID.
    # - ${2} - Node ID.

    set -euo pipefail

    # Create CORE lists.
    if [ "${CHAINS}" -eq 1 ] && [ "${NODES}" -eq 1 ]; then
        mtcr=1
    else
        mtcr=2
    fi
    dtcr=1
    COMMON_DIR="$(readlink -e "$(git rev-parse --show-toplevel)")" || {
        die "Readlink or git rev-parse failed."
    }
    cpu_list=($(source "${COMMON_DIR}"/tools/cpu_util.sh "${CHAINS}" "${NODES}" "${mtcr}" "${dtcr}" ))
    qemu_pids=()
    for pidfile in /var/run/qemu_*.pid; do
        qemu_pids+=($(grep -rwl 'CPU' /proc/"$(sudo cat ${pidfile})"/task/*/comm | xargs dirname | sed -e 's/\/.*\///g'))
    done
    for i in $(seq 0 $(( ${#qemu_pids[@]} - 1 ))); do
        warn "CPU Pinning: ${qemu_pids[${i}]} to ${cpu_list[${i}]}"
        sudo taskset -pc "${cpu_list[${i}]}" "${qemu_pids[${i}]}"
    done
}

function update_vpp_config() {
    # Update VPP configuration.

    set -euo pipefail

    if ! cmp -s "/etc/vpp/setup.gate" "vEdge_vsc_vpp.conf"; then
        warn "Updating VPP configuration."
        sudo cp vEdge_vsc_vpp.conf /etc/vpp/setup.gate || {
            die "Failed to copy VPP configuration!"
        }
        restart_vpp || die
    fi
}


function validate_input() {
    # Validate script input.
    #
    # Arguments:
    # - ${@} - Script parameters.
    # Variable set:
    # - ${CHAINS} - Number of parallel chains.
    # - ${NODES} - Number of NFs in chain.
    # - ${OPERATION} - Operation bit [cleanup|repin].

    set -euo pipefail

    CHAINS="${1}"
    NODES="${2}"
    OPERATION="${3-}"

    if [[ -n ${CHAINS//[0-9]/} ]] || [[ -n ${NODES//[0-9]/} ]]; then
        die "ERROR: Chains and nodes must be an integer values!"
    fi

    if [[ "${CHAINS}" -lt "1" ]] || [[ "${CHAINS}" -gt "10" ]]; then
        die "ERROR: Chains must be an integer value between 1-10!"
    fi

    if [[ "${NODES}" -lt "1" ]] || [[ "${NODES}" -gt "10" ]]; then
        die "ERROR: nodes must be an integer value between 1-10!"
    fi
}


function warn () {
    # Print the message to standard error.
    #
    # Arguments:
    # - ${@} - The text of the message.

    echo "$@" >&2
}


function update_rxq_pinning () {
    # Repin RXQ for Vhosts.

    # Variable read:
    # - ${CHAINS} - Number of parallel chains.
    # - ${NODES} - Number of NFs in chain.

    set -euo pipefail

    warn "Updating VPP configuration (rx-placement)."
    worker=0
    for vEth in $(seq 0 $((${CHAINS} * ${NODES} * 2 - 1))); do
        set -x
        sudo vppctl set interface rx-placement VirtualEthernet0/0/${vEth} queue 0 worker ${worker}
        set +x
        worker=$((($worker + 1) % 2))
    done
}


function repin_vms () {
    # Repin VM resources CPU,RXQ.

    set -euo pipefail

    warn "Reloading vEdge VNFs and updating pinning ....."
    update_rxq_pinning || die
    update_cpu_pinning || die
    warn "Done updating pinning."
}

BASH_FUNCTION_DIR="$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")" || {
    die "Some error during localizing this source directory!"
}
cd "${BASH_FUNCTION_DIR}" || die

VLANS=( )

validate_input "${@}" || die
if [ "${OPERATION}" == "clean" ]; then
    clean_vms || die
elif [ "${OPERATION}" == "repin" ] && [ ${#RUNNING_VMS[@]} -gt 0 ]; then
    repin_vms || die
elif [ "${OPERATION}" == "repin" ] && [ ${#RUNNING_VMS[@]} -eq 0 ]; then
    die "ERROR: vEdge VNFs not running. Unable to update pinning!"
else
    clean_vms || die

    warn "Updating & Restarting VPP to prepare for VM interfaces ....."
    source ./create_vpp_config.sh "${CHAINS}" "${NODES}" ${VLANS[@]} || {
        die "Failed to create VPP configuration!"
    }
    update_vpp_config || die

    # Start VNFs.
    for chain in $(seq 1 "${CHAINS}"); do
        for node in $(seq 1 "${NODES}"); do
            sudo ./kernel_vm.sh "${chain}" "${node}" "${NODES}"
        done
    done
    update_cpu_pinning || die
    update_rxq_pinning || die

    warn "vEdge Chain Started."
fi
