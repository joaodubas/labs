import datetime
import logging
import sys
import time

import redis


def produce():
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
            'time',
            datetime.datetime.utcnow().astimezone(tz).strftime(rfc3339)
        )
        time.sleep(1.0)


def conn(log: logging.Logger) -> redis.Redis:
    cli = redis.Redis(host='streams', port='6379')
    try:
        cli.ping()
    except redis.ConnectionError as e:
        log.exception('conn: error connecting {}'.format(e))
        sys.exit(1)
    except redis.ConnectionError as e:
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