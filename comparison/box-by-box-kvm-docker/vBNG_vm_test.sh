#! /bin/bash

echo ""
echo "TODO:"
echo "  Host VPP"
echo "  - Add sockets for Pktgen"
echo "  - Remove IP addresses and add bridge domains"
echo ""
echo "  Pktgen"
echo "  - Modify to support vhostuser"
echo "  - Optimize VM configuration"
echo ""
echo "  vBNG"
echo "  - Optimize VM configuration"
echo ""

# Update VPP configuration to match vBNG test case
if ! cmp -s "/etc/vpp/setup.gate" "VPP_Configs/vBNG.conf" ; then
  echo "Updating VPP configuration"
  cp VPP_Configs/vBNG.conf /etc/vpp/setup.gate
  service vpp restart
fi
