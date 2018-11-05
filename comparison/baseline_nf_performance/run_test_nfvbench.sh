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

function warn () {
    # Print the message to standard error.
    #
    # Arguments:
    # - ${@} - The text of the message.

    echo "$@" >&2
}

function run_bench () {
    # Runs nvfbench and output results into directory
    #
    # Variables read:
    # - ${BASH_FUNCTION_DIR} - Path to script directory.
    # - ${RATES - Path to script directory.
    # - ${ITERATIONS} - Number of bench iterations.
    # - ${DURATION} - Duration of bench iterations.
    # - ${PREFIX} - Prefix for results.

    set -euo pipefail

    pushd "${BASH_FUNCTION_DIR}" || die "Change dir failed!"
    out_dir="results/$(date +%d-%b)/${PREFIX}/${NODENESS}"
    if [ ! -d "${out_dir}" ]; then
        warn "Creating directory ${out_dir}"
        mkdir -p "${out_dir}" || die "Create output dir failed!"
    fi
    for rate in "${RATES[@]}"; do
        for iter in $(seq 1 "${ITERATIONS}"); do
            warn "Running test: ${PREFIX}, Rate: ${rate}, Iteration ${iter}"
            dcr_image="nfvbench"
            dcr_param="--interactive "
            dcr_param+="--tty "
            nfv_param="nfvbench -c /tmp/nfvbench/nfvbench_config.cfg "
            nfv_param+="--rate ${rate} "
            nfv_param+="--flow-count 1000 "
            nfv_param+="--duration ${DURATION} "
            results="${out_dir}/${PREFIX}-${rate}-${iter}.log"
            params=(${dcr_param} ${dcr_image} ${nfv_param})
            sudo docker exec "${params[@]}" 2>&1 | tee -a "${results}"
        done
    done
    popd || die "Change dir failed!"
}

BASH_FUNCTION_DIR="$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")" || {
    die "Some error during localizing this source directory."
}
PREFIX="csc"
RATES=( "${2:-20Gbps}" )
ITERATIONS=1
DURATION=30
NODENESS=${1:-1}

run_bench || die
