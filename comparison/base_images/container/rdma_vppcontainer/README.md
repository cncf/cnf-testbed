## rdma_vppcontainer base-image
This base-image provides a containerized, configurable deployment of VPP v19.04(*). The container serves the following purpose:
* Host vSwitch, when using m2.xlarge servers provided by Packet (Mellanox ConnectX-4 NIC)

Configuration is currently done though a volume mount on the host, where relevant VPP configuration files are located. The local directory should contain a VPP configuration file named `startup.conf` (and any additional setup files used by this), and the directory should map to /etc/vpp/ in the container (i.e. `/etc/vpp/startup.conf`). The mapped host directory is also used for storing the VPP logs in `output.log`.

The image is based on Ubuntu 18.04 LTS.

(*) VPP v19.04.2 as of August 2019

### Prerequisites

Before the image can be built, Docker needs to be installed on the host. The steps provided here are taken from [docker.com](https://docs.docker.com/install/linux/docker-ce/ubuntu/)

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

### Building the base-image

With the prerequisites installed, the rdma_vppcontainer image can be built as follows:
```
./builder.sh
```

Once completed the image can be seen with `docker image ls`. Currently, CNF Testbed does not utilize any local storage for images, but an easy solution is to upload the image to [Docker Hub](https://hub.docker.com/).

To use Docker Hub for storing images, start by creating an account if you don't have one already. Then tag the image as follows:
```
docker tag <Image ID> <Docker Hub username>/<Image name>:<Tag>
```
The `<Image ID>` is found from the list of images, while the remaining parameters depends on your account and preferences.

To push the image, log into your account:
```
docker login
```

Then push the image:
```
docker push <Docker Hub username>/<Image name>
```

Once the image has been uploaded successfully, log out from your account:
```
docker logout
```
