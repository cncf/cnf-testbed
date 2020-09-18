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


function docker_build_image () {
    # Build docker image.
    if [ -z "$(docker image list | grep cnf_vedge_ipsec)" ]; then
        docker build -t cnf_vedge_ipsec . || die "Building docker image failed!"
        warn "Container image built."
    else
        warn "Skipping as container already exists. Remove first."
    fi
}


function docker_remove_image () {
    # Remove docker image.
    docker image rm --force cnf_vedge_ipsec || die "Removing docker image failed!"
    warn "Image removed."
    exit 0
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

if [ "${1-}" == "clean" ]; then
    docker_remove_image || die
fi
docker_build_image || die
