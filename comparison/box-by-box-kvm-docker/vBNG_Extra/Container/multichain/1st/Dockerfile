FROM ubuntu:xenial

COPY . /vBNG
WORKDIR /vBNG

CMD tail -f /dev/null

RUN chmod +x cnf_vbng_install.sh
RUN ./cnf_vbng_install.sh

#RUN chmod +x cnf_vdnsgen_init.sh
