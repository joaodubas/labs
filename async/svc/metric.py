from __future__ import absolute_import, unicode_literals

import logging

import influxdb


class Emitter(object):
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
        return self.create_database(self.DBNAME)

    def write(self, data):
        self.logger.info('Send metric {}'.format(data))
        return self.client.write_points([data])


client = emitter()
