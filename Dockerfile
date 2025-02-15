FROM debian:bullseye-slim AS builder

ARG TAG
ARG REPOSITORY

RUN apt update && apt install -y git make gcc libssl-dev

WORKDIR /root

RUN ARCH=$(dpkg --print-architecture) \
    && case "$ARCH" in \
    "amd64") \
        BUILD_TARGET="x86-64" \
        ;; \
    "arm64") \
        BUILD_TARGET="arm64" \
        ;; \
    *) \
        echo "Doesn't support $ARCH architecture" \
        exit 1 \
        ;; \
    esac \
    && git clone https://github.com/${REPOSITORY} smartdns \
    && cd smartdns \
    && git fetch --all --tags \
    && git checkout tags/${TAG} \
    && sh package/build-pkg.sh --platform linux --arch $BUILD_TARGET --static \
    && strip -s src/smartdns && cp src/smartdns /usr/bin

FROM alpine:latest

COPY --from=builder /usr/bin/smartdns /usr/bin/smartdns

ENV TZ Asia/Shanghai

RUN apk update --no-cache && apk add --no-cache tzdata ca-certificates curl && apk upgrade --no-cache

WORKDIR /root
ADD smartdns.conf /root
ADD init_rules.sh /root
ADD entrypoint.sh /root
RUN chmod a+x /root/init_rules.sh && \
    chmod a+x /root/entrypoint.sh && \
    sh /root/init_rules.sh

VOLUME /etc/smartdns
WORKDIR /etc/smartdns

EXPOSE 53/udp 
EXPOSE 53/tcp

ENTRYPOINT ["/root/entrypoint.sh"]
