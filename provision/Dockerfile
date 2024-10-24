FROM hashicorp/terraform:1.9.8 AS provision

ENV DO_VERSION=27.3.1
ENV DO_URL=https://download.docker.com/linux/static/stable/x86_64/docker-${DO_VERSION}.tgz
ENV DC_VERSION=v2.29.7
ENV DC_URL=https://github.com/docker/compose/releases/download/${DC_VERSION}/docker-compose-linux-x86_64

RUN echo "install system deps..." \
    && apk --update add \
      ansible-core \
      ansible \
      curl \
      sudo \
      openssl \
      ca-certificates \
      sshpass \
      openssh-client \
      rsync \
    && echo "install docker..." \
    && mkdir -p /tmp/download \
    && curl -L ${DO_URL} | tar -xz -C /tmp/download \
    && mv /tmp/download/docker/* /usr/local/bin \
    && rm -rf /tmp/download \
    && echo "install docker-compose..." \
    && mkdir -p /usr/local/lib/docker/cli-plugins \
    && curl -L ${DC_URL} -o /usr/local/lib/docker/cli-plugins/docker-compose \
    && chmod 755 /usr/local/lib/docker/cli-plugins/docker-compose \
    && echo "configure ansible..." \
    && mkdir -p /etc/ansible \
    && echo "localhost" > /etc/ansible/hosts \
    && echo "clean-up..." \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/*

VOLUME [ "/root/.ansible", "/root/.docker" ]
