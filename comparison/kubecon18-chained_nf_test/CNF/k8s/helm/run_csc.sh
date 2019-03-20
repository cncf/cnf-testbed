#!/usr/bin/env bash

set -euo pipefail


function clean_containers () {
    # Only removes container, not image.
    #
    # Variable reads:
    # - ${CHAINS} - Number of parallel chains.
    # - ${NODES} - Number of NFs in chain.
    set -euo pipefail
    cnf_list=$(helm ls --all --short | grep cnf)
    if [[ ! -z "${cnf_list}" ]]; then
      helm del --purge ${cnf_list}
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


function host_ssh() {
    # usage: host_ssh <Node IP> <Command>
    ssh -o StrictHostKeyChecking=no root@${1} "${@:2}"
}

function host_scp() {
    # usage: host_scp <Node IP> <Source> <Destination>
    scp -o StrictHostKeyChecking=no ${2} root@${1}:${3}
}

function detect_mellanox () {
    # Check presence of Mellanox card.
    # Returns:
    # - 0 - If Mellanox NIC is there.
    # - 1 - If Mellanox NIC is not there.

    set -euo pipefail

    host_ssh $node_ip lspci | grep Mellanox >/dev/null
}


function detect_xxv710 () {
    # Check presence of XXV710 card.
    # Returns:
    # - 0 - If XXV710 NIC is there.
    # - 1 - If XXV710 NIC is not there.

    set -euo pipefail

    host_ssh $node_ip lspci | grep XXV710 >/dev/null
}

function update_host_vpp() {
    if [[ "${OPERATION}" == "clean" ]]; then
        # No need to update configuration
        return 0
    fi
    node_ip="$(kubectl describe node | grep InternalIP | awk '{print $2}')"
    if [ -z "$node_ip" ]; then
        die "ERROR: Unable to get IP of k8s node"
    fi
    if detect_mellanox; then
        csp_nic="mellanox"
    else
        if detect_xxv710; then
            csp_nic="csit"
        else
            csp_nic="intel"
        fi
    fi
    echo "Updating host VPP configuration to support ${CHAINS} chains, ${NODES} nodes"
    vlans=( $(host_ssh $node_ip cat /etc/vpp/templates/1chain_cnf.j2 | grep 'create sub' | awk '{print $4}') )
    csp_nic=$csp_nic ./create_vpp_config_csc.sh $CHAINS $NODES ${vlans[0]} ${vlans[1]} $config_file
    host_scp $node_ip $config_file /etc/vpp/setup.gate
    host_ssh $node_ip service vpp restart
    sleep 5
}

function validate_input() {
    # Validate script input.
    #
    # Arguments:
    # - ${@} - Script parameters.
    # Variable set:
    # - ${CHAINS} - Number of parallel chains.
    # - ${NODES} - Number of NFs in chain.
    # - ${OPERATION} - Operation bit [clean].

    set -euo pipefail

    if [[ "${#}" -lt "2" ]] && [[ ! "${1-}" == "clean" ]]; then
        warn "  Usage: $0 <Chains> <Chain length> [clean]"
        warn "    (or: $0 clean)"
        die "ERROR - At least 2 input arguments required"
    fi

    CHAINS="${1-}"
    NODES="${2-}"
    OPERATION="${3-}"
    KUBECONFIG="${KUBECONFIG:-}"

    if [[ -z "${KUBECONFIG}" ]] || [[ ! -f "${KUBECONFIG}" ]]; then
      die "ERROR: Env variable KUBECONFIG isn't set or doesn't exist"
    fi

    if [[ "${OPERATION}" == "clean" ]] || [[ "${CHAINS}" == "clean" ]]; then
      # Skip validation and do cleanup
      OPERATION="clean"
      return 0
    fi

    if [[ -n ${CHAINS//[0-9]/} ]] || [[ -n ${NODES//[0-9]/} ]]; then
        die "ERROR: Chains and nodes must be an integer values!"
    fi

    if [[ "${CHAINS}" -lt "1" ]] || [[ "${CHAINS}" -gt "7" ]]; then
        die "ERROR: Chains must be an integer value between 1-7!"
    fi

    if [[ "${NODES}" -lt "1" ]] || [[ "${NODES}" -gt "7" ]]; then
        die "ERROR: Nodes must be an integer value between 1-7!"
    fi

    if [[ "$((NODES * CHAINS))" -gt "7" ]]; then
        die "ERROR: Total number of CNFs can not exceed 7"
    fi

    if [[ ! -z "${OPERATION// }" ]]; then
        die "ERROR: Only 'clean' operation is supported (got ${OPERATION})"
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
    # - ${NODES} - Number of NFs in chain.
    # - ${OPERATION} - Operation bit [cleanup|baseline].
    # Variable read:
    # - ${MAIN_CORES} - List of main cores.
    # - ${WORKER_CORES} - List of worker cores.

    set -euo pipefail

    MAIN_CORES=( 6 34 12 40 18 46 24 )
    WORKER_CORES=( 8,36 10,38 14,42 16,44 20,48 22,50 26,54 )

    # Run conainer matrix.
    idx=0
    for chain in $(seq 1 "${CHAINS}"); do
      for node in $(seq 1 "${NODES}"); do
        echo "Starting Chain ${chain}, Node ${node}"
        ./config_csc.sh $chain $node $NODES ${MAIN_CORES[$idx]} ${WORKER_CORES[$idx]}
        sleep 1
        helm install --name cnf${chain}-${node} ./vedge/
        ((idx++))
      done
    done
}


BASH_FUNCTION_DIR="$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")" || {
    die "Some error during localizing this source directory!"
}
cd "${BASH_FUNCTION_DIR}" || die

validate_input "${@}" || die

config_file="vpp_config.cfg"

if [ "${OPERATION}" == "clean" ]; then
    clean_containers || die
else
    if [[ ! -z "$(kubectl get pods | grep cnf)" ]]; then
      die "ERROR: CNFs already exist. Clean up environment before running"
    fi
    update_host_vpp || die
    run_containers || die
    if [ -f "${config_file}" ]; then
        rm "${config_file}" || die
    fi
fi
