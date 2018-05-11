from __future__ import absolute_import, unicode_literals

import datetime
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
        self.emitter = emitter
        self.logger = logging.getLogger('tasks.monitor')
        self.logger.info('Configure monitor')

    def __call__(self):
        self._listen()

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
        task = self._task(event)
        self._emit(
            event,
            task,
            0.0
        )

    def task_received(self, event):
        task = self._task(event)
        self._emit(
            event,
            task,
            duration(task.sent, task.received)
        )

    def task_started(self, event):
        task = self._task(event)
        self._emit(
            event,
            task,
            duration(task.received, task.started)
        )

    def task_succeeded(self, event):
        task = self._task(event)
        self._emit(
            event,
            task,
            duration(task.started, task.succeeded)
        )

    def task_failed(self, event):
        task = self._task(event)
        self._emit(
            event,
            task,
            duration(task.started, task.failed)
        )

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
        self.logger.info(event)
        if 'uuid' in event:
            task = self._task(event)
            self.logger.info(task.__class__)
            self.logger.info(task.__dict__)
        else:
            worker = self._worker(event)
            self.logger.info(worker.__class__)
            self.logger.info(worker.__dict__)

    def _task(self, event):
        """Fetch task for a given event state.

        Args:
            event (dict):

        Returns:
            celery.events.state.Task

        """
        self.state.event(event)
        return self.state.tasks.get(event['uuid'])

    def _worker(self, event):
        """Fetch worker for a given event state.

        Args:
            event (dict):

        Returns:
            celery.events.state.Worker

        """
        self.state.event(event)
        return self.state.workers.get(event['hostname'])

    def _emit(self, event, task, duration):
        metric = dict(
            measurement='tasks',
            fields={
                'count': 1,
                'duration_seconds': duration,
                'retries_count': task.retries,
            },
            tags={
                'worker': event['hostname'],
                'state': event['state'],
                'queue': task.name.rsplit('.', 1)[0],
                'task': task.name.rsplit('.', 1)[-1],
            },
            dt=datetime.datetime.fromtimestamp(event['timestamp']),
        )
        return self.emitter.emit(**metric)


def duration(start, end):
    """Calculate the difference between two timestamps.

    Args:
        start (Optional[float]): start time for the event.
        end (Optional[float]): end time for the event.
    
    Returns:
        float: representing the difference in seconds between end/start times.
            If one of times is `None`, a duration of 0.0 is returned.

    """
    if None in (start, end):
        return 0.0
    return end - start
