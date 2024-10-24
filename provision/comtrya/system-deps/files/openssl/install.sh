#!/usr/bin/env sh
cd $HOME/.local/src/openssl-1.1.1m \
&& ./config --prefix=$HOME/.local/lib/ssl --openssldir=$HOME/.local/lib/ssl shared zlib \
&& make \
&& make install
