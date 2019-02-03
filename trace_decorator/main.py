#!/usr/bin/env python
# encoding: utf-8
from __future__ import unicode_literals, print_function

from greeter import greeter


def ola():
    return mundo()


def mundo():
    return greeter()


if __name__ == '__main__':
    print(ola())