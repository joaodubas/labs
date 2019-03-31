# code server with a twist

Run [`code-server`][0] with support to:

1. [python (3.7.2)][1]
2. [golang (1.12)][2]
3. [erlang/otp (21.3)][3]
4. [elixir (1.8.1)][4]
5. [node (8.15.1)][5]

## Run the server

Invoke `docker-compose up -d` and this will start the server.

[0]: https://github.com/codercom/code-server
[1]: https://github.com/docker-library/python/blob/ce69fc6369feb8ec757b019035ddad7bac20562c/3.7/stretch/Dockerfile
[2]: https://github.com/docker-library/golang/blob/fd272b2b72db82a0bd516ce3d09bba624651516c/1.12/stretch/Dockerfile
[3]: https://github.com/erlang/docker-erlang-otp/blob/81dc84940c670b01c8b5c5622b02500f4f77a4b9/21/Dockerfile
[4]: https://github.com/c0b/docker-elixir/blob/5570afaa6de095a86e98457e1ad1351f92ccfe26/1.8/Dockerfile
[5]: https://github.com/nodejs/docker-node/blob/de76fb48b532d6be012098dc3538bd15329a27d0/8/jessie/Dockerfile
