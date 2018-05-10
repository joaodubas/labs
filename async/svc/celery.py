from __future__ import absolute_import, unicode_literals
import logging

from celery import Celery

app = Celery(
    'tasks',
    backend='redis://result:6379/0',
    broker='pyamqp://guest@broker:5672//',
    include=['svc.tasks'],
    worker_send_tasks_events=True,
    task_send_sent_event=True
)


def logger():
    # NOTE: get logger
    l = logging.getLogger('tasks')
    l.setLevel(logging.INFO)

    # NOTE: create handler
    s = logging.StreamHandler()
    s.setLevel(logging.INFO)

    # NOTE: define log format
    f = logging.Formatter('%(asctime)s | %(name)s | %(levelname)s | %(message)s')
    s.setFormatter(f)

    # NOTE: define handler for logger
    l.addHandler(s)

    return l

logger()
