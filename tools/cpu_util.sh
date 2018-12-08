#!/usr/bin/env bash

set -euo pipefail


function create_cpu_list () {
    # Create the list of CPUs detected by system.
    #
    # Variables set:
    # ${STEP} - Numa interleaving step offset.
    # ${SIBLING_OFFSET} - Sibling thread offset.
    # ${SYSTEM_CPUS} - List of System allocation CPUs.
    # ${SWITCH_CPUS} - List of Vswitch allocation CPUs.
    # ${CPUS} - List of CPUs from single package without siblings (socket).

    set -euo pipefail

    topo="/sys/devices/system/cpu/cpu[0-9]*/topology"

    packages=$(cat ${topo}/physical_package_id | sort | uniq | wc -l) || {
        die "Failed to read CPU!"
    }
    thread_siblings=$(cat ${topo}/thread_siblings | sort | uniq | wc -l) || {
        die "Failed to read CPU!"
    }
    threads_count=$(find ${topo} -name "core_id" | wc -l) || {
        die "Failed to read CPU!"
    }
    ppa=($(find ${topo} -name "physical_package_id" | sort -V | xargs cat)) || {
        die "failed to read cpu!"
    }
    groups=$(printf '%s\n' "${ppa[@]}" | uniq | wc -l)
    threads_per_cpu=$(( ${threads_count} / ${thread_siblings} ))
    max_cpus=$(( ${threads_count} / ${packages} / ${threads_per_cpu} ))

    # CPU alternative enumerating per
    # https://www.kernel.org/doc/Documentation/x86/topology.txt.
    if [ ${groups} -eq ${threads_count} ]; then
        STEP=2
    else
        STEP=1
    fi
    SIBLING_OFFSET="${thread_siblings}"
    CPUS=($(seq 0 "${STEP}" $(( ("${max_cpus}" * "${STEP}") - 1 ))))
    SYSTEM_CPUS=( 0 )
    SWITCH_CPUS=( 2 4 )
}


function create_reserved_cpu_list () {
    # Create the list of available CPUs for mapping.
    #
    # Variables read:
    # ${CHAINS} - Number of chains.
    # ${NODENESS} - Number of nodes per chain.
    # ${STEP} - Numa interleaving skip offset.
    # ${SYSTEM_CPUS} - List of System allocation CPUs.
    # ${SWITCH_CPUS} - List of Vswitch allocation CPUs.
    # ${CPUS} - List of CPUs from single package without siblings (socket).
    # Variables set:
    # ${MT_CPUS} - Cores pre-allocated for main threads.
    # ${DT_CPUS} - Cores pre-allocated for data plane threads.

    set -euo pipefail

    create_cpu_list || die

    nf_count=$(( "${CHAINS}" * "${NODENESS}" ))
    reserved_cpus=$(( "${#SYSTEM_CPUS[@]}" + "${#SWITCH_CPUS[@]}" ))

    mt_req=$(( "${nf_count}" / "${MTCR}" ))
    dt_req=$(( "${nf_count}" / "${DTCR}" ))
    available=$(( "${reserved_cpus}" + "${mt_req}" + "${dt_req}" ))
    if [ "${available}" -gt "${#CPUS[@]}" ]; then
        die "Impossible to place VFs to cores!"
    fi

    mt_start=$(( "${reserved_cpus}" * "${STEP}"))
    mt_end=$(( ("${reserved_cpus}" + "${mt_req}") * "${STEP}" - 1 ))
    MT_CPUS=( $(seq "${mt_start}" "${STEP}" "${mt_end}") )

    dt_start=$(( ("${reserved_cpus}" + "${#MT_CPUS[@]}") * "${STEP}" ))
    dt_end=$(( "${dt_start}" + ("${dt_req}" * "${STEP}") - 1 ))
    DT_CPUS=( $(seq "${dt_start}" "${STEP}" "${dt_end}") )

    warn "MT pre-allocation (MTCR=${MTCR}): ${MT_CPUS[@]}"
    warn "DT pre-allocation (DTCR=${DTCR}): ${DT_CPUS[@]}"
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
    # Create the list of allocated CPUs for mapping.
    #
    # Variables read:
    # ${CHAINS} - Number of chains.
    # ${NODENESS} - Number of nodes per chain.
    # ${SIBLING_OFFSET} - Sibling thread offset.
    # ${MT_CPUS} - Cores pre-allocated for main threads.
    # ${DT_CPUS} - Cores pre-allocated for data plane threads.

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
            partial=()
            if [ $(( "${mt_chg}" % 2 )) -eq 0 ]; then
                partial+=($(( "${MT_CPUS[${mt_idx}]}" )))
            else
                partial+=($(( "${MT_CPUS[${mt_idx}]}" + "${SIBLING_OFFSET}" )))
            fi
            partial+=($(( "${DT_CPUS[${dt_idx}]}" )))
            partial+=($(( "${DT_CPUS[${dt_idx}]}" + "${SIBLING_OFFSET}" )))
            warn "$((${chain}+1))c$((${node}+1))n: ${partial[@]}"
            output+=(${partial[@]})
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
