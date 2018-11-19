FROM ubuntu:xenial

COPY base/ /vEdge
WORKDIR /vEdge

CMD tail -f /dev/null

RUN touch in_container
RUN chmod +x cnf_vedge_base_install.sh
RUN ./cnf_vedge_base_install.sh
