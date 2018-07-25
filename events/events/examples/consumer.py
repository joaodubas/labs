# encoding: utf-8
from __future__ import absolute_import

import datetime
import decimal
import json

from events.consumer import consumer


@consumer(topic='payment', group_id='bill')
def register_bill(message):
    msg = json.loads(message)

    # NOTE: received non dict message
    if not isinstance(msg, (dict, list)):
        return msg

    msg['due_date'] = from_timestamp(msg['due_date'])
    msg['amount'] = to_decimal(msg['amount'])
    return msg


def from_timestamp(ts):
    """Convert a timestamp into a datetime.

    Args:
        ts (int): timestamp to be converted.

    Returns:
        datetime.datetime

    """
    return datetime.datetime.utcfromtimestamp(ts)


def to_decimal(dc):
    """Convert a string into a decimal value.

    Args:
        dc (str): string to be converted.

    Returns:
        decimal.Decimal

    """
    return decimal.Decimal(dc)
