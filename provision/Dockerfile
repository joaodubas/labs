FROM hashicorp/terraform:1.8.3

# NOTE (jpd): ansible install based in willian yeh install
# https://github.com/William-Yeh/docker-ansible/blob/e1cb5d4aec1da7286717bdbe08ce891f53154a47/alpine3/Dockerfile

ENV DO_VERSION 27.0.3
ENV DO_URL https://download.docker.com/linux/static/stable/x86_64/docker-${DO_VERSION}.tgz
ENV DC_VERSION v2.29.0
ENV DC_URL https://github.com/docker/compose/releases/download/${DC_VERSION}/docker-compose-linux-x86_64
ENV ANSIBLE_CORE_VERSION 2.17.2
ENV ANSIBLE_VERSION 10.2.0

RUN echo "install system deps " \
    && apk --update add curl sudo openssl ca-certificates sshpass openssh-client rsync \
    && echo "install docker ..." \
    && mkdir -p /tmp/download \
    && curl -L ${DO_URL} | tar -xz -C /tmp/download \
    && mv /tmp/download/docker/* /usr/local/bin \
    && rm -rf /tmp/download \
    && echo "install docker-compose..." \
    && mkdir -p /usr/local/lib/docker/cli-plugins \
    && curl -L ${DC_URL} -o /usr/local/lib/docker/cli-plugins/docker-compose \
    && chmod 755 /usr/local/lib/docker/cli-plugins/docker-compose \
    && echo "install ansible ..." \
    && apk --update add \
        --repository=http://dl-cdn.alpinelinux.org/alpine/v3.17/main \
        --repository=http://dl-cdn.alpinelinux.org/alpine/v3.17/community \
        python3=3.10.13-r0 \
        python3-dev=3.10.13-r0 \
        py3-pip=22.3.1-r1 \
    && apk --update add --virtual \
        build-dependencies \
        libffi-dev \
        openssl-dev \
        build-base \
        cargo \
    && pip3 install --upgrade pip cffi \
    && pip3 install --upgrade ansible-core==${ANSIBLE_CORE_VERSION} \
    && pip3 install --upgrade ansible==${ANSIBLE_VERSION} \
    && pip3 install --upgrade pycrypt pywinrm \
    && mkdir -p /etc/ansible \
    && echo "localhost" > /etc/ansible/hosts \
    && apk del build-dependencies \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/*

VOLUME [ "/root/.ansible" ]
VOLUME [ "/root/.docker" ]
