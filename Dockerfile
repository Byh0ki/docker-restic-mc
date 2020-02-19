FROM golang:1.13-alpine AS builder

ARG MINIO_CLIENT_VERSION="RELEASE.2020-02-14T19-35-50Z"
ARG RESTIC_VERSION="0.9.6"
ARG RESTIC_SHA256="1cc8655fa99f06e787871a9f8b5ceec283c856fa341a5b38824a0ca89420b0fe"

ENV GOPATH /go
ENV CGO_ENABLED 0
ENV GO111MODULE on

RUN set -e \
 && apk add --update --no-cache ca-certificates curl \
 && curl -sL -o mc.tar.gz https://github.com/minio/mc/archive/${MINIO_CLIENT_VERSION}.tar.gz \
 && tar xzf mc.tar.gz \
 && cd mc-${MINIO_CLIENT_VERSION} \
 && go install -v -ldflags "$(go run buildscripts/gen-ldflags.go)"

RUN curl -sL -o restic.tar.gz https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic-${RESTIC_VERSION}.tar.gz \
 && echo "${RESTIC_SHA256}  restic.tar.gz" | sha256sum -c - \
 && tar xzf restic.tar.gz \
 && cd restic-${RESTIC_VERSION} \
 && go run build.go \
 && mv restic /usr/local/bin/restic \
 && cd .. \
 && rm restic.tar.gz restic-${RESTIC_VERSION} -fR

FROM alpine:3.11.3

RUN set -e \
    && apk add --update --no-cache ca-certificates fuse openssh-client

COPY --from=builder /usr/local/bin/restic /usr/local/bin/restic

COPY --from=builder /go/bin/mc /usr/local/bin/mc

VOLUME /data

ENTRYPOINT ["/usr/local/bin/restic"]
