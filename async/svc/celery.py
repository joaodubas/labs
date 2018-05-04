from __future__ import absolute_import, unicode_literals
from celery import Celery

app = Celery(
    'tasks',
    backend='redis://result:6379/0',
    broker='pyamqp://guest@broker:5672//',
    include=['svc.tasks']
)

if __name__ == '__main__':
    app.start()