import flask

app = flask.Flask(__name__)


@app.route('/')
def home():
    return 'Hello world'


@app.route('/_health')
def health():
    return 'OK'
