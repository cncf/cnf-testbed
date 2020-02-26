FROM ubuntu:18.04 
RUN apt update && apt install -y \
    software-properties-common
RUN add-apt-repository ppa:longsleep/golang-backports
RUN apt update && apt install -y \
    golang-go \
    git \
    iproute2
ENV GOCACHE="/opt/.cache/go-build"
ENV GOENV="/opt/.config/go/env"
ENV GOPATH="/opt/go"
ENV PATH="${PATH}:${GOPATH}/bin"
RUN go get github.com/wmnsk/go-gtp/examples/gw-tester/sgw
ADD ["./sgw_default.yml","/root/sgw.yml"]
RUN apt remove -y git \
    software-properties-common
WORKDIR /root/
