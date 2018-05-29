# celery experiments

Experimenting with celery canvas, specially, with nested coords. Besides that,
giving some visibility to celery, exploring the real-time processing to monitor
queues with influxdb.

## TODO

* [ ] measure revoked/rejected tasks.
* [ ] measure worker.
* [ ] make external connections resilient (eyes on rabbitmq and influxdb).

## Notes

How about take some inspiration from [zerok prometheus exporter][0].

[0]: https://github.com/zerok/celery-prometheus-exporter
