FROM ubuntu:18.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    make \
    git \
    cpp \
    gcc \
    libssl-dev \
    libmnl-dev \
    libnuma-dev \
    rdma-core \
    nasm \
    python-pexpect \
    ca-certificates

RUN git clone --depth 1 https://github.com/FDio/vpp.git --branch v20.01 --single-branch /srv/vpp

WORKDIR /srv/vpp

RUN yes Y | make install-dep \
    && make dpdk-install-dev DPDK_MLX5_PMD=y DPDK_MLX5_PMD_DLOPEN_DEPS=y \
    && cp /opt/vpp/external/x86_64/lib/librte_pmd_mlx5_glue* /usr/lib/ \
    && make pkg-deb vpp_uses_dpdk_mlx5_pmd=yes DPDK_MLX5_PMD_DLOPEN_DEPS=y \
    && cd build-root \
    && dpkg -i $(ls | grep '.deb' | grep -v 'dbg' | grep -v 'python' | grep -v 'vpp-api' | grep -v 'dev') \
    && cd ~ \
    && rm -rf /srv/vpp

RUN apt-get remove -y \
    make \
    git \
    cpp \
    gcc \
    rdma-core \
    nasm \
    python-pexpect

WORKDIR /root

CMD ["/usr/bin/vpp", "-c", "/etc/vpp/startup.conf"]
