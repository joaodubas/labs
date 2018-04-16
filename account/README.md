# Cockroach replicated db

This is a sample app that shows how to setup and use a secure and replicated cockroach setup.

## Setup

First of all, it's necessary to create the certificates:

```bash
./scripts/cockroachdb/certs.sh
```

## Running

To execute the databases start the proxy service:

```bash
docker-compose up -d proxy
```

To execute the go app:

```bash
docer-compose up svc
```