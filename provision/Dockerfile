FROM hashicorp/terraform:0.12.24

# NOTE (jpd): ansible install based in willian yeh install
# https://github.com/William-Yeh/docker-ansible/blob/e1cb5d4aec1da7286717bdbe08ce891f53154a47/alpine3/Dockerfile

ENV DM_VERSION=v0.16.2
ENV DM_RELEASE=docker-machine-Linux-x86_64
ENV DM_BASE_URL=https://github.com/docker/machine/releases/download/${DM_VERSION}
ENV DM_URL=${DM_BASE_URL}/${DM_RELEASE}
ENV DC_VERSION=19.03.9
ENV DC_URL=https://download.docker.com/linux/static/stable/x86_64/docker-${DC_VERSION}.tgz

RUN echo "install docker-machine ... " \
    && apk --update add curl \
    && mkdir -p /tmp/download \
    && curl -L ${DC_URL} | tar -xz -C /tmp/download \
    && mv /tmp/download/docker/* /usr/local/bin \
    && rm -rf /tmp/download \
    && curl -L ${DM_URL} -o /usr/local/bin/docker-machine \
    && chmod 755 /usr/local/bin/docker-machine \
    && echo "install ansible ..." \
    && apk --update add sudo \
    && apk --update add python py-pip openssl ca-certificates \
    && apk --update add --virtual \
        build-dependencies \
        python-dev \
        libffi-dev \
        openssl-dev \
        build-base \
    && pip install --upgrade pip cffi \
    && pip install --upgrade ansible==2.9.4 \
    && pip install --upgrade pycrypt pywinrm \
    && apk --update add sshpass openssh-client rsync \
    && mkdir -p /etc/ansible \
    && echo "localhost" > /etc/ansible/hosts \
    && apk del build-dependencies \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/*

VOLUME [ "/root/.ansible" ]
VOLUME [ "/root/.docker" ]
