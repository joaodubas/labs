# encoding: utf-8
from __future__ import unicode_literals, print_function
import os
import traceback
from functools import wraps

TRACE_UPPER_LIMIT = 5  # limit stack trace depth up to this.


def trace_decorator(fn):
    # type: (Callable[]) -> Callable[]
    """Decorate a method to get a traceback from it's execution.

    Args:
        fn: callable being decorated.
    
    Returns:
        Callable: decorated callable.
    
    """
    @wraps(fn)
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
    # type: (Tuple[str, int, str, Any]) -> str
    """Format traceback entry into a string with common parts.

    Args:
        traceback_line: tuple fetched from traceback.
    
    Returns:
        str: representing traceback line.
    
    """
    file_name, line_number, module_name, _ = traceback_line
    return '{}:{}#{}'.format(
        os.path.relpath(file_name),
        module_name,
        line_number
    )
