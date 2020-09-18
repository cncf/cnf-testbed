FROM ubuntu:18.04

ENV VPP_VER "19.04.1"

RUN apt-get update && apt-get install -y \
    vlan \
    vim \
    curl \
    systemd

RUN curl -s https://packagecloud.io/install/repositories/fdio/release/script.deb.sh | bash

RUN apt-get install -y \
    dpdk \
    vpp=${VPP_VER}-release \
    vpp-plugin-core=${VPP_VER}-release \
    vpp-plugin-dpdk=${VPP_VER}-release \
    vpp-dev=${VPP_VER}-release \
    vpp-dbg=${VPP_VER}-release \
    libvppinfra=${VPP_VER}-release

COPY shared/run_vpp/run_vpp.sh /tmp/

ENTRYPOINT ["bash", "/tmp/run_vpp.sh"]
