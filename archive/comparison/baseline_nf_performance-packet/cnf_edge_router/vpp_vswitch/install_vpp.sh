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
        sudo cp VPP_configs/vEdge_startup.conf /etc/vpp/startup.conf || {
            die "Failed to copy startup config!"
        }
        restart_vpp || die
    fi
}


function config_sysctl() {
    # Function to update sysctl based on number of hugepages on server.

    set -euo pipefail

    hpages=$(cat /proc/cmdline | grep -o 'hugepages=[^ ]*' | awk -F '=' '{print $2}')
    if [ -z "${hpages}" ]; then
        hpages=8192
    fi
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


function install_vpp_intel () {
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
    sudo apt-get --no-install-recommends install -y apt-utils ca-certificates "${artifacts[@]}" || die "VPP installation failed!"
    sleep 1

    if installed vpp; then
        warn "Build and installation complete."
        config_sysctl || die
        mkdir -p /etc/vpp/sockets || die "Creating socket dir failed!"
        update_startup || die
        warn "Reconfiguring VPP to vEdge CNF Configuration."
        chmod +x ./reconfigure.sh && sudo ./reconfigure.sh CNF baseline || die "Reconfiguration failed!"
    else
        die "Something went wrong while building and installing!"
    fi
}


function install_vpp_mlx () {
    # Install vpp with MLX support.

    set -euo pipefail

    # Check for installed MLNX_OFED_LINUX-4.4-2.0.7.0
    if [ -z "$(ofed_info | grep 'MLNX_OFED_LINUX-4.4-2.0.7.0')" ]; then
        die "Please install MLNX_OFED_LINUX-4.4-2.0.7.0 before installing VPP!"
    fi

    # Check for git
    if ! installed git; then
        apt-get --no-install-recommends install -y git
    fi

    # Build and install VPP
    git clone --depth 1 --branch stable/1807 https://gerrit.fd.io/r/vpp || {
        die "Failed to clone vpp!"
    }
    pushd vpp
    sed -i '/vpp_uses_dpdk_mlx5_pmd/s/^# //g' build-data/platforms/vpp.mk
    make install-dep || die "Failed to install dependencies!"
    make dpdk-install-dev DPDK_MLX5_PMD=y || die "Failed to make dpdk!"
    make build-release || die "Failed to make release!"
    make pkg-deb vpp_uses_dpdk_mlx5_pmd=yes || die "Failed to make pkgs!"

    dpkg -i build-root/vpp-lib* || die "Failed to install!"
    dpkg -i build-root/vpp_18* || die "Failed to install!"
    dpkg -i build-root/vpp-plugins* || die "Failed to install!"
    popd

    if installed vpp; then
        warn "Build and installation complete."
        config_sysctl || die
        mkdir -p /etc/vpp/sockets || die "Creating socket dir failed!"
        update_startup || die
        warn "Reconfiguring VPP to vEdge CNF Configuration."
        chmod +x ./reconfigure.sh && sudo ./reconfigure.sh CNF baseline || die "Reconfiguration failed!"
    else
        die "Something went wrong while building and installing!"
    fi
}

BASH_FUNCTION_DIR="$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")" || {
    die "Some error during localizing this source directory!"
}
cd "${BASH_FUNCTION_DIR}" || die

is_vpp_installed ${2-} || die
if [ "${1}" == "mlx" ]; then
    install_vpp_mlx  || die
elif [ "${1}" == "intel" ]; then
    install_vpp_intel || die
else
    die "Please supply [intel|mlx] to chose Intel or MLX!"
fi
