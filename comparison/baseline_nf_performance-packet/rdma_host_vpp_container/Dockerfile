FROM ubuntu:18.04

RUN apt update && apt-get --no-install-recommends install -y apt-utils ca-certificates \
    sudo \
    make \
    git \
    cpp \
    gcc \
    libssl-dev \
    libmnl-dev \
    libnuma-dev \
    net-tools \
    rdma-core \
    nasm \
    python-pexpect \
    vim \
    systemd

RUN git clone --depth 1 -b stable/1904 https://github.com/FDio/vpp.git /srv/vpp

RUN cd /srv/vpp \
    && yes Y | make install-dep \
    && make dpdk-install-dev DPDK_MLX5_PMD=y DPDK_MLX5_PMD_DLOPEN_DEPS=y \
    && cp /opt/vpp/external/x86_64/lib/librte_pmd_mlx5_glue* /usr/lib/ \
    && make pkg-deb vpp_uses_dpdk_mlx5_pmd=yes DPDK_MLX5_PMD_DLOPEN_DEPS=y \
    && cd /srv/vpp/build-root \
    && dpkg -i $(ls /srv/vpp/build-root/ | grep '.deb' | grep -v 'dbg' | grep -v 'python' | grep -v 'vpp-api')

COPY shared/run_vpp/run_vpp.sh /tmp/

ENTRYPOINT ["bash", "/tmp/run_vpp.sh"]
