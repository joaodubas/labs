FROM ubuntu:18.10

# setup unprivileged user
RUN groupadd --gid 1000 coder \
  && useradd --uid 1000 --gid coder --shell /bin/bash --create-home coder

# install system deps
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
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
ENV PATH /usr/local/bin:$PATH

# fetch/install asdf
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.7.4 \
  && echo '\n. ${HOME}/.asdf/asdf.sh' >> ~/.bashrc \
  && echo '\n. ${HOME}/.asdf/completions/asdf.bash' >> ~/.bashrc \
  && ${HOME}/.asdf/bin/asdf plugin-add python \
  && ${HOME}/.asdf/bin/asdf plugin-add erlang \
  && ${HOME}/.asdf/bin/asdf plugin-add rebar \
  && ${HOME}/.asdf/bin/asdf plugin-add elixir \
  && ${HOME}/.asdf/bin/asdf plugin-add nodejs \
  && ${HOME}/.asdf/bin/asdf plugin-add yarn \
  && ${HOME}/.asdf/bin/asdf plugin-add golang

# fetch/install python
RUN ${HOME}/.asdf/bin/asdf install python 3.7.4 \
  && ${HOME}/.asdf/bin/asdf global python 3.7.4

# fetch/install golang
RUN ${HOME}/.asdf/bin/asdf install golang 1.12.9 \
  && ${HOME}/.asdf/bin/asdf global golang 1.12.9
# ENV GOPATH /go
# ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
# RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

# fetch/install erlang
RUN ${HOME}/.asdf/bin/asdf install erlang 22.0.7 \
  && ${HOME}/.asdf/bin/asdf global erlang 22.0.7

# extra useful tools here: rebar & rebar3
# RUN ${HOME}/.asdf/bin/asdf install rebar 2.6.4 \
#   && ${HOME}/.asdf/bin/asdf install rebar 3.11.0 \
#   && ${HOME}/.asdf/bin/asdf global rebar 3.11.0

# fetch/install elixir
RUN ${HOME}/.asdf/bin/asdf install elixir 1.9.1-otp-22 \
  && ${HOME}/.asdf/bin/asdf global elixir 1.9.1-otp-22

# fetch/install node/yarn
RUN PATH=${HOME}/.asdf/bin:${PATH} ${HOME}/.asdf/plugins/nodejs/bin/import-release-team-keyring \
  && PATH=${HOME}/.asdf/bin:${PATH} ${HOME}/.asdf/bin/asdf install nodejs 12.8.1 \
  && ${HOME}/.asdf/bin/asdf global nodejs 12.8.1

# fetch/install code server
ENV CODE_VERSION 1.1156-vsc1.33.1
ENV CODE_PATH code-server${CODE_VERSION}-linux-x64
ENV CODE_FILE ${CODE_PATH}.tar.gz
ENV CODE_URL https://github.com/codercom/code-server/releases/download/${CODE_VERSION}/${CODE_FILE}
WORKDIR /opt
RUN curl -L ${CODE_URL} | tar xz \
  && cp ${CODE_PATH}/code-server /usr/local/bin \
  && cd / \
  && rm -rf /opt/${CODE_PATH}

WORKDIR /root/project
EXPOSE 8443
ENTRYPOINT ["code-server"]
CMD ["-d", "$PWD"]
