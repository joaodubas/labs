from __future__ import absolute_import, unicode_literals

from celery import chain, chord, group

from .celery import app


@app.task
def line_for_date(cols, dt):
    return cols.insert(0, dt)


@app.task
def signup_by_date(dt):
    return 1


@app.task
def approval_by_date(dt):
    return 1


@app.task
def denial_by_date(dt):
    return 1


@app.task
def failure_by_date(dt):
    return 1