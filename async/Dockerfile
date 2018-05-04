FROM python:2.7
LABEL maintainer="Joao Paulo Dubas <joao.dubas@gmail.com>"
RUN pip install pipenv
ADD ./Pipfile /app/Pipfile
ADD ./Pipfile.lock /app/Pipfile.lock
ADD ./requirements.txt /app/requirements.txt
WORKDIR /app
RUN pipenv install --two --dev
VOLUME [ "/app/svc" ]