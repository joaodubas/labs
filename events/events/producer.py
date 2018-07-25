# encoding: utf-8
import logging
from functools import wraps

from confluent_kafka import Producer


class producer(object):
    """Decorator to send events to kafka broker.

    Args:
        topic (str): topic where event s published.

    Attributes:
        emitter (confluent_kafka.Producer): producer connection
        topic (str): topic where event is published.
        logger (logging.Logger): logging instance.

    """
    def __init__(self, topic):
        self.emitter = Producer({
            'bootstrap.servers': 'kafka:9092'
        })
        self.topic = topic
        self.logger = logging.getLogger('events.producer')

    def __call__(self, fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            # NOTE: trigger any available delivery report from previous calls.
            self.emitter.poll(0)

            result = fn(*args, **kwargs)
            self.emitter.produce(
                self.topic,
                result.encode('utf-8'),
                callback=self._callback
            )
            return result
        return wrapper

    def _callback(self, err, msg):
        msgs = {
            'err': 'producer: delivery failed [topic: {} | err: {}]',
            'ok': 'producer: delivery success [topic: {} | partition: {}]',
        }
        if err is not None:
            self.logger.warn(msgs['err'].format(self.topic, err))
        else:
            self.logger.debug(msgs['ok'].format(msg.topic(), msg.partition()))
