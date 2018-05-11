#!/usr/bin/env python3

"""
setup.py file for AttysComm
"""

from distutils.core import setup, Extension
import os

def read(fname):
    return open(os.path.join(os.path.dirname(__file__), fname)).read()

attyscomm_module = Extension('_pyattyscomm',
                           sources=['pyattyscommPYTHON_wrap.cxx'],
                           extra_compile_args=['-std=c++11'],
                           libraries=['attyscomm','bluetooth'],
                           )

setup (name = 'pyattyscomm',
       version = '1.2.1b15',
       author      = "Bernd Porr",
       author_email = "bernd@glasgowneuro.tech",
       url = "https://github.com/glasgowneuro/AttysComm",
       description = 'API for the Attys DAQ box (www.attys.tech)',
       long_description=read('README_py'),
       ext_modules = [attyscomm_module],
       py_modules = ["pyattyscomm"],
       license='Apache 2.0',
       classifiers=[
          'Intended Audience :: Developers',
          'Operating System :: POSIX',
          'Programming Language :: Python'
          ]
      )
