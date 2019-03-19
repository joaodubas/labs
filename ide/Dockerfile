FROM ubuntu:18.10

# install system deps
RUN apt-get update \
    && apt-get install -y \
      git \
      locales \
      net-tools \
      openssl \
      curl \
    && locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8

# fetch/install code server
ENV CODE_VERSION 1.32.0-310
ENV CODE_PATH code-server-${CODE_VERSION}-linux-x64
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
