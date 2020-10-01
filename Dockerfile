FROM golang:1.15.2-alpine3.12 AS builder

ARG RESTIC_VERSION="0.10.0"
ARG RESTIC_SHA256="067fbc0cf0eee4afdc361e12bd03b266e80e85a726647e53709854ec142dd94e"

RUN apk add --update --no-cache ca-certificates curl

RUN curl -sL -o restic.tar.gz https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic-${RESTIC_VERSION}.tar.gz \
 && echo "${RESTIC_SHA256}  restic.tar.gz" | sha256sum -c - \
 && tar xzf restic.tar.gz \
 && cd restic-${RESTIC_VERSION} \
 && go run build.go \
 && mv restic /usr/local/bin/restic \
 && cd .. \
 && rm restic.tar.gz restic-${RESTIC_VERSION} -fR

FROM alpine:3.12.0

RUN apk add --update --no-cache ca-certificates fuse openssh-client bash

COPY --from=builder /usr/local/bin/restic /usr/local/bin/restic

VOLUME /data

ENTRYPOINT ["/usr/local/bin/restic"]
