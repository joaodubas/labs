# Redis Streams

This is a POC using redis streams to communicate different systems, written in
multiples languages (golang and python).

## What is?

This is a new data type, similar to a log structure, with append only mode. For
more details, it's recommend to read the [introduction to streams][0], and to
watch the one and only [Salvatore Sanfilippo][1]
[talking about this new feature at redisday][2].

## Commands

Streams introduce a new set of commands to redis:

1. [`XADD`][3]: append a new entry into specified stream.
1. [`XLEN`][4]: fetch number of items in a stream.
1. [`XRANGE`][5]: query a stream by a range of items, and limiting by an
   optional count.
1. [`XREVRANGE`][6]: query a stream by reverse range of items, and limiting by
   an optional count.
1. [`XREAD`][7]: allow to read data from one or multiple streams, in block or
   non-block usage.

[`XREAD`][7] can be used to consume the same stream with multiple clients, but
in cases where one want to provide a different subset of messages to many
clients, it's necessary to use **consumer groups**:

1. [`XGROUP`][8]: create a consumer group for a given stream.
1. [`XREADGROUP`][9]: read data from a stream in a given group, with a
   consumer.
1. `XACK`: acknowledge a message in a group.
1. [`XPENDING`][10]: show messages sent for a group and without acknowledge.
1. `XCLAIM`: send a pending message to a consumer in a group.

To get visibility of a stream it`s possible to use:

1. `XINFO`: through sub-commands provide rich information about streams,
   groups, and consumers.

To control stream size, it's possible to create a capped stream, or clean a
stream using:

1. `XTRIM`: trim a stream to a given max length.

## POC

In this POC we have two producers and two consumers for the same group. All
data is sent through the same stream.

Some features are missing here:

1. Monitoring: it should be easy to add some key timings to this.
2. Failure check: another process should be responsible for checking pending
   messages and route them to working consumers, and check messages re-sent
   multiples times and re-route them to a dead-letter stream.
3. Interface: it would be awesome to have a visual interface for this.

[0]: https://redis.io/topics/streams-intro
[1]: https://twitter.com/antirez
[2]: https://www.youtube.com/watch?v=qXEyuUxQXZM
[3]: https://redis.io/commands/xadd
[4]: https://redis.io/commands/xlen
[5]: https://redis.io/commands/xrange
[6]: https://redis.io/commands/xrevrange
[7]: https://redis.io/commands/xread
[8]: https://redis.io/commands/xgroup
[9]: https://redis.io/commands/xreadgroup
[10]: https://redis.io/commands/xpending