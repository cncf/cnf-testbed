#! /bin/bash

if [[ "$#" -lt "3" ]]; then
  echo "ERROR - At least 3 input arguments required"
  echo "  Usage: $0 <Chains> <VLAN#1> <VLAN#2> [baseline]"
  exit 1
fi

chains="$1"
vlans=( "$2" "$3" )
baseline="$4"

if [[ -n ${chains//[0-9]/} ]] || [[ -n ${vlans[0]//[0-9]/} ]] || [[ -n ${vlans[1]//[0-9]/} ]]; then
  echo "ERROR: Inputs must be an integer values"
  echo "  Provided: $0 $1 $2 $3 $4"
  echo "  Usage: $0 <Chains> <VLAN#1> <VLAN#2> [baseline]"
  exit 1
fi

if [ ! "${baseline}" == "baseline" ]; then
  if [[ "${chains}" -le "1" ]] || [[ "${chains}" -gt "6" ]]; then
    echo "ERROR - DEBUG: Only supports betwen 2-6 chains"
    echo "  Usage: $0 <Chains> <VLAN#1> <VLAN#2> [baseline]"
    exit 1
  fi
else
  if [[ "${chains}" -le "1" ]] || [[ "${chains}" -gt "8" ]]; then
    echo "ERROR - DEBUG: Baseline only supports betwen 2-8 chains"
    echo "  Usage: $0 <Chains> <VLAN#1> <VLAN#2> [baseline]"
    exit 1
  fi
fi

conf_file="vEdge_multichain_vpp.conf"
if [ -f "${conf_file}" ]; then
  rm ${conf_file}
  touch ${conf_file}
fi

domains=$((${chains} + 1))
for domain in $(seq 1 ${domains}); do
  echo "create bridge-domain ${domain}" >> ${conf_file}
done

echo "" >> ${conf_file}

sockets=$((${chains} * 2))
for socket in $(seq 1 ${sockets}); do
  echo "create vhost-user socket /var/run/vpp/sock${socket}.sock server" >> ${conf_file}
done

echo "" >> ${conf_file}

echo "create sub TwentyFiveGigabitEthernet5e/0/1 ${vlans[0]}" >> ${conf_file}
echo "create sub TwentyFiveGigabitEthernet5e/0/1 ${vlans[1]}" >> ${conf_file}

echo "" >> ${conf_file}

echo "set int l2 bridge TwentyFiveGigabitEthernet5e/0/1.${vlans[0]} 1" >> ${conf_file}
echo "set int l2 bridge VirtualEthernet0/0/0 1" >> ${conf_file}

vEth=1
for bridge in $(seq 2 $((${domains} - 1))); do
  echo "" >> ${conf_file}
  echo "set int l2 bridge VirtualEthernet0/0/${vEth} ${bridge}" >> ${conf_file}
  ((++vEth))
  echo "set int l2 bridge VirtualEthernet0/0/${vEth} ${bridge}" >> ${conf_file}
  ((++vEth))
done

echo "" >> ${conf_file}

echo "set int l2 bridge VirtualEthernet0/0/$((${sockets} - 1)) ${domains}" >> ${conf_file}
echo "set int l2 bridge TwentyFiveGigabitEthernet5e/0/1.${vlans[1]} ${domains}" >> ${conf_file}

echo "" >> ${conf_file}

echo "set int state TwentyFiveGigabitEthernet5e/0/1 up" >> ${conf_file}
echo "set int state TwentyFiveGigabitEthernet5e/0/1.${vlans[0]} up" >> ${conf_file}
echo "set int state TwentyFiveGigabitEthernet5e/0/1.${vlans[1]} up" >> ${conf_file}

echo "" >> ${conf_file}

for veth in $(seq 0 $((${sockets} - 1))); do
  echo "set int state VirtualEthernet0/0/${veth} up" >> ${conf_file}
done

echo "" >> ${conf_file}

echo "set interface l2 tag-rewrite TwentyFiveGigabitEthernet5e/0/1.${vlans[0]} pop 1" >> ${conf_file}
echo "set interface l2 tag-rewrite TwentyFiveGigabitEthernet5e/0/1.${vlans[1]} pop 1" >> ${conf_file}

exit 0
