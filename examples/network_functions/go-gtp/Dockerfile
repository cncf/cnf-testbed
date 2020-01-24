FROM golang:alpine
RUN apk --no-cache add git
RUN go get github.com/wmnsk/go-gtp/examples/gw-tester/enb
RUN go get github.com/wmnsk/go-gtp/examples/gw-tester/mme
RUN go get github.com/wmnsk/go-gtp/examples/gw-tester/pgw
RUN go get github.com/wmnsk/go-gtp/examples/gw-tester/sgw
ADD ["enb/enb_default.yml","/root/enb.yml"]
ADD ["mme/mme_default.yml","/root/mme.yml"]
ADD ["pgw/pgw_default.yml","/root/pgw.yml"]
ADD ["sgw/sgw_default.yml","/root/sgw.yml"]
RUN apk del git
WORKDIR /root/
