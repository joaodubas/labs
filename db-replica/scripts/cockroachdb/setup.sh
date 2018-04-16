#!/usr/bin/env bash
export PATH=/cockroach:$PATH
cockroach user set maxroach --insecure
cockroach sql --insecure -e 'CREATE DATABASE IF NOT EXISTS bank'
cockroach sql --insecure -e 'GRANT ALL ON DATABASE bank TO maxroach'