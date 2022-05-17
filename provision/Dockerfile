FROM hashicorp/terraform:1.1.9

# NOTE (jpd): ansible install based in willian yeh install
# https://github.com/William-Yeh/docker-ansible/blob/e1cb5d4aec1da7286717bdbe08ce891f53154a47/alpine3/Dockerfile

ENV DO_VERSION 20.10.16
ENV DO_URL https://download.docker.com/linux/static/stable/x86_64/docker-${DO_VERSION}.tgz
ENV DC_VERSION v2.5.0
ENV DC_URL https://github.com/docker/compose/releases/download/${DC_VERSION}/docker-compose-linux-x86_64
ENV ANSIBLE_VERSION 5.7.1
ENV ANSIBLE_LINT_VERSION 6.1.0

RUN echo "install system deps " \
    && apk --update add curl \
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
    && apk --update add sudo \
    && apk --update add python3 py3-pip openssl ca-certificates \
    && apk --update add --virtual \
        build-dependencies \
        python3-dev \
        libffi-dev \
        openssl-dev \
        build-base \
        cargo \
    && pip3 install --upgrade pip cffi \
    && pip3 install --upgrade ansible==${ANSIBLE_VERSION} \
    && pip3 install --upgrade ansible-lint==${ANSIBLE_LINT_VERSION} \
    && pip3 install --upgrade pycrypt pywinrm \
    && apk --update add sshpass openssh-client rsync \
    && mkdir -p /etc/ansible \
    && echo "localhost" > /etc/ansible/hosts \
    && apk del build-dependencies \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/*

VOLUME [ "/root/.ansible" ]
VOLUME [ "/root/.docker" ]
