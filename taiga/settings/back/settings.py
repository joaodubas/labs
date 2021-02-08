SECRET_KEY = '9%pno@m688el28@2+^y4v^&6wluqk-g#j#d7$dsjtht)o30dn1'

BASE_URL = 'https://taiga.dubas.dev'
MEDIA_URL = f'{BASE_URL}/media/'
STATIC_URL = f'{BASE_URL}/static/'
SITES['front']['scheme'] = 'https'
SITES['front']['domain'] = 'taiga.dubas.dev'

ALLOWED_HOSTS = [
    '127.0.0.1',
    'localhost',
    'server',
    'taiga.dubas.dev',
]

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'taiga',
        'USER': 'taiga',
        'PASSWORD': 'changeme',
        'HOST': 'database',
        'PORT': '5432',
    }
}

EVENTS_PUSH_BACKEND = "taiga.events.backends.rabbitmq.EventsPushBackend"
EVENTS_PUSH_BACKEND_OPTIONS = {"url": "amqp://guest:guest@taiga_broker/taiga"}
