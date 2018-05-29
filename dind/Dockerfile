FROM docker:18.04.0-ce-dind
RUN set -ex; \
    apk update; \
    apk add --no-cache --virtual bash; \
    apk add --no-cache --virtual zsh; \
    apk add --no-cache --virtual git

RUN set -ex; \
    apk add --no-cache --virtual python3; \
    apk add --no-cache --virtual postgresql; \
    apk add --no-cache --virtual curl; \
    apk add --no-cache --virtual ruby