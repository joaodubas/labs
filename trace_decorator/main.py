#!/usr/bin/env python
# encoding: utf-8
from __future__ import unicode_literals, print_function

from greeter import greeter
# from decorator import trace_decorator


def ola():
    return mundo()


def mundo():
    return greeter()


# greeter = trace_decorator(greeter)

if __name__ == '__main__':
    print(ola())