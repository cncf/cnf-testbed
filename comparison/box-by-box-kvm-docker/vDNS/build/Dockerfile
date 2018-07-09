FROM ubuntu:xenial

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
COPY . /build
WORKDIR /build

RUN chmod +x ./v_dns_install.sh
RUN chmod +x ./v_dns_init.sh
RUN ./v_dns_install.sh
#RUN ./v_dns_init.sh
RUN update-rc.d -f v_dns.sh remove
RUN update-rc.d -f bind9 remove

RUN mkdir -p /opt/sbin
COPY entrypoint.sh /opt/sbin/
RUN chmod +x /opt/sbin/entrypoint.sh

EXPOSE 53 53/udp
ENTRYPOINT ["/opt/sbin/entrypoint.sh"]
CMD ["/usr/sbin/named", "-u", "bind",  "-f", "-g"]
