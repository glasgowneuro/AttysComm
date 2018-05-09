#!/usr/bin/env python3

"""
setup.py file for AttysComm
"""

from distutils.core import setup, Extension


attyscomm_module = Extension('_pyattyscomm',
                           sources=['pyattyscommPYTHON_wrap.cxx'],
                           extra_compile_args=['-std=c++11'],
                           libraries=['attyscomm','bluetooth'],
                           )

setup (name = 'pyattyscomm',
       version = '1.0',
       author      = "Glasgow Neuro LTD",
       description = """AttysComm""",
       ext_modules = [attyscomm_module],
       py_modules = ["pyattyscomm"],
       )
