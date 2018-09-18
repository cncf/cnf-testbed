## Instructions common for the NF machine configuration


**Install the Mellanox drivers, libs, tools and dependencies**

```
cd /tmp
wget http://content.mellanox.com/ofed/MLNX_OFED-4.4-2.0.7.0/MLNX_OFED_LINUX-4.4-2.0.7.0-ubuntu18.04-x86_64.tgz
cd MLNX_OFED_LINUX-4.4-2.0.7.0-ubuntu18.04-x86_64/
./mlnxofedinstall --dpdk --upstream-libs --force
```
