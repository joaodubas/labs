from __future__ import absolute_import, unicode_literals
import datetime

from celery import chain, chord, group

from .celery import app


DATE_FORMAT = '%Y-%d-%m'


@app.task
def process_report(start_date, end_date, email):
    start = datetime.datetime.strptime(start_date, DATE_FORMAT)
    end = datetime.datetime.strptime(end_date, DATE_FORMAT)
    tasks = []
    curr = start
    while curr <= end:
        tasks.append(process_line.s(curr.strftime(DATE_FORMAT)))
        curr += datetime.timedelta(days=1)
    return chord(tasks, report.s(email))()


@app.task
def report(lines, email):
    return lines, email


@app.task
def process_line(dt):
    return chord(
        [
            signup_by_date.s(dt),
            approval_by_date.s(dt),
            denial_by_date.s(dt),
            failure_by_date.s(dt),
        ],
        line_for_date.s(dt)
    )()

@app.task
def line_for_date(cols, dt):
    return cols.insert(0, dt)


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