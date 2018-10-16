#! /bin/bash

check_status() {
if [ ! "$1" == "0" ]; then
  echo "Previous function returned an error - Stopping script"
  exit 1
fi
}

update_startup() {
if ! cmp -s "/etc/vpp/startup.conf" "VPP_configs/vEdge_startup.conf" ; then
  echo "Updating VPP startup configuration"
  cp VPP_configs/vEdge_startup.conf /etc/vpp/startup.conf
  service vpp restart
  sleep 5
fi
}

# Function to update sysctl based on number of hugepages on server
config_sysctl() {
  hpages="4096" # Static to match CSIT server configuration
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

mydir=$(dirname $0)
cd $mydir

input="$1"

# Check if VPP is already installed
if [ ! -z "$(dpkg -l | awk '{print $2}' | grep vpp)" ]; then
  if [ ! "$input" == "clean" ]; then
    echo "VPP already installed"
    config_sysctl
    update_startup
    echo "Existing installation can be removed using: $0 clean"
    exit 1
  else
    rm -rf vpp
    for pkg in $(dpkg -l | awk '{print $2}' | grep vpp); do
      sudo dpkg -r $pkg
    done
    echo "VPP build directory and packages removed"
    exit 0
  fi
fi

# Build and install VPP
curl -s https://packagecloud.io/install/repositories/fdio/1807/script.deb.sh | sudo bash
sudo apt-get update 
sudo apt-get -y install vpp vpp-plugins vpp-dbg vpp-dev vpp-api-java vpp-api-python vpp-api-lua
sleep 3
if [ ! -z "$(dpkg -l | awk '{print $2}' | grep vpp)" ]; then
  echo "Build and installation complete"
  config_sysctl
  mkdir /etc/vpp/sockets
  update_startup
  echo "Reconfiguring VPP to vEdge CNF Configuration"
  cd ..
  ./reconfigure.sh CNF
else
  echo "Something went wrong while building and installing"
  exit 1
fi
exit 0
