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
    # - ${CHAINS} - Number of parallel chains.
    # - ${NODES} - Number of NFs in chain.

    set -euo pipefail

    CHAINS="${1}"
    NODES="${2}"

    if [[ -n ${CHAINS//[0-9]/} ]] || [[ -n ${NODES//[0-9]/} ]]; then
        die "ERROR: Chains and nodes must be an integer values!"
    fi

    if [ -z "${CHAINS}" ] || [ -z "${NODES}" ]; then
        warn "Usage: ${0} <chains> <nodes>"
        die "ERROR: Expecting number of chains and nodes (integer) as input!"
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

for chain in $(seq 1 "${CHAINS}"); do
    for node in $(seq 1 "${NODES}"); do
        warn "###### c${chain}n${node}Edge ######"
        docker exec --interactive --tty c${chain}n${node}Edge vppctl show int
    done
done
