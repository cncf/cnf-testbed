FROM golang:1.14-alpine3.11 as builder

RUN apk --no-cache add git
RUN go get -v github.com/wmnsk/go-gtp/examples/gw-tester/mme

FROM alpine:3.11

COPY --from=builder /go/bin/mme /usr/local/bin/
COPY ./mme_default.yml /etc/mme.yml

ENTRYPOINT ["/usr/local/bin/mme", "-config", "/etc/mme.yml"]
