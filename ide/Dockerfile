FROM ubuntu:22.04 AS base

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
    gfortran \
    git \
    gosu \
    gpg \
    gpg-agent \
    jq \
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
    pkg-config \
    python3-openssl \
    sudo \
    tk-dev \
    unixodbc-dev \
    unzip \
    uuid-dev \
    wget \
    xorg-dev \
    xz-utils \
    zlib1g-dev \
    zsh \
  && echo 'install gh for neovim lsp installer' \
  && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/etc/apt/trusted.gpg.d/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && apt-get update \
  && apt-get -y install gh \
  && rm -rf /var/lib/apt/lists/* \
  && locale-gen en_US.UTF-8

# fetch/install command line utilities
ENV RIPGREP_VERSION 13.0.0
ENV RIPGREP_FILE ripgrep_${RIPGREP_VERSION}_amd64.deb
ENV RIPGREP_URL https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/${RIPGREP_FILE}
ENV GRPC_VERSION 21.12
ENV GRPC_PATH protoc-${GRPC_VERSION}-linux-x86_64
ENV GRPC_FILE ${GRPC_PATH}.zip
ENV GRPC_URL https://github.com/protocolbuffers/protobuf/releases/download/v${GRPC_VERSION}/${GRPC_FILE}
ENV EXA_VERSION v0.10.1
ENV EXA_PATH exa-linux-x86_64-${EXA_VERSION}
ENV EXA_FILE ${EXA_PATH}.zip
ENV EXA_URL https://github.com/ogham/exa/releases/download/${EXA_VERSION}/${EXA_FILE}
ENV BAT_VERSION 0.22.1
ENV BAT_FILE bat_${BAT_VERSION}_amd64.deb
ENV BAT_URL https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/${BAT_FILE}
ENV LEFTHOOK_VERSION 1.2.7
ENV LEFTHOOK_FILE lefthook_${LEFTHOOK_VERSION}_Linux_x86_64
ENV LEFTHOOK_URL https://github.com/evilmartians/lefthook/releases/download/v${LEFTHOOK_VERSION}/${LEFTHOOK_FILE}
# NOTE (jpd): update from antibody to zinit (https://github.com/zdharma-continuum/zinit)
RUN echo 'install antibody' \
  && curl -sfL git.io/antibody | sh -s - -b /usr/local/bin \
  && echo 'setup starship' \
  && curl -sS https://starship.rs/install.sh | sh -s -- --yes \
  && echo 'setup ripgrep' \
  && curl -LO ${RIPGREP_URL} \
  && dpkg -i ${RIPGREP_FILE} \
  && rm ${RIPGREP_FILE} \
  && echo 'setup grpc' \
  && curl -LO ${GRPC_URL} \
  && unzip ${GRPC_FILE} -d /opt/${GRPC_PATH} \
  && ln -s /opt/${GRPC_PATH}/bin/protoc /usr/local/bin/ \
  && cp --recursive /opt/${GRPC_PATH}/include/google /usr/local/include \
  && chmod --recursive 755 /opt/${GRPC_PATH}/bin \
  && chmod --recursive o+r /usr/local/include \
  && rm ${GRPC_FILE} \
  && echo 'setup exa' \
  && curl -LO ${EXA_URL} \
  && unzip ${EXA_FILE} -d /opt/${EXA_PATH} \
  && ln -s /opt/${EXA_PATH}/bin/exa /usr/local/bin \
  && chmod --recursive 755 /opt/${EXA_PATH}/bin \
  && rm ${EXA_FILE} \
  && echo 'setup bat' \
  && curl -LO ${BAT_URL} \
  && dpkg -i ${BAT_FILE} \
  && rm ${BAT_FILE} \
  && echo 'setup lefthook' \
  && curl -LO ${LEFTHOOK_URL} \
  && chmod 755 ${LEFTHOOK_FILE} \
  && mv ${LEFTHOOK_FILE} /usr/local/bin/lefthook

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
ENV LOCAL_BIN_HOME ${HOME}/.local/bin
ENV LOCAL_SRC_HOME ${HOME}/.local/src
ENV XDG_CONFIG_HOME ${HOME}/.config
ENV XDG_DATA_HOME ${HOME}/.local/share
ENV XDG_CACHE_HOME ${HOME}/.cache
ENV ZDOTDIR ${XDG_CONFIG_HOME}/zsh
ENV STARSHIP_CONFIG ${XDG_CONFIG_HOME}/starship/config.toml
ENV PATH ${LOCAL_BIN_HOME}:$PATH

# fetch/install local command line utilities
ENV ASDF_DIR ${LOCAL_SRC_HOME}/asdf
ENV ASDF_DATA_DIR ${XDG_CACHE_HOME}/asdf
ENV ASDF_VERSION v0.11.1
ENV PYENV_ROOT ${LOCAL_SRC_HOME}/pyenv
ENV PATH ${PYENV_ROOT}/bin:${ASDF_DIR}/bin:$PATH
RUN echo 'setup asdf' \
  && git clone https://github.com/asdf-vm/asdf.git ${ASDF_DIR} --branch ${ASDF_VERSION} \
  && echo 'setup pyenv' \
  && curl https://pyenv.run | bash \
  && echo 'setup zoxide' \
  && curl -sS https://webinstall.dev/zoxide | bash

# configure asdf plugins
ENV GO_VERSION 1.19.5
ENV ERLANG_VERSION 25.2.1
ENV ELIXIR_VERSION 1.14.3-otp-25
ENV NODE_VERSION 19.4.0
ENV YARN_VERSION 1.22.19
ENV AWSCLI_VERSION 2.9.16
ENV KUBECTL_VERSION 1.26.1
ENV HELM_VERSION 3.11.0
RUN asdf plugin-add golang \
  && asdf plugin-add erlang \
  && asdf plugin-add elixir \
  && asdf plugin-add nodejs \
  && asdf plugin-add yarn \
  && asdf plugin-add awscli \
  && asdf plugin-add kubectl \
  && asdf plugin-add helm \
  && echo "golang $GO_VERSION" > /home/coder/.tool-versions \
  && echo "erlang $ERLANG_VERSION" >> /home/coder/.tool-versions \
  && echo "elixir $ELIXIR_VERSION" >> /home/coder/.tool-versions \
  && echo "nodejs $NODE_VERSION" >> /home/coder/.tool-versions \
  && echo "yarn $YARN_VERSION" >> /home/coder/.tool-versions \
  && echo "awscli $AWSCLI_VERSION" >> /home/coder/.tool-versions \
  && echo "kubectl $KUBECTL_VERSION" >> /home/coder/.tool-versions \
  && echo "helm $HELM_VERSION" >> /home/coder/.tool-versions

# configure golang
ENV GOPATH ${XDG_DATA_HOME}/go
ENV PATH ${GOPATH}/bin:/usr/local/bin:${PATH}
RUN mkdir -p "${GOPATH}/src" "${GOPATH}/bin" \
  && chmod -R 777 "${GOPATH}"

# configure zshrc extension
RUN echo 'eval "$(starship init zsh)"' >> ${HOME}/.zshrc.ext \
  && echo 'eval "$(zoxide init zsh)"' >> ${HOME}/.zshrc.ext \
  && echo '. ${ASDF_DIR}/asdf.sh' >> ${HOME}/.zshrc.ext \
  && echo 'fpath=(${ASDF_DIR}/completions $fpath)' >> ${HOME}/.zshrc.ext \
  && echo 'autoload -Uz compinit && compinit' >> ${HOME}/.zshrc.ext \
  && echo 'eval "$(pyenv init -)"' >> ${HOME}/.zshrc.ext \
  && echo 'eval "$(pyenv virtualenv-init -)"' >> ${HOME}/.zshrc.ext \
  && echo 'alias l="exa --time-style long-iso --color=auto -F"' >> ${HOME}/.zshrc.ext \
  && echo 'alias ll="l -Fahl"' >> ${HOME}/.zshrc.ext \
  && echo 'alias la="l -a"' >> ${HOME}/.zshrc.ext \
  && echo 'alias cat="bat"' >> ${HOME}/.zshrc.ext

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
  && chown --recursive coder:coder ${XDG_CONFIG_HOME}/exercism \
  && rm -rf ./*

# runtime
VOLUME /home/coder/exercism
COPY ./scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

FROM base AS code-server

# fetch/install code server
ENV CODE_VERSION 4.9.1
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
ENV OPENVSCODE_VERSION 1.74.3
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
