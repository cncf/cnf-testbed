#! /bin/bash

# Update VPP configuration to match vBNG test case
if ! cmp -s "/etc/vpp/setup.gate" "VPP_Configs/vBNG_vm.conf" ; then
  echo "Updating VPP configuration"
  cp VPP_Configs/vBNG_vm.conf /etc/vpp/setup.gate
  service vpp restart
  sleep 5
fi

input="$1"

./vBNG/run_vm.sh "$input"

./Pktgen/run_vm.sh "$input"
