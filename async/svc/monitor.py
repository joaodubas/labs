from __future__ import absolute_import, unicode_literals

import json
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
    """Configure monitoring for tasks/worker celery events.

    Args:
        app (celery.Celery): application instance to be monitored.
        emitter (.monitor.Emitter): metric emitter instance.

    Attributes:
        app (celery.Celery): application monitored.
        emitter (.monitor.Emitter) metric emitter instance.
        state (celery.events.state.State): application cluster state.
        logger (logging.Logger): logging instance.

    """
    def __init__(self, app, emitter):
        self.app = app
        self.state = app.events.State()
        self.logger = logging.getLogger('tasks.monitor')
        self.logger.info('Configure monitor')

    def __call__(self):
        self._dummy_listen()

    def _dummy_listen(self):
        with self.app.connection() as conn:
            receiver = self.app.events.Receiver(
                conn,
                handlers={'*': self._event_handler}
            )
            receiver.capture(limit=None, timeout=None, wakeup=True)

            self.logger.info('Register dummy event handler')

    def _listen(self):
        event_to_method = lambda ev: ev.replace('-', '_')
        method_for_event = lambda ev: getattr(self, event_to_method(ev))
        handlers = {ev: method_for_event(ev) for ev in EVENT_MAP}

        with self.app.connection() as conn:
            receiver = self.app.events.Receiver(
                conn,
                handlers=handlers
            )
            receiver.capture(limit=None, timeout=None, wakeup=True)
        
            self.logger.info('Register event handlers {}'.format(handlers))

    def task_sent(self, event):
        self._event_handler(event)

    def task_received(self, event):
        self._event_handler(event)

    def task_started(self, event):
        self._event_handler(event)

    def task_succeeded(self, event):
        self._event_handler(event)

    def task_failed(self, event):
        self._event_handler(event)

    def task_rejected(self, event):
        self._event_handler(event)

    def task_revoked(self, event):
        self._event_handler(event)

    def task_retried(self, event):
        self._event_handler(event)

    def worker_online(self, event):
        pass

    def worker_heartbeat(self, event):
        pass

    def worker_offline(self, event):
        pass

    def _event_handler(self, event):
        # self.logger.info(event)
        if 'uuid' in event:
            task = self._task(event)
            self.logger.info(task.__class__)
            # self.logger.info(task.__dict__)

    def _task(self, event):
        """Fetch task for a given event state.

        Args:
            event (dict):

        Returns:
            celery.events.state.Task

        """
        self.state.event(event)
        return self.state.tasks.get(event['uuid'])


def writer(message):
    with open('svc/events.txt', 'a') as stream:
        stream.write('\n')
        stream.write(json.dumps(message))
        stream.write('\n')
