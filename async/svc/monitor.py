from __future__ import absolute_import, unicode_literals

import logging

EVENT_MAP = (
    'task-sent',
    'task-received',
    'task-started',
    'task-succeeded',
    'task-failed',
    'task-rejected',
    'task-revoked',
    'task-retried',
    'worker-online',
    'worker-heartbeat',
    'worker-offline',
)


class Monitor(object):
    """Monitor tasks/worker celery events.

    Arguments:
        app (celery.Celery): application instance to be monitored.

    Attributes:
        app (celery.Celery): application monitored.
        state (celery.events.state.State): application cluster state.
        logger (logging.Logger): logging instance.

    """
    def __init__(self, app):
        self.app = app
        self.state = app.events.State()
        self.logger = logging.getLogger('tasks')
        self.logger.info('Configure monitor')

    def __call__(self):
        event_to_method = lambda ev: ev.replace('-', '_')
        method_for_event = lambda ev: getattr(self, event_to_method(ev))
        handlers = {ev: method_for_event(ev) for ev in EVENT_MAP}

        with self.app.connection() as conn:
            receiver = self.app.events.Receiver(
                conn,
                handlers=handlers
            )
            receiver.capture(limit=None, timeout=None, wakeup=None)
        
            self.logger.info('Register event handlers {}'.format(handlers))

    def task_sent(self, event):
        self.logger.info(event)

    def task_received(self, event):
        self.logger.info(event)

    def task_started(self, event):
        self.logger.info(event)

    def task_succeeded(self, event):
        self.logger.info(event)

    def task_failed(self, event):
        self.logger.info(event)

    def task_rejected(self, event):
        self.logger.info(event)

    def task_revoked(self, event):
        self.logger.info(event)

    def task_retried(self, event):
        self.logger.info(event)

    def worker_online(self, event):
        pass

    def worker_heartbeat(self, event):
        pass

    def worker_offline(self, event):
        pass

    def _task(self, task_uuid):
        return self.state.tasks.get(task_uuid)