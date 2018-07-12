#!/bin/bash

IF2="eth1"
IF2_MAC="aa:bb:cc:dd:ee:ff"

echo "Changing MAC address for ${IF2} to ${IF2_MAC}"
ip link set dev ${IF2} address "${IF2_MAC}"

service kea-dhcp4-server restart

if [[ -z ${1} ]]; then
  /usr/sbin/named -u bind -f -g
else
  exec "$@"
fi
