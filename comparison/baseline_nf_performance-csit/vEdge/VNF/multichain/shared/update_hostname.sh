#! /bin/bash

cid="$1"

old="$(cat /etc/hosts | grep 'v*Edge' | awk '{print $2}')"
if [ ! -z "${old}" ]; then
  sudo sed -i "s/${old}/v${cid}Edge/g" /etc/hosts
  sudo hostnamectl set-hostname v${cid}Edge
  sudo systemctl restart systemd-logind.service
fi

exit 0
