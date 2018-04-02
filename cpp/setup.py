"""
setup.py file for pyattyscomm
"""

from distutils.core import setup
import site

setup (name = 'pyattyscomm',
       version = '1.0',
       author      = "Bernd Porr",
       description = """Attys Comm""",
       py_modules = ["pyattyscomm"],
       data_files= [(site.getsitepackages()[0],['_pyattyscomm.so'])],
       )
