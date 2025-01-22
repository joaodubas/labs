FROM hashicorp/terraform:1.9.8 AS provision
ENV DO_VERSION=27.3.1
ENV DO_URL=https://download.docker.com/linux/static/stable/x86_64/docker-${DO_VERSION}.tgz
ENV DC_VERSION=v2.29.7
ENV DC_URL=https://github.com/docker/compose/releases/download/${DC_VERSION}/docker-compose-linux-x86_64
RUN echo 'install system deps...' \
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
  && echo 'install docker...' \
  && mkdir -p /tmp/download \
  && curl -L ${DO_URL} | tar -xz -C /tmp/download \
  && mv /tmp/download/docker/* /usr/local/bin \
  && rm -rf /tmp/download \
  && echo 'install docker-compose...' \
  && mkdir -p /usr/local/lib/docker/cli-plugins \
  && curl -L ${DC_URL} -o /usr/local/lib/docker/cli-plugins/docker-compose \
  && chmod 755 /usr/local/lib/docker/cli-plugins/docker-compose \
  && echo 'configure ansible...' \
  && mkdir -p /etc/ansible \
  && echo "localhost" > /etc/ansible/hosts \
  && echo 'clean-up...' \
  && rm -rf /var/cache/apk/* \
  && rm -rf /tmp/*
VOLUME [ "/root/.ansible", "/root/.docker" ]

FROM ubuntu:24.04 AS playground
ARG DOCKER_GID=999
ARG UID=1000
ARG GID=1000
RUN echo 'remove existing ubuntu user' \
  && groupdel --force ubuntu \
  && userdel --force ubuntu \
  && echo 'setup extra groups' \
  && groupadd --gid ${DOCKER_GID} docker \
  && echo 'install system dependencies' \
  && apt-get update \
  && apt-get install -y software-properties-common \
  && add-apt-repository ppa:ansible/ansible \
  && apt-get update \
  && apt-get install -y \
    ansible \
    curl \
    sudo \
  && echo 'install comtrya' \
  && curl -fsSL https://get.comtrya.dev | sh \
  && echo 'setup playground user' \
  && groupadd --gid ${GID} playground \
  && useradd \
    --uid ${UID} \
    --gid playground \
    --groups docker,sudo \
    --home-dir /home/playground \
    --shell /usr/bin/bash \
    --create-home \
    playground \
  && echo 'playground:playground' | chpasswd \
  && echo 'playground ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/10-playground
USER playground
ENTRYPOINT ["sleep"]
CMD ["infinity"]

FROM nixos/nix:2.24.9 AS devbox
# ARG UID=1000
# ARG GID=1000
# RUN groupadd --gid ${GID} devbox \
#   && useradd \
#     --uid ${UID} \
#     --gid devbox \
#     --home-dir /home/devbox \
#     --shell /usr/bin/bash \
#     --create-home \
#     devbox
# USER devbox
ARG DEVBOX_VERSION=0.13.5
ENV DEVBOX_USE_VERSION=${DEVBOX_VERSION}
RUN nix-channel --update \
  && nix-env -iA nixpkgs.devbox
