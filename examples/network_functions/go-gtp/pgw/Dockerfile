FROM golang:alpine
RUN apk --no-cache add git bash gettext
RUN go get github.com/wmnsk/go-gtp/examples/gw-tester/pgw
ADD ["./pgw_default.yml","/root/pgw.yml"]
RUN apk del git
WORKDIR /root/
