FROM python:3.6

WORKDIR /usr/local/src/app
ADD Pipfile.lock /usr/local/src/app/Pipfile.lock
ADD Pipfile /usr/local/src/app/Pipfile
RUN pip install pipenv
RUN pipenv install
ENTRYPOINT [ "pipenv", "run" ]