#!/usr/bin/env bash

set -euo pipefail


function clean_tmp_files () {
    # Cleanup temporary files.

    set -euo pipefail

    config_files=( vEdge_Interfaces.tmp vEdge.xml )

    for file in "${config_files[@]}"; do
        if [ -f "${file}" ]; then
            sudo rm -f ${file} || true
        fi
    done
}


function clean_vms () {
    # Destroy VagrantVM, not image.
    #
    # Variable reads:
    # - ${CHAINS} - Number of parallel chains.
    # - ${NODES} - Number of NFs in chain.

    set -euo pipefail

    for chain in $(seq 1 "${CHAINS}"); do
        for node in $(seq 1 "${NODES}"); do
            sudo vagrant destroy c${chain}n${node}Edge -f || true
        done
    done
}


function create_interface_list() {
    # Create interface list for virsh.
    #
    # Arguments:
    # - ${1} - Chain ID.
    # - ${2} - Node ID.
    # Variable reads:
    # - ${NODES} - Number of NFs in chain.

    set -euo pipefail

    if [[ "${2}" == "1" ]] && [[ "${NODES}" == "1" ]]; then
        mac1=52:54:0"$((${1} - 1))":00:00:aa
        mac2=52:54:0"$((${1} - 1))":00:00:bb
    elif [[ "${2}" == "1" ]]; then
        mac1=52:54:0"$((${1} - 1))":00:00:aa
        mac2=52:54:0"$((${1} - 1))":00:01:bb
    elif [[ "${2}" == "${NODES}" ]]; then
        mac1=52:54:0"$((${1} - 1))":00:0"${2}":aa
        mac2=52:54:0"$((${1} - 1))":00:00:bb
    else
        mac1=52:54:0"$((${1} - 1))":00:0"${2}":aa
        mac2=52:54:0"$((${1} - 1))":00:0"${2}":bb
    fi
    offset=$(((${1} - 1) * ${NODES} * 2))
    bash -c "cat > vEdge_Interfaces.tmp" <<EOF
    <interface type='vhostuser'>
      <mac address='${mac1}'/>
      <source type='unix' path='/var/run/vpp/sock$((${offset} + (${2} * 2 - 1))).sock' mode='client'/>
      <model type='virtio'/>
      <driver queues='1' rx_queue_size='1024' tx_queue_size='1024'/>
    </interface>
    <interface type='vhostuser'>
      <mac address='${mac2}'/>
      <source type='unix' path='/var/run/vpp/sock$((${offset} + (${2} * 2))).sock' mode='client'/>
      <model type='virtio'/>
      <driver queues='1' rx_queue_size='1024' tx_queue_size='1024'/>
    </interface>
EOF
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

function get_running_vms () {
    # Get list of running VMs.
    #
    # Variable read:
    # - ${CHAINS} - Number of parallel chains.
    # - ${NODES} - Number of NFs in chain.
    # Variable set:
    # - ${RUNNING_VMS} - List of running VMs.

    set -euo pipefail

    RUNNING_VMS=()
    warn "Checking for existing VMs ....."
    for chain in $(seq 1 ${CHAINS}); do
        for node in $(seq 1 ${NODES}); do
            state=$(sudo vagrant status | grep c${chain}n${node}Edge | awk '{print $2}') || true
            if [ "${state}" == "running" ]; then
                RUNNING_VMS+="c${chain}n${node}Edge "
            fi
        done
    done
}


function restart_vpp () {
    # Restarts VPP service.

    set -euo pipefail

    warn "Restarting of VPP ....."
    sudo service vpp restart || die "Service restart failed!"
    sleep 5 || die
}


function set_hostname () {
    # Workaround for setting proper hostname in VNFs.
    # Vagrant sets same hostname for all VNFs in set.
    #
    # Arguments:
    # - ${1} - Chain ID.
    # - ${2} - Node ID.

    set -euo pipefail

    cmd="./update_hostname.sh ${1} ${2}"
    sudo vagrant ssh c${1}n${2}Edge -c "${cmd}"
}

function update_cpu_pinning () {
    # Update CPU pinning for each VM via virsh.
    #
    # Arguments:
    # - ${1} - Chain ID.
    # - ${2} - Node ID.

    set -euo pipefail

    # Create CORE lists.
    if [ "${CHAINS}" -eq 1 ] && [ "${NODES}" -eq 1 ]; then
        mtcr=1
    else
        mtcr=2
    fi
    dtcr=1
    COMMON_DIR="$(readlink -e "$(git rev-parse --show-toplevel)")" || {
        die "Readlink or git rev-parse failed."
    }
    cpu_list=($(source "${COMMON_DIR}"/tools/cpu_util.sh "${CHAINS}" "${NODES}" "${mtcr}" "${dtcr}" ))
    core_count=0
    for id in $(virsh list --state-running | grep multichain | awk '{print $1}'); do
        vagrant_id="$(virsh dominfo ${id} | grep 'Name' | awk '{print $2}' | awk -F _ '{print $4}')"
        warn "CPU Pinning: Chain ${vagrant_id:1:1}, Node ${vagrant_id:3:1}"
        for core in {0..2}; do
            sudo virsh vcpupin ${id} ${core} ${cpu_list[${core_count}]} || {
                die "Failed to repin VM cores!"
            }
            (( core_count++ ))
        done
    done
}

function update_vpp_config() {
    # Update VPP configuration.

    set -euo pipefail

    if ! cmp -s "/etc/vpp/setup.gate" "vEdge_vsc_vpp.conf"; then
        warn "Updating VPP configuration."
        sudo cp vEdge_vsc_vpp.conf /etc/vpp/setup.gate || {
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
    # - ${NODES} - Number of NFs in chain.
    # - ${OPERATION} - Operation bit [cleanup|repin].

    set -euo pipefail

    CHAINS="${1}"
    NODES="${2}"
    OPERATION="${3-}"

    if [[ -n ${CHAINS//[0-9]/} ]] || [[ -n ${NODES//[0-9]/} ]]; then
        die "ERROR: Chains and nodes must be an integer values!"
    fi

    if [[ "${CHAINS}" -lt "1" ]] || [[ "${CHAINS}" -gt "8" ]]; then
        die "ERROR: Chains must be an integer value between 1-8!"
    fi

    if [[ "${NODES}" -lt "1" ]] || [[ "${NODES}" -gt "8" ]]; then
        die "ERROR: Nodes must be an integer value between 1-8!"
    fi
}


function warn () {
    # Print the message to standard error.
    #
    # Arguments:
    # - ${@} - The text of the message.

    echo "$@" >&2
}


function update_rxq_pinning () {
    # Repin RXQ for Vhosts.

    # Variable read:
    # - ${CHAINS} - Number of parallel chains.
    # - ${NODES} - Number of NFs in chain.

    set -euo pipefail

    warn "Updating VPP configuration (rx-placement)."
    worker=0
    for vEth in $(seq 0 $((${CHAINS} * ${NODES} * 2 - 1))); do
        set -x
        sudo vppctl set interface rx-placement VirtualEthernet0/0/${vEth} queue 0 worker ${worker}
        set +x
        worker=$((($worker + 1) % 2))
    done
}


function repin_vms () {
    # Repin VM resources CPU,RXQ.

    set -euo pipefail

    warn "Reloading vEdge VNFs and updating pinning ....."
    sudo taskset 0xF vagrant reload || die "Failed to reload Vagrant!"
    sleep 5 || die
    update_rxq_pinning || die
    update_cpu_pinning || die
    warn "Done updating pinning."
}


BASH_FUNCTION_DIR="$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")" || {
    die "Some error during localizing this source directory!"
}
cd "${BASH_FUNCTION_DIR}" || die

VLANS=( )

validate_input "${@}" || die
if [ "${OPERATION}" == "clean" ]; then
    clean_vms || die
elif [ "${OPERATION}" == "repin" ] && [ ${#RUNNING_VMS[@]} -gt 0 ]; then
    repin_vms || die
elif [ "${OPERATION}" == "repin" ] && [ ${#RUNNING_VMS[@]} -eq 0 ]; then
    die "ERROR: vEdge VNFs not running. Unable to update pinning!"
else
    get_running_vms || die

    if [ ${#RUNNING_VMS[@]} -gt 0 ]; then
        warn "Usage: ${0} <Chains> <Nodes> [clean|repin]"
        die "One or more VMs are running, please remove before running script: ${RUNNING_VMS[@]}!"
    fi

    warn "Updating & Restarting VPP to prepare for VM interfaces ....."
    source ./create_vpp_config.sh "${CHAINS}" "${NODES}" ${VLANS[@]} || {
        die "Failed to create VPP configuration!"
    }
    update_vpp_config || die

    if [ -z "$(vagrant box list | grep vedge)" ]; then
        echo "Base image not found - Building"
        pushd ../base_image
        ./build_vm.sh
        popd
    fi

    source ./create_vagrantfile.sh "${CHAINS}" "${NODES}" || {
        die "Failed to create Vagrantfile!"
    }

    sudo taskset 0xF vagrant up || {
        die "Failed to Vagrant VM up!"
    }

    clean_tmp_files || die
    for id in $(virsh list --state-running | grep multichain | awk '{print $1}'); do
        warn "Virsh ID: ${id}"
        sudo virsh dumpxml --inactive --security-info ${id} > vEdge.xml || {
            die "Failed to dumpxml VM ${id}!"
        }
        # Below we collect vagrant_id, since instances might not spawn in
        # correct order
        vagrant_id="$(virsh dominfo ${id} | grep 'Name' | awk '{print $2}' | awk -F _ '{print $4}')"
        warn "Vagrant ID: Chain ${vagrant_id:1:1}, Node ${vagrant_id:3:1}"
        line=$(grep -HrIin "<serial type='pty'>" vEdge.xml | awk -F ':' '{print $2}')
        create_interface_list ${vagrant_id:1:1} ${vagrant_id:3:1} || die
        cat vEdge_Interfaces.tmp || die
        sed -i "$((line-1))r vEdge_Interfaces.tmp" vEdge.xml || die
        sleep 1
        sudo virsh define vEdge.xml || die
    done
    repin_vms || die
    for chain in $(seq 1 ${CHAINS}); do
        for node in $(seq 1 ${NODES}); do
            cmd="cp /vagrant/* . && chmod +x vnf_vedge_install.sh && ./vnf_vedge_install.sh ${chain} ${node} ${NODES}"
            sudo vagrant ssh c${chain}n${node}Edge -c "$cmd"
            set_hostname ${chain} ${node} || die
        done
    done
    warn "vEdge Chain Started."
fi
