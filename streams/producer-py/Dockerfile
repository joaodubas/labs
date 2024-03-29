FROM python:3.12.2
ARG POETRY_VERSION
ENV PATH /root/.local/bin:$PATH
RUN curl -sSL https://install.python-poetry.org | POETRY_VERSION=${POETRY_VERSION} python3 -
WORKDIR /usr/local/src/app
ADD pyproject.toml poetry.lock /usr/local/src/app/
RUN poetry install
ADD . /usr/local/src/app
ENTRYPOINT [ "poetry", "run" ]
