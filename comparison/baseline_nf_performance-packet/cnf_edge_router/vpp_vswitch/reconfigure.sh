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

function restart_vpp () {
    # Restarts VPP service.

    set -euo pipefail

    warn "Restarting of VPP ....."
    sudo service vpp restart || die "Service restart failed!"
    sleep 5 || die
}

case "${1}" in
    VNF)
        config_file="vEdge_vnf.conf"
        ;;
    CNF)
        config_file="vEdge_cnf.conf"
        ;;
    *)
        warn "Usage: $0 {VNF|CNF} [baseline]"
        die
esac

if [ "${2-}" == "baseline" ]; then
    startup="vEdge_baseline_startup.conf"
else
    startup="vEdge_startup.conf"
fi

if ! cmp -s "/etc/vpp/startup.conf" "VPP_configs/${startup}" ; then
    warn "Updating VPP Startup configuration."
    sudo cp VPP_configs/"${startup}" /etc/vpp/startup.conf || {
        die "Config copy failed!"
    }
    restart_vpp || die
fi

# Update VPP configuration to match vBNG test case
if ! cmp -s "/etc/vpp/setup.gate" "VPP_configs/${config_file}" ; then
    warn "Updating VPP configuration."
    sudo cp VPP_configs/"${config_file}" /etc/vpp/setup.gate || {
        die "Config copy failed!"
    }
    restart_vpp || die
fi
