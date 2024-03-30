import datetime
import logging
import os
import sys
import time

import redis


def produce():
    """Send messages, every second, to a given redis stream."""
    tz = datetime.timezone(
        datetime.timedelta(0),
        name='Z'
    )
    rfc3339 = '%Y-%m-%dT%H:%M:%S.%f%Z'
    log = logger()

    cli = conn(log)
    while True:
        send(
            log,
            cli,
            'host',
            'host b',
            'system',
            os.environ.get('STREAM_HOST', 'stream'),
            'time',
            datetime.datetime.now(datetime.UTC).astimezone(tz).strftime(rfc3339)
        )
        time.sleep(1.0)


def conn(log: logging.Logger) -> redis.Redis:
    """Make connection to redis server.

    Args:
        log: common logger instance.

    Returns:
        Redis connection.

    """
    stream_host = os.environ.get('STREAM_HOST', 'stream')
    stream_port = os.environ.get('STREAM_PORT', '6379')
    cli = redis.Redis(host=stream_host, port=int(stream_port))
    try:
        cli.ping()
    except redis.ConnectionError as e:
        log.exception('conn: error connecting {}'.format(e))
        sys.exit(1)
    except redis.RedisError as e:
        log.exception('conn: redis error {}'.format(e))
        sys.exit(1)
    except Exception as e:
        log.exception('conn: sys error {}'.format(e))
        sys.exit(1)
    return cli


def send(log: logging.Logger, cli: redis.Redis, *args):
    try:
        r = cli.execute_command('XADD', 'log', '*', *args)
    except redis.RedisError as e:
        log.exception('send: failed to log {}'.format(e))
        sys.exit(1)
    log.info('send: success {}'.format(r))


def logger() -> logging.Logger:
    root = logging.getLogger()
    root.setLevel(logging.DEBUG)

    ch = logging.StreamHandler(sys.stdout)
    ch.setLevel(logging.DEBUG)

    fmt = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    formatter = logging.Formatter(fmt)

    ch.setFormatter(formatter)
    root.addHandler(ch)

    return root


if __name__ == '__main__':
    produce()
