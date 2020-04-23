FROM golang:1.14-alpine3.11 as builder

RUN apk --no-cache add git
RUN go get -v github.com/wmnsk/go-gtp/examples/gw-tester/enb
RUN go get -v github.com/wmnsk/go-gtp/examples/gw-tester/mme
RUN go get -v github.com/wmnsk/go-gtp/examples/gw-tester/pgw
RUN go get -v github.com/wmnsk/go-gtp/examples/gw-tester/sgw

FROM alpine:3.11

COPY --from=builder /go/bin/enb /usr/local/bin/
COPY --from=builder /go/bin/mme /usr/local/bin/
COPY --from=builder /go/bin/pgw /usr/local/bin/
COPY --from=builder /go/bin/sgw /usr/local/bin/
COPY ./enb/enb_default.yml /etc/enb.yml
COPY ./mme/mme_default.yml /etc/mme.yml
COPY ./pgw/pgw_default.yml /etc/pgw.yml
COPY ./sgw/sgw_default.yml /etc/sgw.yml
