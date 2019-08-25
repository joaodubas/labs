FROM python:3.7
LABEL maintainer="Joao Paulo Dubas <joao.dubas@gmail.com>"
ENV PATH /root/.poetry/bin:$PATH
RUN curl -sSL https://raw.githubusercontent.com/sdispater/poetry/master/get-poetry.py | python \
  && /root/.poetry/bin/poetry completions bash > /etc/bash_completion.d/poetry.bash_completion
ADD ./pyproject.toml /pyproject.toml
ADD ./poetry.lock /app/poetry.lock
WORKDIR /app
RUN poetry install
VOLUME [ "/app/svc" ]
