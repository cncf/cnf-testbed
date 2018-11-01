#! /bin/bash

# Don't install anything if VPP service exists
if [ ! -z "$(systemctl | grep vpp.service)" ]; then
  echo "VPP already installed on instance"
  echo "Exiting"
  exit 0
fi

apt-get install -y curl

. /etc/lsb-release
#DISTRIB_ID=Ubuntu
#DISTRIB_RELEASE=18.04
#DISTRIB_CODENAME=bionic
#DISTRIB_DESCRIPTION="Ubuntu 18.04 LTS"

if [ "$DISTRIB_CODENAME" == "bionic" ]; then
  # Install VPP 18.07
  curl -L https://packagecloud.io/fdio/1807/gpgkey |sudo apt-key add -
  rm /etc/apt/sources.list.d/99fd.io.list
  echo "deb [trusted=yes] https://packagecloud.io/fdio/1807/ubuntu/ bionic main" | tee -a /etc/apt/sources.list.d/99fd.io.list
  apt-get update
  apt-get install -y vpp vpp-lib vpp-plugins vpp-dbg vpp-dev vpp-api-java vpp-api-python vpp-api-lua
elif [ "$DISTRIB_CODENAME" == "xenial" ]; then
  # Install VPP 18.04 (stable)
  export UBUNTU="xenial"
  export RELEASE=".stable.1804"
  rm /etc/apt/sources.list.d/99fd.io.list
  echo "deb [trusted=yes] https://nexus.fd.io/content/repositories/fd.io$RELEASE.ubuntu.$UBUNTU.main/ ./" | tee -a /etc/apt/sources.list.d/99fd.io.list
  sudo apt-get update
  apt-get install -y vpp vpp-lib vpp-plugins vpp-dbg vpp-dev vpp-api-java vpp-api-python vpp-api-lua
  touch /etc/vpp/setup.gate
  sed -i '8i\  startup-config /etc/vpp/setup.gate' /etc/vpp/startup.conf
else
  echo "Unsupported environment - Try manual install"
  echo "Exiting"
  exit 0
fi
