FROM ubuntu:bionic

COPY base/ /vEdge
WORKDIR /vEdge

CMD mkdir ~/sockets
CMD tail -f /dev/null

RUN apt-get update -y && \
    apt-get install --allow-unauthenticated -y \
        make \
        gcc \
        libcurl4-openssl-dev \
        python-pip \
        bridge-utils \
        apt-transport-https \
        ca-certificates \
        vim \
        curl && \
    pip install jsonschema

RUN curl -s https://packagecloud.io/install/repositories/fdio/release/script.deb.sh | bash

RUN apt-get install -y \
        vpp=18.10-release \
        vpp-dbg=18.10-release\
        vpp-dev=18.10-release\
        vpp-lib=18.10-release\
        vpp-plugins=18.10-release

RUN touch in_container
