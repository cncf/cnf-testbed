FROM ubuntu:18.04

ENV VPP_VER "18.10"

RUN apt-get update && apt-get install -y \
    vlan \
    vim \
    curl \
    systemd

RUN curl -s https://packagecloud.io/install/repositories/fdio/release/script.deb.sh | bash

RUN apt-get install -y \
    dpdk \
    vpp=${VPP_VER}-release \
    vpp-plugins=${VPP_VER}-release \
    vpp-dev=${VPP_VER}-release \
    vpp-dbg=${VPP_VER}-release \
    vpp-lib=${VPP_VER}-release

ENTRYPOINT ["vpp", "-c", "/tmp/shared/startup.conf"]
