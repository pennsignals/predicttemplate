#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""See configuration in pyproject.toml and setup.cfg."""

from setuptools import find_packages, setup

INSTALL_REQUIRES = (
    (
        "dsdk[psycopg2,pymssql]@"
        "git+https://github.com/pennsignals/dsdk.git"
        "@1.5.6#egg=dsdk"
    ),
    "numpy>=1.22.0",
    "pandas>=1.3.5",
    "pip>=22.0.4",
    "python-dateutil",
    "scikit-learn>=1.0.2",
    "scipy>=1.7.3",
    "setuptools>=61.2.0",
    "setuptools_scm[toml]>=6.4.2",
    "wheel>=0.37.1",
)

TEST_REQUIRES = (
    "astroid",
    "black",
    "coverage[toml]",
    "cruft",
    "flake8",
    "flake8-bugbear",
    "flake8-commas",
    "flake8-comprehensions",
    "flake8-docstrings",
    "flake8-logging-format",
    "flake8-mutable",
    "flake8-sorted-keys",
    "mypy",
    "pep8-naming",
    "pre-commit",
    "pylint",
    "pytest",
    "pytest-cov",
    "types-pkg-resources",
    "types-python-dateutil",
    "types-pyyaml",
)

setup(
    entry_points={
        "console_scripts": [
            "predict = {{cookiecutter.name}}:Service.main",
            "create.gold = {{cookiecutter.name}}:Service.create_gold",
            "validate.gold = {{cookiecutter.name}}:Service.validate_gold",
            "pickle = {{cookiecutter.name}}:Model.pickle",
            # "publish.flowsheets = {{cookiecutter.name}}:Service.publish_flowsheets",
            # "publish.flowsheet = {{cookiecutter.name}}:Service.publish_flowsheet",
        ]
    },
    extras_require={"all": TEST_REQUIRES, "test": TEST_REQUIRES},
    include_package_data=True,
    install_requires=INSTALL_REQUIRES,
    packages=find_packages("predict/src"),
    package_dir={"": "predict/src"},
    python_requires=">=3.9",
    use_scm_version={"local_scheme": "dirty-tag"},
)
