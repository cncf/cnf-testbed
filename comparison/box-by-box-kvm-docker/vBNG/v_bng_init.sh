#!/bin/bash

sudo systemctl start vpp

# The below tap configuration is not yet needed
echo "EXITING v_bng_init.sh early!"
exit 0 

# wait for TAP_DEV to become active before setting a route
TAP_DEV=tap0
STATUS=$(ip link show $TAP_DEV 2> /dev/null)
while [ -z "$STATUS" ]; do
    echo "$(date) v_bng_init.sh: $TAP_DEV is not yet ready..."
    sleep 1
    STATUS=$(ip link show $TAP_DEV 2> /dev/null)
done
ip route add 10.3.0.0/24 via 192.168.40.41 dev $TAP_DEV

