#!/bin/bash
set -e

# TODO (jpd): configure pyenv and git links when proper env vars are set
# git config --global user.name 'Joao P Dubas'
# git config --global user.email joao.dubas@gmail.com
# git config --global core.editor nvim
# pyenv global 3.10.4
# ln -s ${HOME}/.local/share/pypoetry/venv/bin/poetry ${HOME}/.local/bin/poetry

if [ "$1" = 'code-server' ] || [ "$1" = 'openvscode-server' ]; then
    echo 'change ownership from coder home'
    chown --recursive coder:coder /home/coder

    echo 'create zsh cache path'
    gosu coder mkdir -p /home/coder/.cache/zsh

    echo 'create coder/openvscode extension dir'
    gosu coder mkdir -p /home/coder/.cache/code-server
    gosu coder mkdir -p /home/coder/.cache/openvscode/extensions

    echo 'execute command'
    exec gosu coder "$@"
fi

exec "$@"
