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

function update_startup() {
    # Update VPP startup configuration.

    set -euo pipefail

    if ! cmp -s "/etc/vpp/startup.conf" "VPP_configs/vEdge_startup.conf" ; then
        warn "Updating VPP startup configuration."
        cp VPP_configs/vEdge_startup.conf /etc/vpp/startup.conf || {
            die "Failed to copy startup config!"
        }
        restart_vpp || die
    fi
}


function config_sysctl() {
    # Function to update sysctl based on number of hugepages on server.

    set -euo pipefail

    hpages="32768" # Enough to support 8 VNFs with current image
    vpp_config="/etc/sysctl.d/80-vpp.conf"
    vpp_hpages="$(grep 'vm.nr_hugepages=' ${vpp_config} | awk -F '=' '{print $2}')"
    if [ ! "${vpp_hpages}" == "${hpages}" ]; then
        warn "Updating ${vpp_config}."
        sudo sed -i "s/vm.nr_hugepages=.*/vm.nr_hugepages=${hpages}/g" "${vpp_config}" || {
            die "Changing ${vpp_config} failed!"
        }
        sudo sysctl -w vm.nr_hugepages="${hpages}" || {
            die "Increasing system huge pages failed!"
        }
        map_count="$(($hpages * 3))"
        sudo sed -i "s/vm.max_map_count=.*/vm.max_map_count=${map_count}/g" "${vpp_config}" || {
            die "Changing ${vpp_config} failed!"
        }
        sudo sysctl -w vm.max_map_count="${map_count}" || {
            die "Increasing system max map count failed!"
        }
        shmmax="$(($hpages * 2048 * 1024))"
        sudo sed -i "s/kernel.shmmax=.*/kernel.shmmax=${shmmax}/g" "${vpp_config}" || {
            die "Changing ${vpp_config} failed!"
        }
        sudo sysctl -w kernel.shmmax=${shmmax} || {
            die "Increasing kernel shmmax failed!"
        }
    fi
}

function installed () {

    set -euo pipefail

    # Check if the given utility is installed. Fail if not installed.
    #
    # Arguments:
    # - ${1} - Utility to check.
    # Returns:
    # - 0 - If command is installed.
    # - 1 - If command is not installed.

    command -v "${1}"
}

function is_vpp_installed () {
    # Function to update sysctl based on number of hugepages on server.

    set -euo pipefail

    # Check if VPP is already installed
    if installed vpp; then
        if [ "${1-}" == "clean" ]; then
            #rm -rf vpp
            for pkg in $(dpkg -l | awk '{print $2}' | grep vpp); do
                sudo dpkg -r "${pkg}" || {
                    die "Removal of vpp package ${pkg} failed!"
                }
            done
            warn "VPP build directory and packages removed."
            exit 0
        else
            warn "VPP already installed."
            config_sysctl || die
            update_startup || die
            die "Existing installation can be removed using: ${0} clean!"
        fi
    fi
}

function install_vpp () {
    # Install vpp.

    set -euo pipefail

    VPP_VERSION="18.10-release"
    artifacts=()
    vpp=(vpp vpp-dbg vpp-dev vpp-lib vpp-plugins)
    if [ -z "${VPP_VERSION-}" ]; then
        artifacts+=(${vpp[@]})
    else
        artifacts+=(${vpp[@]/%/=${VPP_VERSION-}})
    fi
    curl -s https://packagecloud.io/install/repositories/fdio/release/script.deb.sh | sudo bash
    sudo apt-get install -y "${artifacts[@]}" || die "VPP installation failed!"
    sleep 1

    if installed vpp; then
        warn "Build and installation complete."
        config_sysctl || die
        mkdir -p /etc/vpp/sockets || die "Creating socket dir failed!"
        update_startup || die
        warn "Reconfiguring VPP to vEdge CNF Configuration."
        sudo ./reconfigure.sh CNF baseline || die "Reconfiguration failed!"
        exit 0
    else
        die "Something went wrong while building and installing!"
    fi
}

BASH_FUNCTION_DIR="$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")" || {
    die "Some error during localizing this source directory!"
}
cd "${BASH_FUNCTION_DIR}" || die

is_vpp_installed ${1-} || die
install_vpp || die
