#!/bin/bash
set -e
. /opt/homebrew/Caskroom/miniforge/base/etc/profile.d/conda.sh
conda env remove --name {{cookiecutter.name}}
cat << EOF > test_environment.yml
name: {{cookiecutter.name}}
channels:
    - conda-forge
# NOTICE:
#   setup.py is authoritative for production use.
#   Synchronize critical common production dependency versions
#   between this file and setup.py
dependencies:
    - python>=3.9
    - psycopg2-binary>=2.8.6
    - pymssql>=2.2.3
EOF
tr '\n' , < setup.py | grep -o "INSTALL_REQUIRES =.*TEST_REQUIRES =" | tr , '\n' | egrep '^    "' | awk -F\" '{print "    - "$2}' | \
    sed 's/==/=/g' | \
    sed 's/pip.*$/pip/g' | \
    sed 's/setuptools>.*$/setuptools/g' | \
    sed 's/setuptools_scm[toml]>.*$/setuptools_scm[toml]/g' >> test_environment.yml
conda env create -f test_environment.yml && \
conda activate {{cookiecutter.name}} && \
pip install pre-commit &&  pre-commit install && pip install -e ".[all]"
rm test_environment.yml
