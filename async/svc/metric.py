from __future__ import absolute_import, unicode_literals

import datetime
import logging

import influxdb
import pytz


class Emitter(object):
    """Emit metrics to influx database.

    Attributes:
        logger (logging.Logger): logging facility.
        client (influxdb.InfluxDBClient): influxdb client

    """
    DBNAME = 'async_metric'

    def __init__(self):
        self.logger = logging.getLogger('tasks.emitter')
        self.client = influxdb.InfluxDBClient(host='metric')
        self._setup()

    def _setup(self):
        self.logger.info('Setup metric database')
        dbs = [v['name'] for v in self.client.get_list_database()]
        if self.DBNAME in dbs:
            self.client.switch_database(self.DBNAME)
            return None

        self.client.switch_database(self.DBNAME)
        return self.client.create_database(self.DBNAME)

    def emit(self, measurement, fields, tags=None, dt=None):
        dt = self._zulu_aware_datetime(dt or datetime.datetime.utcnow())

        point = {
            'measurement': measurement,
            'fields': fields,
            'time': dt.strftime('%Y-%m-%dT%H:%M:%S.%f%Z')
        }
        if tags:
            point['tags'] = tags
        return self.write(point)

    def write(self, data):
        """Write given data in influxdb.

        Args:
            data (dict): having the keys:

        Returns:
            bool

        """
        self.logger.info('Send metric {}'.format(data))
        return self.client.write_points([data])

    def _zulu_aware_datetime(self, dt):
        """Convert a datetime into a tzinfo aware datetime.

        Args:
            dt (datetime.datetime): date to be made timezone aware.

        Returns
            datetime.datetime

        """
        z = Zulu()
        try:
            return z.localize(dt)
        except ValueError:
            return z.normalize(dt)
        return dt


class Zulu(pytz.utc.__class__):
    zone = 'Z'
    _tzname = zone

    def __str__(self):
        return self._tzname

    def __repr__(self):
        return '<{}>'.format(self._tzname)

    def tzname(self, dt):
        return self._tzname


client = Emitter()
