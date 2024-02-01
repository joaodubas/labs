FROM ubuntu:22.04 AS base

# install system deps
ARG USER_UID=1000
ARG USER_GID=1000
ARG DOCKER_GID=999
ARG WHEEL_GID=980
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
  && apt-get install -y software-properties-common \
  && add-apt-repository ppa:fish-shell/release-3 \
  && add-apt-repository ppa:neovim-ppa/unstable \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    autoconf \
    automake \
    bsdmainutils \
    build-essential \
    ca-certificates \
    curl \
    dirmngr \
    doas \
    fish \
    g++ \
    gcc \
    gfortran \
    git \
    gosu \
    gpg \
    gpg-agent \
    groff \
    jq \
    less \
    libbz2-1.0 \
    libbz2-dev \
    libc6-dev \
    libcurl3-dev \
    libffi-dev \
    liblzma-dev \
    liblzma5 \
    libncurses-dev \
    libncurses5-dev \
    libncursesw5-dev \
    libodbc1 \
    libpcre2-dev \
    libreadline-dev \
    libsctp-dev \
    libsctp1 \
    libsqlite3-dev \
    libssl-dev \
    libtool \
    libwxgtk3.0-gtk3-0v5 \
    libwxgtk3.0-gtk3-dev \
    libxslt-dev \
    libyaml-dev \
    llvm \
    locales \
    make \
    neovim \
    net-tools \
    openssh-client \
    openssl \
    parallel \
    pkg-config \
    python3-openssl \
    sudo \
    tk-dev \
    tmux \
    tmuxp \
    unixodbc-dev \
    unzip \
    uuid-dev \
    wget \
    xorg-dev \
    xz-utils \
    zlib1g-dev \
  && rm -rf /var/lib/apt/lists/* \
  && locale-gen en_US.UTF-8 \
  && echo 'setup unprivileged user' \
  && groupadd --gid ${WHEEL_GID} wheel \
  && groupadd --gid ${DOCKER_GID} docker \
  && groupadd --gid ${USER_GID} coder \
  && useradd \
    --uid ${USER_UID} \
    --gid coder \
    --groups docker,wheel \
    --shell $(which fish) \
    --home-dir /home/coder \
    --create-home \
    coder \
  && echo 'coder:coder' | chpasswd \
  && echo 'permit persist :wheel as root' > /etc/doas.conf

# global command line utilities
ENV DO_VERSION 24.0.7
ENV DO_URL https://download.docker.com/linux/static/stable/x86_64/docker-${DO_VERSION}.tgz
ENV DC_VERSION v2.23.3
ENV DC_URL https://github.com/docker/compose/releases/download/${DC_VERSION}/docker-compose-linux-x86_64
ENV GRPC_VERSION 22.3
ENV GRPC_PATH protoc-${GRPC_VERSION}-linux-x86_64
ENV GRPC_FILE ${GRPC_PATH}.zip
ENV GRPC_URL https://github.com/protocolbuffers/protobuf/releases/download/v${GRPC_VERSION}/${GRPC_FILE}
ENV EXERCISM_VERSION 3.1.0
ENV EXERCISM_FILE  exercism-${EXERCISM_VERSION}-linux-x86_64.tar.gz
ENV EXERCISM_URL https://github.com/exercism/cli/releases/download/v${EXERCISM_VERSION}/${EXERCISM_FILE}
RUN echo 'setup starship' \
  && curl -sS https://starship.rs/install.sh | sh -s -- --yes \
  && echo 'setup grpc' \
  && curl -LO ${GRPC_URL} \
  && unzip ${GRPC_FILE} -d /opt/${GRPC_PATH} \
  && ln -s /opt/${GRPC_PATH}/bin/protoc /usr/local/bin/ \
  && cp --recursive /opt/${GRPC_PATH}/include/google /usr/local/include \
  && chmod --recursive 755 /opt/${GRPC_PATH}/bin \
  && chmod --recursive o+r /usr/local/include \
  && rm ${GRPC_FILE} \
  && echo 'setup docker' \
  && mkdir /tmp/download \
  && curl -L ${DO_URL} | tar -zx -C /tmp/download \
  && chgrp --recursive docker /tmp/download \
  && mv /tmp/download/docker/* /usr/local/bin \
  && rm -rf /tmp/download \
  && echo 'setup docker compose' \
  && mkdir -p /usr/local/lib/docker/cli-plugins \
  && curl -L ${DC_URL} -o /usr/local/lib/docker/cli-plugins/docker-compose \
  && chmod 750 /usr/local/lib/docker/cli-plugins/docker-compose \
  && chgrp --recursive docker /usr/local/lib/docker \
  && echo 'setup exercism' \
  && mkdir /tmp/download \
  && curl -L -XGET ${EXERCISM_URL} | tar -xz -C /tmp/download \
  && mv /tmp/download/exercism /usr/local/bin \
  && rm -rf /tmp/download

USER coder
WORKDIR /home/coder

ENV LANGUAGE en_US.UTF-8
ENV LANG ${LANGAGUE}
ENV LC_ALL ${LANGUAGE}
ENV HOME /home/coder
ENV LOCAL_BIN_HOME ${HOME}/.local/bin
ENV LOCAL_SRC_HOME ${HOME}/.local/src
ENV XDG_CONFIG_HOME ${HOME}/.config
ENV XDG_DATA_HOME ${HOME}/.local/share
ENV XDG_CACHE_HOME ${HOME}/.cache
ENV STARSHIP_CONFIG ${XDG_CONFIG_HOME}/starship/config.toml
ENV PATH ${LOCAL_BIN_HOME}:$PATH

# command line utilities
RUN curl https://mise.jdx.dev/install.sh | sh \
  && curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash \
  && git clone https://github.com/tmux-plugins/tpm.git ${XDG_CONFIG_HOME}/tmux/plugins/tpm

# git configuration
COPY ./scripts/patch/kickstart.nvim/updates.patch /tmp
COPY ./config/nvim/lua/custom/plugins/init.lua /tmp
RUN git clone https://github.com/nvim-lua/kickstart.nvim.git "${XDG_CONFIG_HOME}"/nvim \
  && cd ${XDG_CONFIG_HOME}/nvim \
  && git reset --hard b11581491671ed49b1dfdb1ea777932ade7ff2e5 \
  && git apply /tmp/updates.patch \
  && cp /tmp/init.lua ${XDG_CONFIG_HOME}/nvim/lua/custom/plugins \
  && nvim --headless "+Lazy! sync" +qa

# install rtx plugins
RUN ${LOCAL_BIN_HOME}/mise plugins install --force --yes \
    awscli \
    bat \
    dagger \
    elixir \
    erlang \
    eza \
    fzf \
    helm \
    k3d \
    kubectl \
    kubie \
    lefthook \
    poetry \
    ripgrep \
    starship \
    terraform \
    tilt \
    tmux \
    usql \
    yarn \
    zoxide

# configure golang
ENV GOPATH ${XDG_DATA_HOME}/go
ENV PATH ${GOPATH}/bin:/usr/local/bin:${PATH}
RUN mkdir -p "${GOPATH}/src" "${GOPATH}/bin" \
  && chmod -R 777 "${GOPATH}"

# configure fish and bash
RUN fish -c true \
  && echo 'starship init fish | source' >> ${XDG_CONFIG_HOME}/fish/config.fish \
  && echo '{$LOCAL_BIN_HOME}/mise activate fish | source' >> ${XDG_CONFIG_HOME}/fish/config.fish \
  && echo 'zoxide init fish | source' >> ${XDG_CONFIG_HOME}/fish/config.fish \
  && echo 'alias cat="bat"' >> ${XDG_CONFIG_HOME}/fish/config.fish \
  && echo 'alias l="eza --time-style long-iso --color=auto -F"' >> ${XDG_CONFIG_HOME}/fish/config.fish \
  && echo 'alias ll="l -Fahl"' >> ${XDG_CONFIG_HOME}/fish/config.fish \
  && echo 'alias la="l -a"' >> ${XDG_CONFIG_HOME}/fish/config.fish

# configure openssl 1.1
# this is needed to compile older erlang versions
# example: KERL_CONFIGURE_OPTIONS="-with-ssl=${HOME}/.local/lib/ssl" asdf install
WORKDIR ${HOME}/.local
RUN cd src \
  && wget https://www.openssl.org/source/openssl-1.1.1m.tar.gz \
  && tar -xzf openssl-1.1.1m.tar.gz \
  && cd openssl-1.1.1m \
  && ./config --prefix=${HOME}/.local/lib/ssl --openssldir=${HOME}/.local/lib/ssl shared zlib \
  && make \
  # && make test \
  && make install

# configure git
ARG GIT_USER_EMAIL
ARG GIT_USER_NAME
RUN git config --global user.email "${GIT_USER_EMAIL}" \
  && git config --global user.name "${GIT_USER_NAME}" \
  && git config --global core.editor nvim

USER root

# fetch/install exercism
ENV EXERCISM_VERSION 3.1.0
ENV EXERCISM_FILE  exercism-${EXERCISM_VERSION}-linux-x86_64.tar.gz
ENV EXERCISM_URL https://github.com/exercism/cli/releases/download/v${EXERCISM_VERSION}/${EXERCISM_FILE}
WORKDIR /tmp
RUN curl -L -XGET ${EXERCISM_URL} | tar xz \
  && mv exercism /usr/local/bin \
  && rm -rf ./*

# runtime
VOLUME /home/coder/exercism
COPY ./scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

FROM base AS code-server

# fetch/install code server
ENV CODE_VERSION 4.20.1
ENV CODE_RELEASE v${CODE_VERSION}
ENV CODE_PATH code-server-${CODE_VERSION}-linux-amd64
ENV CODE_FILE ${CODE_PATH}.tar.gz
ENV CODE_URL https://github.com/coder/code-server/releases/download/${CODE_RELEASE}/${CODE_FILE}
WORKDIR /usr/local/lib
RUN echo "Downloading ${CODE_URL}" \
  && curl -L ${CODE_URL} | tar xz \
  && ln -s ${PWD}/${CODE_PATH}/bin/code-server /usr/local/bin \
  && chmod 755 ${PWD}/${CODE_PATH}/bin/code-server

# runtime
WORKDIR /home/coder/project
EXPOSE 8443
CMD ["code-server", "--config", "/home/coder/.config/code-server/config.yml"]

FROM base AS openvscode-server

# fetch/install code server
ENV OPENVSCODE_VERSION 1.85.1
ENV OPENVSCODE_RELEASE openvscode-server-v${OPENVSCODE_VERSION}
ENV OPENVSCODE_PATH openvscode-server-v${OPENVSCODE_VERSION}-linux-x64
ENV OPENVSCODE_FILE ${OPENVSCODE_PATH}.tar.gz
ENV OPENVSCODE_URL https://github.com/gitpod-io/openvscode-server/releases/download/${OPENVSCODE_RELEASE}/${OPENVSCODE_FILE}
WORKDIR /usr/local/lib
RUN echo "Downloading ${OPENVSCODE_URL}" \
  && curl -L ${OPENVSCODE_URL} | tar xz \
  && sed -i 's/^ROOT=.*$/ROOT=\/usr\/local\/lib\/\$\{OPENVSCODE_PATH\}/' ${OPENVSCODE_PATH}/bin/openvscode-server \
  && ln -s ${PWD}/${OPENVSCODE_PATH}/bin/openvscode-server /usr/local/bin/openvscode-server

# runtime
WORKDIR /home/coder/project
EXPOSE 3000
CMD ["openvscode-server", "--port", "3000", "--host", "0.0.0.0"]
