FROM ubuntu:18.04

# setup unprivileged user
RUN groupadd --gid 1000 coder \
  && useradd --uid 1000 --gid coder --shell /bin/bash --create-home coder

# install system deps
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
  && apt-get install -y software-properties-common \
  && add-apt-repository ppa:neovim-ppa/unstable \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    autoconf \
    automake \
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
    libwxgtk3.0 \
    libwxgtk3.0-dev \
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
    tk-dev \
    unixodbc-dev \
    unzip \
    uuid-dev \
    wget \
    xz-utils \
    zlib1g-dev \
  && rm -rf /var/lib/apt/lists/* \
  && locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8

# fetch/install asdf
ENV ASDF_VERSION v0.7.4
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch ${ASDF_VERSION} \
  && echo '\n. ${HOME}/.asdf/asdf.sh' >> ~/.bashrc \
  && echo '\n. ${HOME}/.asdf/completions/asdf.bash' >> ~/.bashrc

# fetch/install python
ENV PYTHON_VERSION 3.8.0
RUN ${HOME}/.asdf/bin/asdf plugin-add python \
  && ${HOME}/.asdf/bin/asdf install python ${PYTHON_VERSION} \
  && ${HOME}/.asdf/bin/asdf global python ${PYTHON_VERSION}

# fetch/install golang
ENV GO_VERSION 1.13.3
ENV GOPATH /go
RUN ${HOME}/.asdf/bin/asdf plugin-add golang \
  && ${HOME}/.asdf/bin/asdf install golang ${GO_VERSION} \
  && ${HOME}/.asdf/bin/asdf global golang ${GO_VERSION} \
  && mkdir -p "${GOPATH}/src" "${GOPATH}/bin" \
  && chmod -R 777 "${GOPATH}"

# fetch/install java
ENV JAVA_VERSION adopt-openjdk-13+33_openj9-0.16.0
RUN ${HOME}/.asdf/bin/asdf plugin-add java \
  && ${HOME}/.asdf/bin/asdf install java ${JAVA_VERSION} \
  && ${HOME}/.asdf/bin/asdf global java ${JAVA_VERSION} \
  && echo '\n. ${HOME}/.asdf/plugins/java/set-java-home.sh' >> ~/.bashrc

# fetch/install kotlin
ENV KOTLIN_VERSION 1.3.50
RUN ${HOME}/.asdf/bin/asdf plugin-add kotlin \
  && ${HOME}/.asdf/bin/asdf install kotlin ${KOTLIN_VERSION} \
  && ${HOME}/.asdf/bin/asdf global kotlin ${KOTLIN_VERSION}

# fetch/install erlang
ENV ERLANG_VERSION 22.1.4
RUN ${HOME}/.asdf/bin/asdf plugin-add erlang \
  && ${HOME}/.asdf/bin/asdf install erlang ${ERLANG_VERSION} \
  && ${HOME}/.asdf/bin/asdf global erlang ${ERLANG_VERSION}

# fetch/install elixir
ENV ELIXIR_VERSION 1.9.2-otp-22
RUN ${HOME}/.asdf/bin/asdf plugin-add elixir \
  && ${HOME}/.asdf/bin/asdf install elixir ${ELIXIR_VERSION} \
  && ${HOME}/.asdf/bin/asdf global elixir ${ELIXIR_VERSION}

# fetch/install node/yarn
ENV NODE_VERSION 12.12.0
RUN ${HOME}/.asdf/bin/asdf plugin-add nodejs \
  && PATH=${HOME}/.asdf/bin:${PATH} ${HOME}/.asdf/plugins/nodejs/bin/import-release-team-keyring \
  && PATH=${HOME}/.asdf/bin:${PATH} ${HOME}/.asdf/bin/asdf install nodejs ${NODE_VERSION} \
  && ${HOME}/.asdf/bin/asdf global nodejs ${NODE_VERSION}
ENV YARN_VERSION 1.19.1
RUN ${HOME}/.asdf/bin/asdf plugin-add yarn \
  && ${HOME}/.asdf/bin/asdf install yarn ${YARN_VERSION} \
  && ${HOME}/.asdf/bin/asdf global yarn ${YARN_VERSION}

# fetch/install exercism
ENV EXERCISM_VERSION v3.0.12
ENV EXERCISM_FILE exercism-linux-64bit.tgz
ENV EXERCISM_URL https://github.com/exercism/cli/releases/download/${EXERCISM_VERSION}/${EXERCISM_FILE}
WORKDIR /tmp
RUN curl -L -XGET ${EXERCISM_URL} | tar xz \
  && mv exercism /usr/local/bin \
  && mkdir -p /root/.config/exercism \
  && mv shell/exercism_completion.bash /root/.config/exercism \
  && echo '\n. ${HOME}/.config/exercism/exercism_completion.bash' >> ~/.bashrc \
  && rm -rf ./*

# fetch/install neovim
ENV RIPGREP_VERSION 11.0.2
ENV RIPGREP_FILE ripgrep_${RIPGREP_VERSION}_amd64.deb
ENV RIPGREP_URL https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/${RIPGREP_FILE}
RUN echo "install plug" \
  && curl -fLo \
    /root/.local/share/nvim/site/autoload/plug.vim \
    --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
  && echo "install fzf" \
  && git clone --depth 1 https://github.com/junegunn/fzf.git /root/.fzf \
  && /root/.fzf/install \
  && echo "install ripgrep" \
  && curl -LO ${RIPGREP_URL} \
  && dpkg -i ${RIPGREP_FILE} \
  && rm ${RIPGREP_FILE} \
  && echo "install pynvim" \
  && /root/.asdf/installs/python/${PYTHON_VERSION}/bin/pip install pynvim

# fetch/install code server
ENV CODE_VERSION 2.1688-vsc1.39.2
ENV CODE_PATH code-server${CODE_VERSION}-linux-x86_64
ENV CODE_FILE ${CODE_PATH}.tar.gz
ENV CODE_URL https://github.com/cdr/code-server/releases/download/${CODE_VERSION}/${CODE_FILE}
WORKDIR /opt
RUN curl -L ${CODE_URL} | tar xz \
  && cp ${CODE_PATH}/code-server /usr/local/bin \
  && cd / \
  && rm -rf /opt/${CODE_PATH}

WORKDIR /root/project
VOLUME /root/exercism
ENV PATH $GOPATH/bin:/usr/local/bin:$PATH
EXPOSE 8443
ENTRYPOINT ["code-server"]
CMD ["-d", "$PWD"]
