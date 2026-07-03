FROM hashicorp/terraform:1.14.8

# NOTE (jpd): ansible install based in willian yeh install
# https://github.com/William-Yeh/docker-ansible/blob/e1cb5d4aec1da7286717bdbe08ce891f53154a47/alpine3/Dockerfile

ENV DO_VERSION 29.4.0
ENV DO_URL https://download.docker.com/linux/static/stable/x86_64/docker-${DO_VERSION}.tgz
ENV DC_VERSION v5.1.2
ENV DC_URL https://github.com/docker/compose/releases/download/${DC_VERSION}/docker-compose-linux-x86_64
ENV ANSIBLE_CORE_VERSION 2.20.4
ENV ANSIBLE_VERSION 13.5.0

RUN echo "install system deps " \
    && apk --update add curl sudo openssl ca-certificates sshpass openssh-client rsync
RUN echo "install docker ..." \
    && mkdir -p /tmp/download \
    && curl -L ${DO_URL} | tar -xz -C /tmp/download \
    && mv /tmp/download/docker/* /usr/local/bin \
    && rm -rf /tmp/download \
    && echo "install docker-compose..." \
    && mkdir -p /usr/local/lib/docker/cli-plugins \
    && curl -L ${DC_URL} -o /usr/local/lib/docker/cli-plugins/docker-compose \
    && chmod 755 /usr/local/lib/docker/cli-plugins/docker-compose
RUN echo "install python..." \
    && apk --update add \
        python3=3.12.13-r0 \
        python3-dev=3.12.13-r0 \
        py3-pip=25.1.1-r1 \
    && apk --update add --virtual \
        build-dependencies \
        libffi-dev \
        openssl-dev \
        build-base \
        cargo
RUN echo "install ansible..." \
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
