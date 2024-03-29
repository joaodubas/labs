import logging
import sys
import time

import redis


def consume():
    log = logger()
    message_id = '>'

    cli = conn(log)
    group(log, cli)
    while True:
        _ = recv(log, cli, message_id)
        time.sleep(1)


def conn(log: logging.Logger) -> redis.Redis:
    cli = redis.Redis(host='streams', port=6379)
    try:
        cli.ping()
    except redis.ConnectionError as e:
        log.exception('conn: error connecting {}'.format(e))
        sys.exit(1)
    except Exception as e:
        log.exception('conn: sys error {}'.format(e))
        sys.exit(1)
    return cli


def group(log: logging.Logger, cli: redis.Redis):
    try:
        cli.execute_command("XGROUP", "CREATE", 'log', 'Group', "0")
    except redis.RedisError as e:
        if 'Group name already exists' not in e.__str__():
            log.exception('group: create failed {}'.format(e))
            return
    log.info('group: create sucess')


def recv(log: logging.Logger, cli: redis.Redis, message_id: str):
    try:
        r = cli.execute_command(
            'XREADGROUP',
            'GROUP',
            'Group',
            'ConsumerPY',
            'COUNT',
            '10',
            'BLOCK',
            '500',
            'STREAMS',
            'log',
            message_id
        )
    except redis.RedisError as e:
        log.exception('recv: failed to fetch {}'.format(e))
        return
    for keys in r:
        key, messages = keys
        log.info('recv: log key {}'.format(key.decode('utf-8')))
        for mid, items in messages:
            log.info('recv: message id {}'.format(mid.decode('utf-8')))
            d = {k.decode('utf-8'): v.decode('utf-8') for k, v in items.items()}
            log.info('recv: log {}'.format(d))
            ack(log, cli, mid.decode('utf-8'))
            message_id = mid
    return message_id


def ack(log: logging.Logger, cli: redis.Redis, message_id: str):
    try:
        r = cli.execute_command('XACK', 'log', 'Group', message_id)
    except redis.RedisError as e:
        log.exception('ack: failed to ack message {} ({})'.format(
            message_id,
            e
        ))
        return
    log.info('ack: success to ack message {} ({})'.format(message_id, r))


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
