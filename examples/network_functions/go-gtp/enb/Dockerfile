FROM golang:alpine
RUN apk --no-cache add git
RUN go get github.com/wmnsk/go-gtp/examples/gw-tester/enb
ADD ["./enb_default.yml","/root/enb.yml"]
RUN apk del git
WORKDIR /root/
