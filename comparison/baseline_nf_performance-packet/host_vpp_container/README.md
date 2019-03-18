## Deploying host VPP in a container
The following steps are intended for deploying the container on a "fresh" Packet.net server equipped with Intel x710 NIC.

The server should be running **Ubuntu 18.04 LTS**

### Update interfaces
Open `/etc/network/interfaces` and remove the interface configuration for `eno2`

### Update GRUB
Open `/etc/default/grub` and replace `GRUB_CMDLINE_LINUX` with the below configuration
```
GRUB_CMDLINE_LINUX="console=tty0 console=ttyS1,115200n8 biosdevname=0 net.ifnames=1 numa_balancing=disable intel_pstate=disable intel_iommu=on iommu=pt isolcpus=2-27,30-55 nohz_full=2-27,30-55 rcu_nocbs=2-27,30-55 nmi_watchdog=0 audit=0 nosoftlockup processor.max_cstate=1 intel_idle.max_cstate=1 hpet=disable tsc=reliable mce=off numa_balancing=disable hugepagesz=2M hugepages=81920"
```
Once updated run `update-grub2`.

### Load vfio-pci module at boot
Create the file `/etc/modules-load.d/vfio-pci.conf`, and add the following content
```
vfio-pci
```

### Reboot the server
Reboot the server to apply the above modifications, and wait for the server to be available through SSH.


### Install Docker
_Installation steps taken from [docker.com](https://docs.docker.com/install/linux/docker-ce/ubuntu/)_

```
apt-get update

apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"

apt-get update

apt-get install docker-ce docker-ce-cli containerd.io
```

### Build and run VPP container
Run the following commands to build and run the container

```
# Build container image (vpp_image)
./builder.sh

# Run VPP container (VPPcontainer using vpp_image)
./runner.sh
```

The configuration used for running VPP can be found in `shared/startup.conf` 

### Access VPP CLI in container

VPP can be accessed through the container

```
docker exec -it VPPcontainer /bin/bash
$ vppctl
```
