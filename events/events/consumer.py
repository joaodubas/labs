# encoding: utf-8
import logging
from functools import wraps

from confluent_kafka import Consumer, KafkaError


class consumer(object):
    """Decorator to consume events from kafka.

    Args:
        topic (str): topic from which events are consumed.
        groupd_id (str): consumer group identifier.

    Attributes:
        consumer (confluent_kafka.Consumer): kafka consumer connection.
        topic (str): topic from which events are consumed.
        logger (logging.Logger): logging instance.

    """
    def __init__(self, topic, group_id):
        self.consumer = Consumer({
            'bootstrap.servers': 'kafka:9092',
            'group.id': group_id,
            'default.topic.config': {
                'auto.offset.reset': 'smallest',
            },
        })
        self.topic = topic
        self.logger = logging.getLogger('events.consumer')

    def __call__(self, fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            self.consumer.subscribe([self.topic])
            try:
                while True:
                    msg = self.consumer.poll(1.0)

                    if msg is None:
                        continue
                    elif msg.error():
                        if msg.error().code() == KafkaError._PARTITION_EOF:
                            continue
                        else:
                            self.logger.warning(
                                'consumer: fetch failed {}'.format(msg.error())
                            )
                            self.consumer.close()
                            break

                    yield fn(message=msg.value().decode('utf-8'))
            except KeyboardInterrupt as e:
                self.consumer.close()
                self.logger.info('consumer: close')
                raise

        return wrapper
