FROM ubuntu:18.04
RUN apt-get update && apt-get install -y software-properties-common \
    --no-install-recommends
RUN add-apt-repository ppa:longsleep/golang-backports
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    golang-1.14 \
    iproute2
ENV GOPATH="/opt/go"
ENV PATH="${PATH}:${GOPATH}/bin:/usr/lib/go-1.14/bin"
RUN go get github.com/wmnsk/go-gtp/examples/gw-tester/enb
RUN go get github.com/wmnsk/go-gtp/examples/gw-tester/mme
RUN go get github.com/wmnsk/go-gtp/examples/gw-tester/pgw
RUN go get github.com/wmnsk/go-gtp/examples/gw-tester/sgw
RUN apt-get remove -y git software-properties-common
COPY ./enb/enb_default.yml /etc/enb.yml
COPY ./mme/mme_default.yml /etc/mme.yml
COPY ./sgw/sgw_default.yml /etc/sgw.yml
COPY ./pgw/pgw_default.yml /etc/pgw.yml
