#!/usr/bin/env bash

set -euo pipefail


function clean_containers () {
    # Only removes container, not image.
    #
    # Variable reads:
    # - ${CHAINS} - Number of parallel chains.
    # - ${NODENESS} - Number of NFs in chain.

    set -euo pipefail

    for chain in $(seq 1 "${CHAINS}"); do
        for node in $(seq 1 "${NODENESS}"); do
            sudo docker rm --force "c${chain}n${node}Edge" || true
        done
    done
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
    sleep 5 || die
}


function update_vpp_config() {
    # Update VPP configuration.

    set -euo pipefail

    if ! cmp -s "/etc/vpp/setup.gate" "vEdge_csc_vpp.conf"; then
        warn "Updating VPP configuration."
        sudo cp vEdge_csc_vpp.conf /etc/vpp/setup.gate || {
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
    # - ${NODENESS} - Number of NFs in chain.
    # - ${OPERATION} - Operation bit [cleanup|baseline].

    set -euo pipefail

    CHAINS="${1}"
    NODENESS="${2}"
    OPERATION="${3-}"

    if [[ -n ${CHAINS//[0-9]/} ]] || [[ -n ${NODENESS//[0-9]/} ]]; then
        die "ERROR: Chains and nodeness must be an integer values!"
    fi

    if [[ "${CHAINS}" -lt "1" ]] || [[ "${CHAINS}" -gt "8" ]]; then
        die "ERROR: Chains must be an integer value between 1-8!"
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


function run_containers () {
    # Run container matrix.
    #
    # Variable read:
    # - ${CHAINS} - Number of parallel chains.
    # - ${NODENESS} - Number of NFs in chain.
    # - ${OPERATION} - Operation bit [cleanup|baseline].
    # Variable read:
    # - ${VLANS} - Base VLANS.
    # - ${MAIN_CORES} - List of main cores.
    # - ${WORKER_CORES} - List of worker cores.

    set -euo pipefail

    VLANS=( )

    # Build containers.
    source ./build_container.sh || {
        die "Failed to build container!"
    }
    # Create vpp configuration.
    source ./create_vpp_config.sh "${CHAINS}" "${NODENESS}" ${VLANS[@]} || {
        die "Failed to create VPP config!"
    }
    update_vpp_config || {
        die "Failed to update VPP config!"
    }
    # Create CORE lists.
    mtcr=2
    dtcr=1
    COMMON_DIR="$(readlink -e "$(git rev-parse --show-toplevel)")" || {
        die "Readlink or git rev-parse failed."
    }
    cpu_list=($(source "${COMMON_DIR}"/tools/cpu_util.sh "${CHAINS}" "${NODENESS}" "${mtcr}" "${dtcr}" ))
    # Run conainer matrix.
    n=0
    for chain in $(seq 1 "${CHAINS}"); do
        for node in $(seq 1 "${NODENESS}"); do
            dcr_name="c${chain}n${node}Edge"
            cpuset_cpus="${cpu_list[n]},${cpu_list[n+1]},${cpu_list[n+2]}"
            if [ -z "$(docker inspect -f {{.State.Running}} ${dcr_name})" ]; then
                sudo docker run --privileged --cpus 3 --tty --detach \
                    --cpuset-cpus "${cpuset_cpus}" \
                    --device=/dev/hugepages/:/dev/hugepages/ \
                    --volume "/etc/vpp/sockets/:/root/sockets/" \
                    --name "${dcr_name}" vedge_csc \
                    /vEdge/configure.sh "${chain}" "${node}" "${NODENESS}" "${cpuset_cpus}" || {
                    die "Failed to start ${dcr_name} container!"
                }
            fi
            n=$(( n+3 ))
            warn "${dcr_name} container started at ${cpuset_cpus}."
            sleep 5 || die
        done
    done
    # Restart VPP to get correct queue pinning of Memifs.
    restart_vpp || die
}

BASH_FUNCTION_DIR="$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")" || {
    die "Some error during localizing this source directory!"
}
cd "${BASH_FUNCTION_DIR}" || die

validate_input "${@}" || die
if [ "${OPERATION}" == "clean" ]; then
    clean_containers || die
else
    run_containers || die
fi
