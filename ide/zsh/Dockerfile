FROM ubuntu:20.04

# install system deps, zsh and user
RUN apt-get update \
    && apt-get -y dist-upgrade \
    && apt-get -y install curl git sudo vim zsh \
    && curl -sfL git.io/antibody | sh -s - -b /usr/local/bin \
    && chsh -s $(which zsh) root \
    && useradd -s $(which zsh) -d /home/me -m -G sudo me \
    && echo 'me:me' | chpasswd

COPY ./config/zsh /home/me/.config/zsh
RUN chown --recursive me:me /home/me

USER me
WORKDIR /home/me
ENV XDG_CONFIG_HOME /home/me/.config
ENV XDG_DATA_HOME /home/me/.local/share
ENV XDG_CACHE_HOME /home/me/.cache
ENV ZDOTDIR ${XDG_CONFIG_HOME}/zsh

# RUN antibody init \
#     && antibody bundle

CMD ["zsh"]
