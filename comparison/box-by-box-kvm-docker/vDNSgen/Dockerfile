FROM ubuntu:xenial

COPY . /vDNSgen
WORKDIR /vDNSgen

RUN apt-get update
RUN apt-get --no-install-recommends install -y apt-utils ca-certificates lshw pciutils net-tools iproute bsdmainutils

CMD tail -f /dev/null

RUN chmod +x cnf_vdnsgen_install.sh
RUN ./cnf_vdnsgen_install.sh

RUN chmod +x cnf_vdnsgen_init.sh
