#!/usr/bin/env bash

set -exuo pipefail


function calibration_set () {
    # Runs calibration set.

    set -exuo pipefail

    cat /proc/cmdline || die "Failed to retrieve cmdline params!"
    lscpu || die "Failed to run lscpu!"

    install_jitter_tool || die
    sudo chrt 5 taskset -c 3 pma_tools/jitter/jitter -i 30 || {
        die "Failed to run jitter tool!"
    }
    sudo modprobe msr || die "Failed to insert MSR kmodule!"
    chmod +x mlc || die "Failed to add execution bit!"
    sudo ./mlc --bandwidth_matrix || die "Failed to run jitter tool!"
    sudo ./mlc --peak_injection_bandwidth || die "Failed to run jitter tool!"
    sudo ./mlc --max_bandwidth || die "Failed to run jitter tool!"
    sudo ./mlc --latency_matrix || die "Failed to run jitter tool!"
    sudo ./mlc --idle_latency || die "Failed to run jitter tool!"
    sudo ./mlc --loaded_latency || die "Failed to run jitter tool!"
    sudo ./mlc --c2c_latency || die "Failed to run jitter tool!"
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


function install_jitter_tool () {
    # Installs pma_tools/jitter.

    set -exuo pipefail

    if [ ! -d pma_tools ]; then
        rm -rf pma_tools || die "Failed to delete pma_tools directory!"
        git clone https://gerrit.fd.io/r/pma_tools || die "Failed to clone!"
        pushd pma_tools/jitter
        make
        popd
    fi
}


function warn () {
    # Print the message to standard error.
    #
    # Arguments:
    # - ${@} - The text of the message.

    echo "$@" >&2
}


BASH_FUNCTION_DIR="$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")" || {
    die "Some error during localizing this source directory!"
}
cd "${BASH_FUNCTION_DIR}" || die

calibration_set || die
