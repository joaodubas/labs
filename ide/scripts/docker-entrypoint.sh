#!/bin/bash
set -e

if [ "$1" = 'code-server' ] || [ "$1" = 'openvscode-server' ]; then
    chown --recursive coder:coder /home/coder
    gosu coder mkdir -p /home/coder/.cache/zsh
    exec gosu coder "$@"
fi

exec "$@"
