#! /bin/bash

check_status() {
if [ ! "$1" == "0" ]; then
  echo "Previous function returned an error - Stopping script"
  exit 1
fi
}

mydir=$(dirname $0)
cd $mydir

input="$1"

# Check for git
if [ -z "$(dpkg -l | awk '{print $2}' | grep git)" ]; then
  apt install git
fi

# Check for installed MLNX_OFED_LINUX-4.4-2.0.7.0
if [ -z "$(ofed_info | grep 'MLNX_OFED_LINUX-4.4-2.0.7.0')" ]; then
  echo "Please install MLNX_OFED_LINUX-4.4-2.0.7.0 before installing VPP"
  exit 1
fi

# Check if VPP is already installed
if [ ! -z "$(dpkg -l | awk '{print $2}' | grep vpp)" ]; then
  if [ ! "$input" == "clean" ]; then
    echo "VPP already installed"
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
git clone https://gerrit.fd.io/r/vpp
cd vpp
git checkout origin/stable/1807
sed -i '/vpp_uses_dpdk_mlx5_pmd/s/^# //g' build-data/platforms/vpp.mk
make install-dep
check_status "$?"
make dpdk-install-dev DPDK_MLX5_PMD=y
check_status "$?"
make build-release
check_status "$?"
make pkg-deb vpp_uses_dpdk_mlx5_pmd=yes
check_status "$?"

dpkg -i build-root/vpp-lib*
check_status "$?"
dpkg -i build-root/vpp_18*
check_status "$?"
dpkg -i build-root/vpp-plugins*
check_status "$?"

sleep 3
if [ ! -z "$(dpkg -l | awk '{print $2}' | grep vpp)" ]; then
  echo "Build and installation complete"
  echo "Reconfiguring VPP to vEdge CNF Configuration"
  cd ..
  ./reconfigure.sh CNF
else
  echo "Something went wrong while building and installing"
  exit 1
fi
exit 0
