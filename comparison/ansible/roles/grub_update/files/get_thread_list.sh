#! /bin/bash 

# Arguments:
#   ${1} - [Optional] (int) number of cores per socket to isolate
# Output:
#   List of cores to isolate using GRUB
#   If no input or 0 is provided, all cores except the first on each socket is isolated

set -euo pipefail

DEBUG=false
ISOLCPUS=${1:-0}

function debug () {
  # Arguments:
  #   ${1} - Debug message
  # Output:
  #   Prints message to stderr
  if $DEBUG; then
    echo "[DEBUG] $@" >&2
  fi
}

function die () {
  # Arguments:
  #   ${1} - [Optional] Error message as quoted string
  # Output:
  #   Prints error message and exits with code 1
  set -x
  set +eu
  echo "${1:-Unspecified runtime error.}"
  exit 1
}

function get_enumeration () {
  # Based on https://www.kernel.org/doc/Documentation/x86/topology.txt (4.b)
  # Script supports both normal and alternative enumeration
  #
  # Arguments:
  #   ${1} - Array of host threads based on CPU0
  #   ${2} - Array of siblings for CPU0
  # Output:
  #   If Hyperthreading is disabled, return 0.
  #   Otherwise, integer value indicating method for enumerating:
  #   1 = normal, 2 = alternative
  threads=(${1})
  siblings=(${2})
  if [[ "${#siblings[@]}" -eq 1 ]]; then
    # No Hyperthreading
    echo "0"
  else
    threads_middle=$((${#threads[@]} / 2))
    debug "Threads_middle: $threads_middle"
    # Hyperthreading - Figure out enumeration
    if [[ "${threads[1]}" == "${siblings[1]}" ]]; then
      # Normal enumeration
      echo "1"
    elif [[ "${threads[$threads_middle]}" == "${siblings[1]}" ]]; then
      # Alternative enumeration
      echo "2"
    else
      die "Unknown enumeration method"
    fi
  fi  
}

function get_isolation_list () {
  # Arguments:
  #   ${1} - Enumeration method
  # Output:
  #   CSV formatted list of threads to isoalte across all sockets
  enumeration=${1}
  thread_csv=$(cat ${topo}/core_siblings_list | sort | uniq) || {
    die "Failed to read thread lists"
  }
  modified_csv=""
  for i in ${thread_csv[@]}; do
    debug "Thread CSV: $i"
    thread_array=(${i//,/ })
    debug "Thread array: ${thread_array[@]}"
    if [[ "${enumeration}" == "0" ]]; then
      # No Hyperthreading
      debug "enum 0 - no HT"
      if [[ "${ISOLCPUS}" == "0" ]]; then
        ISOL=$((${#thread_array[@]} - 1))
      else
        ISOL=${ISOLCPUS}
      fi
      if [[ "$(($ISOL + 1))" -ge "${#thread_array[@]}" ]]; then
        # Not/just enough cores for requested number of isolated cores
        # Isolate all cores except core 0 (host)
        thread_array="${thread_array[@]:1}"
        modified_csv="${modified_csv},${thread_array// /,}"
      else
        thread_array="${thread_array[@]:1:${ISOL}}"
        modified_csv="${modified_csv},${thread_array// /,}"
      fi
    elif [[ "${enumeration}" == "1" ]]; then
      # Normal enumeration
      debug "enum 1 - normal"
      if [[ "${ISOLCPUS}" == "0" ]]; then
        ISOL=$((${#thread_array[@]} - 2))
      else
        ISOL=$((${ISOLCPUS} * 2))
      fi
      if [[ "$(($ISOL + 2))" -ge "${#thread_array[@]}" ]]; then
        # Not/just enough cores for requested number of isolated cores
        # Isolate all cores except both siblings of core 0 (host)
        thread_array="${thread_array[@]:2}"
        modified_csv="${modified_csv},${thread_array// /,}"
      else
        thread_array="${thread_array[@]:2:${ISOL}}"
        modified_csv="${modified_csv},${thread_array// /,}"
      fi
    else
      # Alternative enumeration
      debug "enum 2 - alternative"
      half_length=$((${#thread_array[@]} / 2))
      if [[ "${ISOLCPUS}" == "0" ]]; then
        ISOL=$((${half_length} - 1))
      else
        ISOL=${ISOLCPUS}
      fi
      if [[ "$(($ISOL + 1))" -ge "${half_length}" ]]; then
        # Not/just enough cores for requested number of isolated cores
        # Isolate all cores except both siblings of core 0 (host)
        thread_array1="${thread_array[@]:1:$((${half_length} - 1))}"
        modified_csv="${modified_csv},${thread_array1// /,}"
        thread_array2="${thread_array[@]:$((${half_length} + 1))}"
        modified_csv="${modified_csv},${thread_array2// /,}"
      else
        thread_array1="${thread_array[@]:1:${ISOL}}"
        modified_csv="${modified_csv},${thread_array1// /,}"
        thread_array2="${thread_array[@]:$((${half_length} + 1)):${ISOL}}"
        modified_csv="${modified_csv},${thread_array2// /,}"
      fi
    fi
  done
  if [ -z "$modified_csv" ]; then
    die "Modified CSV is empty."
  else
    modified_csv="${modified_csv:1}"
  fi
  debug "Modified CSV: ${modified_csv}"
  echo "${modified_csv}"
}

function get_host_threads () {
  # Output:
  #   Array of threads on same socket as CPU0
  threads=$(cat /sys/devices/system/cpu/cpu0/topology/core_siblings_list)
  threads=(${threads//,/ })
  debug "CPU0 socket threads: ${threads[@]}"
  echo "${threads[@]}"
}

function get_host_siblings () {
  # Output:
  #   Array of siblings for CPU0
  siblings=$(cat /sys/devices/system/cpu/cpu0/topology/thread_siblings_list)
  siblings=(${siblings//,/ })
  debug "CPU0 Siblings: ${siblings[@]}"
  echo "${siblings[@]}"
}

function get_host_thread_indices () {
  # Arguments:
  #   ${1} - Array of host threads based on CPU0
  #   ${2} - Array of siblings for CPU0
  # Output:
  #   Array of indices for locating CPU0 siblings in array of host threads
  threads=(${1})
  siblings=(${2})
  if [ ${#siblings[@]} -lt 1 ] || [ ${#siblings[@]} -gt 2 ]; then
    die "Number of siblings not supported: ${#siblings[@]}"
  fi
  debug "Sibling count: ${#siblings[@]}"

  for i in "${siblings[@]}"; do
    for k in "${!threads[@]}"; do
      if [[ "${threads[$k]}" = "${i}" ]]; then
        debug "Index: ${k}";
        indices+=($k)
      fi
    done
  done
  debug "Indices: ${indices[@]}"
  echo ${indices[@]}
}

topo="/sys/devices/system/cpu/cpu[0-9]*/topology"

host_threads=$(get_host_threads) || die
host_siblings=$(get_host_siblings) || die
host_indices=$(get_host_thread_indices "${host_threads[@]}" "${host_siblings[@]}") || die
debug "(Main) host indices: ${host_indices[@]}"
enumeration=$(get_enumeration "${host_threads[@]}" "${host_siblings[@]}") || die
debug "(Main) enumeration: ${enumeration}"
isolation_list=$(get_isolation_list "${enumeration}")
debug "(Main) isolation_list: ${isolation_list}"
echo "${isolation_list}"
exit 0
