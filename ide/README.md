# online visual studio code with a twist

Run [`code-server`][code-server] or [`openvscode-server`][openvscode] with support to:

1. [asdf (0.9.0)][asdf]
1. [pyenv (2.2.4)][pyenv]
1. [golang (1.18)][golang]
1. [erlang/otp (24.3.2)][erlang]
1. [elixir (1.13.3)][elixir]
1. [R (4.1.3)][R]
1. [node (17.8.0)][node]

## Run the servers

Invoke `docker-compose up -d` and this will start the servers.

## Notes

I'm still deciding which code editor is the best one, that's why I'm keeping both for now.

[code-server]: https://github.com/codercom/code-server
[openvscode]: https://github.com/gitpod-io/openvscode-server
[asdf]: https://asdf-vm.com/#/
[pyenv]: https://github.com/pyenv/pyenv
[golang]: https://github.com/kennyp/asdf-golang
[erlang]: https://github.com/asdf-vm/asdf-erlang
[R]: https://github.com/asdf-community/asdf-r
[elixr]: https://github.com/asdf-vm/asdf-elixir
[node]: https://github.com/asdf-vm/asdf-nodejs
