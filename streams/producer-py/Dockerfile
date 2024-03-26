FROM python:3.12.2

RUN pip install poetry

WORKDIR /usr/local/src/app
ADD pyproject.toml /usr/local/src/app/
ADD poetry.lock /usr/local/src/app/
RUN poetry install
ADD . /usr/local/src/app
ENTRYPOINT [ "poetry", "run" ]
