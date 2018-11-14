#!/usr/bin/env bash

set -euo pipefail

chain="${1}"
node="${2}"

old="$(cat /etc/hosts | grep 'c*v*Edge' | awk '{print $2}')"
if [ ! -z "${old}" ]; then
  sudo sed -i "s/${old}/c${chain}n${node}Edge/g" /etc/hosts
  sudo hostnamectl set-hostname "c${chain}n${node}Edge"
  sudo systemctl restart systemd-logind.service
fi
