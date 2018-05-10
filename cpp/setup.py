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
       version = '1.2.1b',
       author      = "Bernd Porr",
       author_email = "bernd@glasgowneuro.tech",
       url = "https://github.com/glasgowneuro/AttysComm",
       description = 'API for the Attys',
       long_description = 'API for the DAQ box Attys (www.attys.tech) for Linux',
       ext_modules = [attyscomm_module],
       py_modules = ["pyattyscomm"],
       license='Apache 2.0',
       )
