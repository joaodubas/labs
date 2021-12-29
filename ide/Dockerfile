FROM ubuntu:20.04 AS base

# install system deps
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
  && apt-get install -y software-properties-common \
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
    g++ \
    gcc \
    git \
    gosu \
    gpg \
    gpg-agent \
    jq \
    libbz2-dev \
    libc6-dev \
    libffi-dev \
    liblzma-dev \
    libncurses-dev \
    libncurses5-dev \
    libncursesw5-dev \
    libodbc1 \
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
    pkg-config \
    python-openssl \
    sudo \
    tk-dev \
    unixodbc-dev \
    unzip \
    uuid-dev \
    wget \
    xz-utils \
    zsh \
    zlib1g-dev \
  && rm -rf /var/lib/apt/lists/* \
  && curl -sfL git.io/antibody | sh -s - -b /usr/local/bin \
  && locale-gen en_US.UTF-8

# setup unprivileged user
RUN groupadd --gid 999 docker \
  && groupadd --gid 1000 coder \
  && useradd \
      --uid 1000 \
      --gid coder \
      --groups docker,sudo \
      --shell $(which zsh) \
      --home-dir /home/coder \
      --create-home \
      coder \
  && echo 'coder:coder' | chpasswd

USER coder
WORKDIR /home/coder

ENV LANGUAGE en_US.UTF-8
ENV LANG ${LANGAGUE}
ENV LC_ALL ${LANGUAGE}
ENV HOME /home/coder
ENV XDG_CONFIG_HOME ${HOME}/.config
ENV XDG_DATA_HOME ${HOME}/.local/share
ENV XDG_CACHE_HOME ${HOME}/.cache
ENV ASDF_DIR ${XDG_CONFIG_HOME}/asdf
ENV ASDF_DATA_DIR ${XDG_CACHE_HOME}/asdf
ENV ZDOTDIR ${XDG_CONFIG_HOME}/zsh

# fetch/install asdf
ENV PATH ${ASDF_DIR}/bin:$PATH
ENV ASDF_VERSION v0.9.0
RUN git clone https://github.com/asdf-vm/asdf.git ${ASDF_DIR} --branch ${ASDF_VERSION} \
  && echo '\n. ${ASDF_DIR}/asdf.sh' >> ${HOME}/.zshrc.ext \
  && echo 'fpath=(${ASDF_DIR}/completions $fpath)' >> ${HOME}/.zshrc.ext \
  && echo 'autoload -Uz compinit && compinit' >> ${HOME}/.zshrc.ext

# configure asdf plugins
ENV GO_VERSION 1.17.5
ENV ERLANG_VERSION 24.1.7
ENV ELIXIR_VERSION 1.12.3-otp-24
ENV NODE_VERSION 17.2.0
ENV YARN_VERSION 1.22.17
RUN asdf plugin-add golang \
  && asdf plugin-add erlang \
  && asdf plugin-add elixir \
  && asdf plugin-add nodejs \
  && asdf plugin-add yarn \
  && echo "golang $GO_VERSION" > /home/coder/.tool-versions \
  && echo "erlang $ERLANG_VERSION" >> /home/coder/.tool-versions \
  && echo "elixir $ELIXIR_VERSION" >> /home/coder/.tool-versions \
  && echo "nodejs $NODE_VERSION" >> /home/coder/.tool-versions \
  && echo "yarn $YARN_VERSION" >> /home/coder/.tool-versions

# configure golang
ENV GOPATH ${HOME}/.config/go
ENV PATH ${GOPATH}/bin:/usr/local/bin:${PATH}
RUN mkdir -p "${GOPATH}/src" "${GOPATH}/bin" \
  && chmod -R 777 "${GOPATH}"

USER root

# fetch/install exercism
ENV EXERCISM_VERSION v3.0.13
ENV EXERCISM_FILE exercism-linux-64bit.tgz
ENV EXERCISM_URL https://github.com/exercism/cli/releases/download/${EXERCISM_VERSION}/${EXERCISM_FILE}
WORKDIR /tmp
RUN curl -L -XGET ${EXERCISM_URL} | tar xz \
  && mv exercism /usr/local/bin \
  && echo ${XDG_CONFIG_HOME} \
  && mkdir -p ${XDG_CONFIG_HOME}/exercism \
  && mv shell/exercism_completion.bash ${XDG_CONFIG_HOME}/exercism \
  && echo '\n. ${XDG_CONFIG_HOME}/exercism/exercism_completion.bash' >> ${HOME}/.zshrc.ext \
  && chown --recursive coder:coder ${XDG_CONFIG_HOME}/exercism \
  && rm -rf ./*

# fetch/install ripgrep
ENV RIPGREP_VERSION 13.0.0
ENV RIPGREP_FILE ripgrep_${RIPGREP_VERSION}_amd64.deb
ENV RIPGREP_URL https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/${RIPGREP_FILE}
RUN curl -LO ${RIPGREP_URL} \
  && dpkg -i ${RIPGREP_FILE} \
  && rm ${RIPGREP_FILE}

# fetch/install grpc
ENV GRPC_VERSION 3.19.1
ENV GRPC_PATH protoc-${GRPC_VERSION}-linux-x86_64
ENV GRPC_FILE ${GRPC_PATH}.zip
ENV GRPC_URL https://github.com/protocolbuffers/protobuf/releases/download/v${GRPC_VERSION}/${GRPC_FILE}
RUN curl -LO ${GRPC_URL} \
  && unzip ${GRPC_FILE} -d /opt/${GRPC_PATH} \
  && ln -s /opt/${GRPC_PATH}/bin/protoc /usr/local/bin/ \
  && cp --recursive /opt/${GRPC_PATH}/include/google /usr/local/include \
  && chmod --recursive 755 /opt/${GRPC_PATH}/bin \
  && chmod --recursive o+r /usr/local/include \
  && rm ${GRPC_FILE}

FROM base AS code-server

# fetch/install code server
ENV CODE_VERSION 4.0.1
ENV CODE_RELEASE v${CODE_VERSION}
ENV CODE_PATH code-server-${CODE_VERSION}-linux-amd64
ENV CODE_FILE ${CODE_PATH}.tar.gz
ENV CODE_URL https://github.com/cdr/code-server/releases/download/${CODE_RELEASE}/${CODE_FILE}
WORKDIR /usr/local/lib
RUN echo "Downloading ${CODE_URL}" \
  && curl -L ${CODE_URL} | tar xz \
  && ln -s ${PWD}/${CODE_PATH}/bin/code-server /usr/local/bin \
  && chmod 755 ${PWD}/${CODE_PATH}/bin/code-server

# runtime
WORKDIR /home/coder/project
VOLUME /home/coder/exercism
EXPOSE 8443
COPY ./scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["code-server", "--config", "/home/coder/.config/code-server/config.yml"]

FROM base AS openvscode-server

# fetch/install code server
ENV OPENVSCODE_VERSION 1.63.2
ENV OPENVSCODE_RELEASE openvscode-server-v${OPENVSCODE_VERSION}
ENV OPENVSCODE_PATH openvscode-server-v${OPENVSCODE_VERSION}-linux-x64
ENV OPENVSCODE_FILE ${OPENVSCODE_PATH}.tar.gz
ENV OPENVSCODE_URL https://github.com/gitpod-io/openvscode-server/releases/download/${OPENVSCODE_RELEASE}/${OPENVSCODE_FILE}
WORKDIR /usr/local/lib
RUN echo "Downloading ${OPENVSCODE_URL}" \
  && curl -L ${OPENVSCODE_URL} | tar xz \
  && sed -i 's/^ROOT=.*$/ROOT=\/usr\/local\/lib\/\$\{OPENVSCODE_PATH\}/' ${OPENVSCODE_PATH}/server.sh \
  && ln -s ${PWD}/${OPENVSCODE_PATH}/server.sh /usr/local/bin/openvscode-server

# runtime
WORKDIR /home/coder/project
VOLUME /home/coder/exercism
EXPOSE 3000
COPY ./scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["openvscode-server", "--port", "3000", "--host", "0.0.0.0"]
