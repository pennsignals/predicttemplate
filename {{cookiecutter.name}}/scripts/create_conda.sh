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
    - pip
    - pymssql>=2.2.3
EOF
tr '\n' , < pyproject.toml | grep -o "dependencies = .*predict =" | tr , '\n' | egrep -v "psycopg2-binary|dsdk|flake8-commas|flake8-sorted-keys|types-pkg-resources" | egrep '^    "' | awk -F\" '{print "    - "$2}' | sed 's/==/=/g' >> test_environment.yml
cat << EOF >> test_environment.yml
    - pip:
EOF
tr '\n' , < pyproject.toml | grep -o "dependencies = .*predict =" | tr , '\n' | egrep "dsdk|flake8-commas|flake8-sorted-keys|types-pkg-resources" | egrep '^    "' | awk -F\" '{print "      - "$2}' >> test_environment.yml
conda env create -f test_environment.yml && \
conda activate {{cookiecutter.name}} && \
pip install pre-commit && pre-commit install && pip install -e ".[dev]"
rm test_environment.yml
