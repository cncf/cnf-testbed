#! /bin/bash

case $1 in
  VNF)
    config_file="vEdge_vnf.conf"
    ;;
  CNF)
    config_file="vEdge_cnf.conf"
    ;;
  *)
    echo "Usage: $0 {VNF|CNF}"
    exit 1
esac

# Update VPP configuration to match vBNG test case
if ! cmp -s "/etc/vpp/setup.gate" "VPP_configs/${config_file}" ; then
  echo "Updating VPP configuration"
  cp VPP_configs/${config_file} /etc/vpp/setup.gate
  service vpp restart
  sleep 5
fi

echo "VPP configuration updated"
exit 0
