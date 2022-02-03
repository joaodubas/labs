#!/bin/bash
set -e

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
