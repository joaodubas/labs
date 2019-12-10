#!/usr/bin/env bash
export PATH=/cockroach:$PATH
cockroach user set maxroach --certs-dir /certs --host db_one
cockroach sql --certs-dir /certs --host db_one -e 'CREATE DATABASE IF NOT EXISTS bank'
cockroach sql --certs-dir /certs --host db_one -e 'GRANT ALL ON DATABASE bank TO maxroach'
