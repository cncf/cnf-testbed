**Install the Mellanox drivers, libs, tools and dependencies**

Note: We are using an older version of the Mellanox_OFED to work with Ubuntu 16.04 (what's needed by the TRex NFVbench uses).


```
cd /tmp
wget http://content.mellanox.com/ofed/MLNX_OFED-4.4-1.0.0.0/MLNX_OFED_LINUX-4.4-1.0.0.0-ubuntu18.04-x86_64.tgz
tar zxvf MLNX_OFED_LINUX-4.4-1.0.0.0-ubuntu18.04-x86_64.tgz
cd MLNX_OFED_LINUX-4.4-1*
./mlnxofedinstall --dpdk --upstream-libs --force
```
