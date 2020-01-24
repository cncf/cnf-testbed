FROM golang:alpine
RUN apk --no-cache add git
RUN go get github.com/wmnsk/go-gtp/examples/gw-tester/sgw
ADD ["./sgw_default.yml","/root/sgw.yml"]
RUN apk del git
WORKDIR /root/
