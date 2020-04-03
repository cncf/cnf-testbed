FROM golang:1.14-alpine3.11 as builder

RUN apk --no-cache add git
RUN go get -v github.com/wmnsk/go-gtp/examples/gw-tester/sgw

FROM alpine:3.11

COPY --from=builder /go/bin/sgw /usr/local/bin/
COPY ./sgw_default.yml /etc/sgw.yml

ENTRYPOINT ["/usr/local/bin/sgw", "-config", "/etc/sgw.yml"]
