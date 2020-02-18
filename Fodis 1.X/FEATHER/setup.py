# force floating point division. Can still use integer with //
from __future__ import division
# other good compatibility recquirements for python3
from __future__ import absolute_import
from __future__ import print_function
from __future__ import unicode_literals
from setuptools import setup


def run():
    setup(name='FEATHER dependencies',
          version='0.0',
          url='https://github.com/prheenan/AppFEATHER.git',
          author='Patrick Heenan',
          author_email='patrick.heenan@colorado.edu',
          license='MIT',
		  packages=["."],
          install_requires=[
              'scipy',
              'numpy',
              'h5py',
              'matplotlib',
          ],
          zip_safe=False)

if __name__ == "__main__":
    run()
