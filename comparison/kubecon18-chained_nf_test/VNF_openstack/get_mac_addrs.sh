#! /bin/bash

get_mac () {
  openstack port list | grep "${1}" | awk '{print $6}' 
}

if [ $# -ne 2 ]; then
  echo "ERROR: Check arguments"
  echo "USAGE: $0 <Chains> <Nodes>"
  exit
fi

CHAINS="${1}"
NODES="${2}"

for chain in $(seq 1 $CHAINS); do
  left[$((chain - 1))]="'$(get_mac ${chain}_1_${NODES}_l)'"
  right[$((chain - 1))]="'$(get_mac ${chain}_${NODES}_${NODES}_r)'"
done
  
left_string=$( IFS=, ; echo "${left[*]}" )
right_string=$( IFS=, ; echo "${right[*]}")
echo "mac_addrs_left: [$left_string]"
echo "mac_addrs_right: [$right_string]"
