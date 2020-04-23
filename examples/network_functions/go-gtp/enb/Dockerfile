FROM golang:1.14-alpine3.11 as builder

RUN apk --no-cache add git
RUN go get -v github.com/wmnsk/go-gtp/examples/gw-tester/enb

FROM alpine:3.11

COPY --from=builder /go/bin/enb /usr/local/bin/
COPY ./enb_default.yml /etc/enb.yml

ENTRYPOINT ["/usr/local/bin/enb", "-config", "/etc/enb.yml"]
