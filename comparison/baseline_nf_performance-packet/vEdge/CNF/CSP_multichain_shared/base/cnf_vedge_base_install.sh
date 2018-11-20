#! /bin/bash

# Prepare files
cd /vEdge
mkdir ~/sockets

apt-get update -y
apt-get install --allow-unauthenticated -y make gcc libcurl4-openssl-dev python-pip bridge-utils apt-transport-https ca-certificates vim curl
pip install jsonschema

# Install VPP
VPP_VERSION="18.10-release"
artifacts=()
vpp=(vpp vpp-dbg vpp-dev vpp-lib vpp-plugins)
if [ -z "${VPP_VERSION-}" ]; then
    artifacts+=(${vpp[@]})
else
    artifacts+=(${vpp[@]/%/=${VPP_VERSION-}})
fi
curl -s https://packagecloud.io/install/repositories/fdio/release/script.deb.sh | bash
apt-get install -y "${artifacts[@]}"
sleep 1
