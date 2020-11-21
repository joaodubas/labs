FROM ubuntu:20.04

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
ENV ASDF_HOME_DIR ${XDG_CONFIG_HOME}/asdf
ENV ASDF_DATA_DIR ${XDG_CACHE_HOME}/asdf
ENV ZDOTDIR ${XDG_CONFIG_HOME}/zsh

# fetch/install asdf
ENV PATH ${XDG_CONFIG_HOME}/asdf/bin:$PATH
ENV ASDF_VERSION v0.8.0-rc1
RUN git clone https://github.com/asdf-vm/asdf.git ${ASDF_HOME_DIR} --branch ${ASDF_VERSION} \
  && echo '\n. ${ASDF_HOME_DIR}/asdf.sh' >> ${HOME}/.zshrc.ext \
  && echo '\n. ${ASDF_HOME_DIR}/completions/asdf.bash' >> ${HOME}/.zshrc.ext

# fetch/install python
ENV PYTHON_VERSION 3.9.0
RUN asdf plugin-add python \
  && asdf install python ${PYTHON_VERSION} \
  && asdf global python ${PYTHON_VERSION} \
  && echo "install pynvim" \
  && ${ASDF_DATA_DIR}/installs/python/${PYTHON_VERSION}/bin/pip install pynvim

# fetch/install golang
ENV GO_VERSION 1.15.2
ENV GOPATH ${HOME}/.config/go
ENV PATH ${GOPATH}/bin:/usr/local/bin:${PATH}
RUN asdf plugin-add golang \
  && asdf install golang ${GO_VERSION} \
  && asdf global golang ${GO_VERSION} \
  && mkdir -p "${GOPATH}/src" "${GOPATH}/bin" \
  && chmod -R 777 "${GOPATH}"

# fetch/install java
ENV JAVA_VERSION openjdk-15
RUN asdf plugin-add java \
  && asdf install java ${JAVA_VERSION} \
  && asdf global java ${JAVA_VERSION} \
  && echo '\n. ${ASDF_DATA_DIR}/plugins/java/set-java-home.bash' >> ${HOME}/.zshrc.ext

# fetch/install kotlin
ENV KOTLIN_VERSION 1.4.10
RUN asdf plugin-add kotlin \
  && asdf install kotlin ${KOTLIN_VERSION} \
  && asdf global kotlin ${KOTLIN_VERSION}

# fetch/install erlang
ENV ERLANG_VERSION 23.1.1
RUN asdf plugin-add erlang \
  && asdf install erlang ${ERLANG_VERSION} \
  && asdf global erlang ${ERLANG_VERSION}

# fetch/install elixir
ENV ELIXIR_VERSION 1.11.0-otp-23
RUN asdf plugin-add elixir \
  && asdf install elixir ${ELIXIR_VERSION} \
  && asdf global elixir ${ELIXIR_VERSION}

# fetch/install node/yarn
ENV NODE_VERSION 14.13.1
RUN asdf plugin-add nodejs \
  && ${ASDF_DATA_DIR}/plugins/nodejs/bin/import-release-team-keyring \
  && asdf install nodejs ${NODE_VERSION} \
  && asdf global nodejs ${NODE_VERSION}
ENV YARN_VERSION 1.22.10
RUN asdf plugin-add yarn \
  && asdf install yarn ${YARN_VERSION} \
  && asdf global yarn ${YARN_VERSION}

# fetch/install neovim plug
RUN curl -fLo \
    ${XDG_DATA_HOME}/nvim/site/autoload/plug.vim \
    --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# fetch/install fzf
RUN mkdir -p ${ZDOTDIR} \
  && touch ${ZDOTDIR}/.zshrc \
  && git clone --depth 1 https://github.com/junegunn/fzf.git ${HOME}/.fzf \
  && ${HOME}/.fzf/install

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
ENV RIPGREP_VERSION 12.1.1
ENV RIPGREP_FILE ripgrep_${RIPGREP_VERSION}_amd64.deb
ENV RIPGREP_URL https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/${RIPGREP_FILE}
RUN curl -LO ${RIPGREP_URL} \
  && dpkg -i ${RIPGREP_FILE} \
  && rm ${RIPGREP_FILE}
ENV FZF_DEFAULT_COMMAND rg --files
ENV FZF_DEFAULT_OPTS -m --height 50% --border

# fetch/install grpc
ENV GRPC_VERSION 3.13.0
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

# fetch/install code server
ENV CODE_VERSION 3.7.2
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
USER coder
WORKDIR ${HOME}/project
VOLUME ${HOME}/exercism
EXPOSE 8443
ENTRYPOINT ["code-server"]
CMD ["-d", "$PWD"]
