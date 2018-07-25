# encoding: utf-8
from __future__ import absolute_import

import calendar
import decimal
import json

from events.producer import producer


@producer(topic='payment')
def emit_bill(contract_id, borrower_id, due_date, amount):
    return json.dumps({
        'contract': contract_id,
        'borrower': borrower_id,
        'due_date': to_timestamp(due_date),
        'amount': from_decimal(amount),
    })


def to_timestamp(dt):
    """Convert a datetime instance to timestamp.

    Args:
        dt (datetime.datetime): date to be converted.

    Returns:
        int

    """
    return calendar.timegm(dt.timetuple())


def from_decimal(dc):
    """Convert a decimal value into a string.

    Args:
        dc (decimal.Decimal): value to be converted.

    Returns:
        str

    """
    return str(dc)
