"""Usage:
from svc import tasks
kw = {
    'start_date': (tasks.datetime.date.today() - tasks.datetime.timedelta(days=2)).strftime(tasks.DATE_FORMAT),
    'end_date': tasks.datetime.date.today().strftime(tasks.DATE_FORMAT),
    'email': 'joao.dubas@gmail.com'
}
rs = tasks.process_report.apply_async(kwargs=kw)

from svc import celery, metric, monitor
m = monitor.Monitor(celery.app, metric.client)
"""
from __future__ import absolute_import, unicode_literals, print_function

import csv
import datetime
import logging
import time
from collections import namedtuple
from cStringIO import StringIO

from celery import chain, chord, group

from .celery import app


DATE_FORMAT = '%Y-%m-%d'
logger = logging.getLogger('tasks')


@app.task
def process_failure(start_date, end_date, email):
    time.sleep(10)
    raise ValueError('What did you expected?')


@app.task(bind=True, max_retries=3)
def process_retry(self, start_date, end_date, email):
    try:
        raise ValueError('Live another day!')
    except ValueError as e:
        raise self.retry(countdown=1, exc=e)


Funnel = namedtuple(
    'Funnel',
    (
        'date',
        'signup_count',
        'signup_value',
        'approval_count',
        'approval_value',
        'denial_count',
        'denial_value',
        'failure_count',
        'failure_value',
    )
)


@app.task
def process_report(start_date, end_date, email):
    logger.info('Enqueue report process between {} - {} to {}'.format(
        start_date,
        end_date,
        email
    ))

    start = datetime.datetime.strptime(start_date, DATE_FORMAT)
    end = datetime.datetime.strptime(end_date, DATE_FORMAT)
    return chord(generate_lines(start, end))(report_generator.s(email))


@app.task
def report_generator(lines, email):
    logger.info('Generate report for customer {}'.format(email))

    stream = StringIO()
    writer = csv.writer(stream)
    writer.writerow(Funnel._fields)
    writer.writerows(lines)
    stream.seek(0)

    return stream.getvalue(), email


def generate_lines(start_date, end_date):
    logger.info(
        'Enqueue lines processing for period {:%Y-%m-%d} - {:%Y-%m-%d}'.format(
            start_date,
            end_date
        )
    )

    curr_date = start_date
    while curr_date <= end_date:
        yield process_line(curr_date)
        curr_date += datetime.timedelta(days=1)


def process_line(curr_date):
    logger.info('Enqueue line processing for date {:%Y-%m-%d}'.format(
        curr_date
    ))

    dt = curr_date.strftime(DATE_FORMAT)
    return chord(
        [
            signup_by_date.s(dt),
            approval_by_date.s(dt),
            denial_by_date.s(dt),
            failure_by_date.s(dt),
        ],
        line_for_date.s(dt)
    )


@app.task
def line_for_date(cols, dt):
    logger.info('Processing line for period {}'.format(dt))

    funnel = create_funnel(cols, dt)
    return funnel._asdict().values()

@app.task
def signup_by_date(dt):
    return {'count': 1, 'value': 1, 'step': 'signup'}


@app.task
def approval_by_date(dt):
    return {'count': 1, 'value': 1, 'step': 'approval'}


@app.task
def denial_by_date(dt):
    return {'count': 1, 'value': 1, 'step': 'denial'}


@app.task
def failure_by_date(dt):
    return {'count': 1, 'value': 1, 'step': 'failure'}


def create_funnel(cols, dt):
    kw = {'date': dt}
    for cell in cols:
        kw['{}_count'.format(cell['step'])] = cell['count']
        kw['{}_value'.format(cell['step'])] = cell['value']
    return Funnel(**kw)
