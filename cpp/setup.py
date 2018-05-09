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
       version = '1.2.1',
       author      = "Bernd Porr",
       author_email = "bernd@glasgowneuro.tech",
       url = "https://github.com/glasgowneuro/AttysComm",
       license = "../LICENSE",
       description = """API for the Attys (www.attys.tech) under Linux""",
       ext_modules = [attyscomm_module],
       py_modules = ["pyattyscomm"],
       )
