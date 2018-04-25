#!/usr/bin/env python
# encoding: utf-8
from __future__ import unicode_literals
from decorator import trace_decorator


@trace_decorator
def greeter():
    return 'ola mundo'