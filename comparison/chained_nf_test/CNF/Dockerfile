FROM ubuntu:xenial

COPY . /vEdge
WORKDIR /vEdge

CMD tail -f /dev/null

RUN chmod +x cnf_vedge_install.sh
RUN ./cnf_vedge_install.sh
