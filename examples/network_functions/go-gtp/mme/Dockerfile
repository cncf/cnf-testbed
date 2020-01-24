FROM golang:alpine
RUN apk --no-cache add git
RUN go get github.com/wmnsk/go-gtp/examples/gw-tester/mme
ADD ["./mme_default.yml","/root/mme.yml"]
RUN apk del git
WORKDIR /root/
