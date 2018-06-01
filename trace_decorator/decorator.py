#!/usr/bin/env python
# encoding: utf-8
from __future__ import unicode_literals, print_function
import os
import traceback

TRACE_UPPER_LIMIT = 5  # limit stack trace depth up to this.


def trace_decorator(fn):
    def wrapper():
        rs = []
        for idx, tb in enumerate(traceback.extract_stack()):
            if idx > TRACE_UPPER_LIMIT:
                break
                os.path.relpath
            rs.append(format_traceback(tb))
        print(' >> '.join(rs))
        return fn()
    return wrapper


def format_traceback(traceback_line):
    file_name, line_number, module_name, _ = traceback_line
    return '{}:{}#{}'.format(
        os.path.relpath(file_name),
        module_name,
        line_number
    )
