FROM buildpack-deps:18.04-scm as builder

RUN apt update \
    && apt upgrade -y \
    && apt install -y gcc make

ENV TCL_VERSION 8.6.8
ENV TCL_PATH tcl${TCL_VERSION}
RUN mkdir /tmp/tcl \
    && curl -sL -o /tmp/tcl/tcl.tar.gz https://prdownloads.sourceforge.net/tcl/${TCL_PATH}-src.tar.gz \
    && cd /tmp/tcl \
    && tar -xzf /tmp/tcl/tcl.tar.gz \
    && cd /tmp/tcl/${TCL_PATH}/unix \
    && ./configure \
    && make \
    && make test \
    && make install

ENV GOSU_VERSION 1.10
RUN curl -sL -o /tmp/gosu https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64; \
    curl -sL -o /tmp/gosu.asc https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64.asc; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
    gpg --batch --verify /tmp/gosu.asc /tmp/gosu; \
    chmod 755 /tmp/gosu; \
    /tmp/gosu nobody true

ENV REDIS_VERSION 5.0-rc3
ENV REDIS_PATH redis-${REDIS_VERSION}
RUN mkdir /tmp/redis \
    && curl -sL -o /tmp/redis/redis.tar.gz https://github.com/antirez/redis/archive/${REDIS_VERSION}.tar.gz \
    && cd /tmp/redis \
    && tar -xzf /tmp/redis/redis.tar.gz \
    && cd /tmp/redis/${REDIS_PATH} \
    && make V=1 CFLAGS="--static" EXEEXT="--static" LDFLAGS="-I/usr/local/include/" \
    && make test

FROM debian:jessie-slim

ENV REDIS_VERSION 5.0-rc3
COPY --from=builder /tmp/gosu /usr/local/bin/gosu
COPY --from=builder /tmp/redis/redis-${REDIS_VERSION}/src/redis-benchmark /usr/local/bin/redis-benchmark
COPY --from=builder /tmp/redis/redis-${REDIS_VERSION}/src/redis-check-aof /usr/local/bin/redis-check-aof
COPY --from=builder /tmp/redis/redis-${REDIS_VERSION}/src/redis-check-rdb /usr/local/bin/redis-check-rdb
COPY --from=builder /tmp/redis/redis-${REDIS_VERSION}/src/redis-cli /usr/local/bin/redis-cli
COPY --from=builder /tmp/redis/redis-${REDIS_VERSION}/src/redis-sentinel /usr/local/bin/redis-sentinel
COPY --from=builder /tmp/redis/redis-${REDIS_VERSION}/src/redis-server /usr/local/bin/redis-server
COPY --from=builder /tmp/redis/redis-${REDIS_VERSION}/redis.conf /etc/redis/redis.conf
COPY --from=builder /tmp/redis/redis-${REDIS_VERSION}/sentinel.conf /etc/redis/sentinel.conf

RUN groupadd -r redis && useradd -r -g redis redis \
    && mkdir /data \
    && chown redis:redis /data
VOLUME ["/data"]
WORKDIR /data

COPY docker-entrypoint.sh /usr/local/bin
ENTRYPOINT [ "/usr/local/bin/docker-entrypoint.sh" ]

EXPOSE 6379
CMD [ "redis-server" ]