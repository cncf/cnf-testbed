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


function clean_vagrantfile () {
    # Cleanup vagrantfile.
    #
    # Variable set:
    # - ${VAGRANTFILE} - Vagrant configuration file.

    set -euo pipefail

    VAGRANTFILE="Vagrantfile"
    if [ -f "${VAGRANTFILE}" ]; then
        rm "${VAGRANTFILE}" || die
        touch "${VAGRANTFILE}" || die
    fi
}


function generate_vagrantfile () {
    # Generate vagrantfile.
    #
    # Variable read:
    # - ${VAGRANTFILE} - Vagrant configuration file.
    # Variable set:
    # - ${CHAINS} - Number of parallel chains.
    # - ${NODES} - Number of NFs in chain.
    # - ${VAGRANTFILE} - Vagrant configuration file.

    set -euo pipefail

    bash -c "cat > ${VAGRANTFILE}" <<EOF
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|

  config.vm.box = 'vedge'

  config.vm.synced_folder './shared', '/vagrant'
EOF

    for chain in $(seq 1 ${CHAINS}); do
        for node in $(seq 1 ${NODES}); do
            bash -c "cat >> ${VAGRANTFILE}" <<EOF
  config.vm.define vm_name = 'c${chain}n${node}Edge' do |c${chain}n${node}Edge|
    c${chain}n${node}Edge.vm.hostname = vm_name
    c${chain}n${node}Edge.vm.provider :libvirt do |v|
      v.cpus = 3
      v.numa_nodes = [
        {:cpus => '0-2', :memory => '4096'}
      ]
      v.memorybacking :hugepages
      v.memorybacking :access, :mode => 'shared'
    end
  end
EOF
        done
    done

    echo "end" >> ${VAGRANTFILE} || die "Failed to write to config!"
}


function validate_input() {
    # Validate script input.
    #
    # Arguments:
    # - ${@} - The text of the message.
    # Variable set:
    # - ${CHAINS} - Number of parallel chains.
    # - ${NODES} - Number of NFs in chain.
    # - ${OPERATION} - Operation bit [cleanup|baseline].

    set -euo pipefail

    if [[ "${#}" -lt "2" ]]; then
        warn "Usage: ${0} <Chains> <Nodes>"
        die "ERROR - At least three input arguments required"
    fi

    for param in "${@}"; do
        if [[ -n ${param//[0-9]/} ]]; then
            die "ERROR: Inputs must be an integer values!"
        fi
    done

    CHAINS="${1}"
    NODES="${2}"

    if [[ "${CHAINS}" -lt "1" ]] || [[ "${CHAINS}" -gt "8" ]]; then
        die "ERROR - DEBUG: Only supports up to 1-8 chains!"
    fi

    if [[ "${NODES}" -lt "1" ]] || [[ "${NODES}" -gt "8" ]]; then
        die "ERROR - DEBUG: Only supports up to 1-8 nodes per chain!"
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

validate_input "${@}" || die
clean_vagrantfile || die
generate_vagrantfile || die
