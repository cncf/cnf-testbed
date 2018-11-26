#!/usr/bin/env bash

set -euo pipefail


function create_cpu_list () {
    # Create the list of CPUs detected by system.
    #
    # Variables set:
    # ${SKIP} - Numa interleaving skip offset.
    # ${SIBLING} - Sibling thread offset.
    # ${SYSTEM_CPUS} - List of System allocation CPUs.
    # ${SWITCH_CPUS} - List of Vswitch allocation CPUs.
    # ${NUMA_CPUS} - List of CPUs from single package (socket).

    set -euo pipefail

    # CPU alternative enumerating per
    # https://www.kernel.org/doc/Documentation/x86/topology.txt.
    if lscpu | grep "Intel(R) Xeon(R) Gold"; then
        alternative_enumeration=true
    else
        alternative_enumeration=false
    fi
    packages=2
    threads_per_core=2
    threads_count=$(lscpu -p | grep -v "#" | wc -l)
    max_cpus=$(( "${threads_count}" / "${packages}" / "${threads_per_core}" ))

    if ${alternative_enumeration}; then
        SKIP=2
        SIBLING=$(( "${max_cpus}" * 2 ))
    else
        SKIP=1
        SIBLING=$(( "${max_cpus}" * 2 ))
    fi

    NUMA_CPUS=( $(seq 0 "${SKIP}" $(( ("${max_cpus}" * "${SKIP}") - 1 ))) )
    SYSTEM_CPUS=( 0 )
    SWITCH_CPUS=( 1 )
}


function create_reserved_cpu_list () {
    # Create the list of available CPUs for mapping.
    #
    # Variables read:
    # ${CHAINS} - Number of chains.
    # ${NODENESS} - Number of nodes per chain.
    # ${SKIP} - Numa interleaving skip offset.
    # ${SYSTEM_CPUS} - List of System allocation CPUs.
    # ${SWITCH_CPUS} - List of Vswitch allocation CPUs.
    # ${CPUS_NUMA} - List of CPUs from single package (socket).
    # Variables set:
    # ${MT_CPUS} - Cores allocated for main threads.
    # ${DT_CPUS} - Cores allocated for data plane threads.

    set -euo pipefail

    create_cpu_list || die

    nf_count=$(( "${CHAINS}" * "${NODENESS}" ))
    reserved_cpus=$(( "${#SYSTEM_CPUS[@]}" + "${#SWITCH_CPUS[@]}" ))

    mt_req=$(( "${nf_count}"/"${MTCR}" ))
    dt_req=$(( "${nf_count}"/"${DTCR}" ))
    available=$(( "${reserved_cpus}" + "${mt_req}" + "${dt_req}" ))
    if [ "${available}" -gt "${#NUMA_CPUS[@]}" ]; then
        die "Impossible to place VFs to cores!"
    fi

    mt_start=$(( "${reserved_cpus}" * "${SKIP}"))
    mt_end=$(( ("${reserved_cpus}" + "${mt_req}") * "${SKIP}" - 1 ))
    MT_CPUS=( $(seq "${mt_start}" "${SKIP}" "${mt_end}") )

    dt_start=$(( ("${reserved_cpus}" + "${#MT_CPUS[@]}") * "${SKIP}" ))
    dt_end=$(( "${dt_start}" + ("${dt_req}" * "${SKIP}") - 1 ))
    DT_CPUS=( $(seq "${dt_start}" "${SKIP}" "${dt_end}") )

    warn "MT allocation (MTCR=${MTCR}): ${MT_CPUS[@]}"
    warn "DT allocation (DTCR=${DTCR}): ${DT_CPUS[@]}"
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


function return_allocated_cpu_list () {

    set -euo pipefail

    if [ "${#MT_CPUS[@]}" -eq 0 ] || [ "${#DT_CPUS[@]}" -eq 0 ]; then
        die "Empty reservation array!"
    fi

    declare -a output

    for chain in $( seq 0 $(("${CHAINS}" - 1)) ); do
        for node in $( seq 0 $(("${NODENESS}" - 1)) ); do
            pre_offset=$(( "${node}" + "${chain}" * "${NODENESS}" ))
            mt_chg=$(( "${pre_offset}" / "${#MT_CPUS[@]}" ))
            mt_idx=$(( "${pre_offset}" % "${#MT_CPUS[@]}" ))
            dt_idx=$(( "${pre_offset}" % "${#DT_CPUS[@]}" ))

            if [ $(( "${mt_chg}" % 2 )) -eq 0 ]; then
                warn "MT: $(( ${MT_CPUS[${mt_idx}]} )), DT: $(( ${DT_CPUS[${dt_idx}]} )),$(( ${DT_CPUS[${dt_idx}]} + ${SIBLING} ))"
                output+=($(( "${MT_CPUS[${mt_idx}]}" )))
            else
                warn "MT: $(( ${MT_CPUS[${mt_idx}]} + ${SIBLING} )), DT: $(( ${DT_CPUS[${dt_idx}]} )),$(( ${DT_CPUS[${dt_idx}]} + ${SIBLING} ))"
                output+=($(( "${MT_CPUS[${mt_idx}]}" + "${SIBLING}" )))
            fi
            output+=($(( "${DT_CPUS[${dt_idx}]}" )))
            output+=($(( "${DT_CPUS[${dt_idx}]}" + "${SIBLING}" )))
        done
    done

    echo "${output[@]}"
}


function validate_input() {
    # Validate script input.
    #
    # Arguments:
    # - ${@} - Script parameters.
    # Variable set:
    # - ${CHAIN} - Chain ID.
    # - ${NODENESS} - Number of NFs in chain.
    # - ${MTCR} - Main thread to core ratio (MTCR).
    # - ${DTCR} - Dataplane thread to core ratio (DTCR).

    set -euo pipefail

    if [[ "${#}" -lt "4" ]]; then
        warn "  Usage: $0 <Chains> <Nodeness> <MTCR> <DTCR>"
        die "ERROR - At least 4 input arguments required!"
    fi

    # Number of chains.
    CHAINS=${1}
    # Number of nodes per chain.
    NODENESS=${2}
    # Main thread to core ratio (MTCR).
    MTCR=${3}
    # Dataplane thread to core ratio (DTCR).
    DTCR=${4}

    if [[ -n ${MTCR//[0-9]/} ]] || [[ -n ${DTCR//[0-9]/} ]]; then
        die "ERROR: MTCR and DTCR must be an integer values!"
    fi

    if [[ -n ${CHAINS//[0-9]/} ]] || [[ -n ${NODENESS//[0-9]/} ]]; then
        die "ERROR: Chains, nodeness must be an integer values!"
    fi

    nf_count=$(( "${CHAINS}" * "${NODENESS}" ))

    if [ "${nf_count}" -lt ${MTCR} ] || [ "${nf_count}" -lt ${DTCR} ]; then
        die "Invalid combination (MTCR or DTCR must be higher then NF count)!"
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
create_reserved_cpu_list "${@}" || die
return_allocated_cpu_list || die
