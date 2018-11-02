#! /bin/bash

case $1 in
  VNF)
    config_file="vEdge_vnf.conf"
    ;;
  CNF)
    config_file="vEdge_cnf.conf"
    ;;
  *)
    echo "Usage: $0 {VNF|CNF} [baseline]"
    exit 1
esac

do_restart=0

if [ "$2" == "baseline" ]; then
  startup="vEdge_baseline_startup.conf"
else
  startup="vEdge_startup.conf"
fi

if ! cmp -s "/etc/vpp/startup.conf" "VPP_configs/${startup}" ; then
  echo "Updating VPP Startup configuration"
  cp VPP_configs/${startup} /etc/vpp/startup.conf
  do_restart=1
fi

# Update VPP configuration to match vBNG test case
if ! cmp -s "/etc/vpp/setup.gate" "VPP_configs/${config_file}" ; then
  echo "Updating VPP Setup configuration"
  cp VPP_configs/${config_file} /etc/vpp/setup.gate
  do_restart=1
fi

if [[ "${do_restart}" == "1" ]]; then
  service vpp restart
  sleep 5
  echo "VPP configuration updated"
else
  echo "No update needed"
fi
exit 0
