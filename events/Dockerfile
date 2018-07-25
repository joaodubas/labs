FROM python:2.7

RUN pip install poetry

ADD pyproject.lock /tmp
ADD pyproject.toml /tmp

WORKDIR /tmp
RUN poetry install

ADD ./ /opt/app
WORKDIR /opt/app
