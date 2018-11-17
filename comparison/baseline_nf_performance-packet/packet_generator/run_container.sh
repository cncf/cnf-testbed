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

function clean_nfvbench () {
    # Remove nfvbench container

    set -euo pipefail

    docker rm --force nfvbench || {
        die "Failed to remove container!"
    }
    warn "NFVbench container removed."
}


function start_nfvbench () {
    # Start nfvbench container.

    set -euo pipefail

    trex_ver='v2.32'
    nfvbench_ver="opnfv/nfvbench:2.0.5"

    sudo docker pull "${nfvbench_ver}" || {
        die "Failed to pull container!"
    }
    if [ -z "$(docker inspect -f {{.State.Running}} nfvbench)" ]; then
        sudo docker run --detach --net=host --privileged -v $PWD:/tmp/nfvbench \
            -v /dev:/dev \
            -v /lib/modules/$(uname -r):/lib/modules/$(uname -r) \
            -v /usr/src:/usr/src -v /usr/bin/ofed_info:/usr/bin/ofed_info \
            -v /etc/libibverbs.d:/etc/libibverbs.d -v /usr/lib:/tmp/lib \
            -v /dev/mst:/dev/mst -v /usr/lib:/usr/lib -v /lib:/lib \
            --name nfvbench "${nfvbench_ver}" || {
            die "Failed to start nfvbench container!"
        }
        warn "Remember to update nfvbench_config.cfg with correct PCI addresses."
        # Below command updates the number of hugepages available for TRex,
        # allowing more cores to be used
        sudo docker exec -it nfvbench sed -i -e "s/512 /2048 /" -e "s/512\"/2048\"/" /opt/trex/"${trex_ver}"/trex-cfg
        # Also change the mbuf factor to further reduce the memory usage
        sudo docker exec -it nfvbench sed -i -e "s/--cfg {} \&>/--cfg {} --mbuf-factor 0.2 \&>/g" /nfvbench/nfvbench/traffic_server.py
    fi

    warn "NFVbench container running."
}

BASH_FUNCTION_DIR="$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")" || {
    die "Some error during localizing this source directory!"
}
cd "${BASH_FUNCTION_DIR}" || die

if [ "${1-}" == "clean" ]; then
    clean_nfvbench || die
else
    start_nfvbench || die
fi
