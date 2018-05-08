#!/usr/bin/env python

"""
setup.py file for SWIG example
"""

from distutils.core import setup, Extension


example_module = Extension('_pyattyscomm',
                           sources=['pyattyscommPYTHON_wrap.cxx'],
                           extra_compile_args=['-std=c++11'],
                           libraries=['attyscomm','bluetooth'],
                           )

setup (name = 'pyattyscomm',
       version = '1.0',
       author      = "Glasgow Neuro LTD",
       description = """AttysComm""",
       ext_modules = [example_module],
       py_modules = ["pyattyscomm"],
       )
