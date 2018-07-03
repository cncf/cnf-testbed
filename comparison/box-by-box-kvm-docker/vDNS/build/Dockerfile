FROM ubuntu:xenial

RUN apt-get update
COPY . /build
WORKDIR /build

RUN chmod +x ./v_dns_install.sh
RUN ./v_dns_install.sh
