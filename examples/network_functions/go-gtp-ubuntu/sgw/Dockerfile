FROM ubuntu:18.04 
RUN apt-get update && apt-get --no-install-recommends install -y apt-utils ca-certificates \
    software-properties-common
RUN add-apt-repository ppa:longsleep/golang-backports
RUN apt-get update && apt-get --no-install-recommends install -y \
    git \
    golang-1.14 \
    iproute2
ENV GOPATH="/opt/go"
ENV PATH="${PATH}:${GOPATH}/bin:/usr/lib/go-1.14/bin"
RUN go get github.com/wmnsk/go-gtp/examples/gw-tester/sgw
RUN apt-get remove -y git software-properties-common
COPY ./sgw_default.yml /etc/sgw.yml
ENTRYPOINT ["sgw", "-config", "/etc/sgw.yml"]
