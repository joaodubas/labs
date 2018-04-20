FROM local-app as base

FROM ubuntu:18.04

RUN apt-get update \
    && apt-get install -y curl gpg
RUN curl https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor > microsoft.gpg
RUN mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" \
        > /etc/apt/sources.list.d/vscode.list
RUN apt-get update \
    && apt-get install -y code

RUN apt-get update \
    && apt-get install -y python3 python3-setuptools python3-pip \
    && pip3 install --upgrade pip

ENV HOME_APP /opt/app
ENV FLASK_APP ${HOME_APP}/app.py
COPY ./src ${HOME_APP}
RUN pip install -r /opt/app/requirements.txt
