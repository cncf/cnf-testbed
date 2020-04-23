FROM ubuntu:18.04

ENV VPP_VER "20.01"

RUN apt-get update && apt-get install -y --no-install-recommends \
    gnupg \
    apt-transport-https \
    curl \
    ca-certificates

RUN curl -s https://packagecloud.io/install/repositories/fdio/release/script.deb.sh | bash
RUN apt-get install -y --no-install-recommends \
    dpdk \
    vpp=${VPP_VER}-release \
    vpp-plugin-core=${VPP_VER}-release \
    vpp-plugin-dpdk=${VPP_VER}-release \
    libvppinfra=${VPP_VER}-release

CMD ["/usr/bin/vpp", "-c", "/etc/vpp/startup.conf"]
