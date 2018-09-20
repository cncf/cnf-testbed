#! /bin/bash

# Function to update sysctl based on number of hugepages on server
config_sysctl() {
  hpages=$(cat /proc/cmdline | grep -o 'hugepages=[^ ]*' | awk -F '=' '{print $2}')
  if [ ! "$(cat /etc/sysctl.d/80-vpp.conf | grep 'vm.nr_hugepages=' | awk -F '=' '{print $2}')" == "$hpages" ]; then 
    echo "Updating /etc/sysctl.d/80-vpp.conf"
    sudo sed -i "s/vm.nr_hugepages=.*/vm.nr_hugepages=${hpages}/g" /etc/sysctl.d/80-vpp.conf
    sudo sysctl -w vm.nr_hugepages=${hpages}
    map_count=$(($hpages * 3))
    sudo sed -i "s/vm.max_map_count=.*/vm.max_map_count=${map_count}/g" /etc/sysctl.d/80-vpp.conf
    sudo sysctl -w vm.max_map_count=${map_count}
    shmmax=$(($hpages * 2048 * 1024))
    sudo sed -i "s/kernel.shmmax=.*/kernel.shmmax=${shmmax}/g" /etc/sysctl.d/80-vpp.conf
    sudo sysctl -w kernel.shmmax=${shmmax}
  fi
}

# If VPP is installed check/update config and exit
if [ ! -z "$(systemctl | grep vpp.service)" ]; then
  echo "VPP already installed on instance"
  config_sysctl
  echo "Exiting"
  exit 0
fi

. /etc/lsb-release
#DISTRIB_ID=Ubuntu
#DISTRIB_RELEASE=18.04
#DISTRIB_CODENAME=bionic
#DISTRIB_DESCRIPTION="Ubuntu 18.04 LTS"

curl -L https://packagecloud.io/fdio/release/gpgkey |sudo apt-key add -
rm /etc/apt/sources.list.d/99fd.io.list
echo "deb [trusted=yes] https://packagecloud.io/fdio/release/ubuntu/ bionic main" | tee -a /etc/apt/sources.list.d/99fd.io.list
apt-get update
apt-get install -y vpp vpp-lib vpp-plugins vpp-dbg vpp-dev vpp-api-java vpp-api-python vpp-api-lua

config_sysctl

exit 0

## Seeing if this can be simplified ##

if [ "$DISTRIB_CODENAME" == "bionic" ]; then
  # Install VPP 18.07
  curl -L https://packagecloud.io/fdio/1807/gpgkey |sudo apt-key add -
  rm /etc/apt/sources.list.d/99fd.io.list
  echo "deb [trusted=yes] https://packagecloud.io/fdio/1807/ubuntu/ bionic main" | tee -a /etc/apt/sources.list.d/99fd.io.list
  apt-get update
  apt-get install vpp vpp-lib vpp-plugins vpp-dbg vpp-dev vpp-api-java vpp-api-python vpp-api-lua
elif [ "$DISTRIB_CODENAME" == "xenial" ]; then
  # Install VPP 18.04 (stable)
  export UBUNTU="xenial"
  export RELEASE=".stable.1804"
  rm /etc/apt/sources.list.d/99fd.io.list
  echo "deb [trusted=yes] https://nexus.fd.io/content/repositories/fd.io$RELEASE.ubuntu.$UBUNTU.main/ ./" | tee -a /etc/apt/sources.list.d/99fd.io.list
  sudo apt-get update
  apt-get install vpp vpp-lib vpp-plugins vpp-dbg vpp-dev vpp-api-java vpp-api-python vpp-api-lua
  touch /etc/vpp/setup.gate
  sed -i '8i\  startup-config /etc/vpp/setup.gate' /etc/vpp/startup.conf
  config_sysctl
  service vpp restart
else
  echo "Unsupported environment - Try manual install"
  echo "Exiting"
  exit 0
fi
