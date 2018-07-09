#!/bin/bash

service kea-dhcp4-server restart

if [[ -z ${1} ]]; then
  /usr/sbin/named -u bind -f -g
else
  exec "$@"
fi
