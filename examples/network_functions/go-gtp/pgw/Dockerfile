FROM golang:1.14-alpine3.11 as builder

RUN apk --no-cache add git
RUN go get -v github.com/wmnsk/go-gtp/examples/gw-tester/pgw

FROM alpine:3.11

COPY --from=builder /go/bin/pgw /usr/local/bin/
COPY ./pgw_default.yml /etc/pgw.yml

ENTRYPOINT ["/usr/local/bin/pgw", "-config", "/etc/pgw.yml"]
