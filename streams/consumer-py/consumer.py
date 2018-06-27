import logging
import sys

import redis


def consume():
    log = logger()
    message_id = '>'

    cli = conn(log)
    group(log, cli)
    while True:
        recv(log, cli, message_id)
        time.sleep(1)


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


def group(log: logging.Logger, cli: redis.Redis):
    try:
	cli.execute_command("XGROUP", "CREATE", 'log', 'Group', "0")
    except redis.RedisError as e:
        log.exception('group: create failed {}'.format(e))
        return
    log.info('group: create sucess')


def recv(log: logging.Logger, cli: redis.Redis, message_id: str):
    try:
        r = cli.execute_command(
            'XREADGROUP',
            'Group',
            'ConsumerPY',
            'COUNT',
            '10',
            'BLOCK',
            '2000',
            'STREAMS',
            'log',
            message_id
        )
    except redis.RedisError as e:
        log.exception('recv: failed to fetch {}'.format(e))
        return
    log.info('recv: success {}'.format(r))


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
    consume()
