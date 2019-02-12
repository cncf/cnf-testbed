#!/bin/bash
git clone https://github.com/DPDK/dpdk.git ~/dpdk
cd ~/dpdk
git checkout tags/v16.11
make install T=x86_64-native-linuxapp-gcc
echo "~/dpdk/x86_64-native-linuxapp-gcc/kmod/igb_uio.ko"
