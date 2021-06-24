FROM hashicorp/terraform:1.0.0

# NOTE (jpd): ansible install based in willian yeh install
# https://github.com/William-Yeh/docker-ansible/blob/e1cb5d4aec1da7286717bdbe08ce891f53154a47/alpine3/Dockerfile

ENV DM_VERSION=v0.16.2
ENV DM_RELEASE=docker-machine-Linux-x86_64
ENV DM_BASE_URL=https://github.com/docker/machine/releases/download/${DM_VERSION}
ENV DM_URL=${DM_BASE_URL}/${DM_RELEASE}
ENV DO_VERSION=20.10.7
ENV DO_URL=https://download.docker.com/linux/static/stable/x86_64/docker-${DO_VERSION}.tgz
ENV DC_VERSION=1.29.2
ENV DC_URL=https://github.com/docker/compose/releases/download/${DC_VERSION}/docker-compose-Linux-x86_64
ENV ANSIBLE_VERSION=4.1.0

RUN echo "install system deps " \
    && apk --update add curl \
    && echo "install docker ..." \
    && mkdir -p /tmp/download \
    && curl -L ${DO_URL} | tar -xz -C /tmp/download \
    && mv /tmp/download/docker/* /usr/local/bin \
    && rm -rf /tmp/download \
    && echo "install docker-compose..." \
    && curl -L ${DC_URL} -o /usr/local/bin/docker-compose \
    && chmod 755 /usr/local/bin/docker-compose \
    && echo "install docker-machine ..." \
    && curl -L ${DM_URL} -o /usr/local/bin/docker-machine \
    && chmod 755 /usr/local/bin/docker-machine \
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
    && pip3 install --upgrade pycrypt pywinrm \
    && apk --update add sshpass openssh-client rsync \
    && mkdir -p /etc/ansible \
    && echo "localhost" > /etc/ansible/hosts \
    && apk del build-dependencies \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/*

VOLUME [ "/root/.ansible" ]
VOLUME [ "/root/.docker" ]
