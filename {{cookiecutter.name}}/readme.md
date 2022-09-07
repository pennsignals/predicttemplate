# {{cookiecutter.name}}

{{cookiecutter.description}}

[![Release](https://github.com/pennsignals/{{cookiecutter.name}}/actions/workflows/release.yml/badge.svg)](https://github.com/pennsignals/{{cookiecutter.name}}/actions/workflows/release.yml)

[![Test](https://github.com/pennsignals/{{cookiecutter.name}}/actions/workflows/test.yml/badge.svg)](https://github.com/pennsignals/{{cookiecutter.name}}/actions/workflows/test.yml)

## Prerequisites

1. Use bash / ksh linux command line
2. Use git version control from the command line
3. Use docker and docker-compose from the command line
4. Use jupyterlab
5. Use modern python >= 3.9 and python modules for Data Science / ML
6. Use setup.py and anaconda's environment.yaml to manage trained model dependencies along with isolated python virtual environments
7. Requirement for drift monitoring
8. Requirement for feature / evidence / prediction storage / procenance / tracability in operations
9. Requirement to manage secrets across environments and keep them out of version control
10. Requirement manage configuration across environments
11. Possible requirement to publish predictions into the Electornic Medical Record System
12. Intent to deploy a containerized microservice by buildng a python module that uses a trained model or heuristic asset

## Workflow

Use the jupyterlab container `docker compose up --build jupyterlab` for your data science exploration and development. Submit feature requests and bugs as issues against the template.

Use the postgres container `docker compose up --build postgres` for testing schema creation, and for your local feature, evidence, and prediction storage.

Use the pgadmin container `docker compose up --build pgadmin`, psql command line, or a database client like dbeaver of datagrip to interact with the containerized postgres database directly.

Use the grafana container `docker compose up --build grafana` to see drift monitoring and debug postgres functions for drift monitoring and generation of synthetic data.

Before model training, schedule a review of the queries and feature vectors:

1. Use `snake_case` for column names, feature names, and table names. Avoid any assumptions about downstream system case sensitivity of metadata, `snake_case` is safest.
2. Use &lg; `as_of` datetime in all queries. Avoid "cheating on the test" during model training by reading future data that will not be available in real time operations. Allow different versions of the model to be compared on historical data sets by making the queries deterministic as possible using `as_of`.
3. Use the canonical `closed-open` form for all intervals: e.g. `interval_begin` &lte; `admitted_datetime` &lt; `interval_end` to eliminate one-off errors and reprocessing/duplication of data that should be in disjoint data sets. The `closed open` form is read as, "from interval_begin inclusive up to but not including interval_end". Do NOT use `between` in sql queries which includes both the begin AND the end of the the interval.
4. The `as_of` datetime is typically also the `interval_end`.

After model training, complete the python module using git, precommit, and tests.

Schedule a review of the python code, lint ignores in the code and lint ignores in pyproject.toml.

Run predict `docker compose up --build predict` to run and debug the pipline.

Create a gold file of predictions with as_of and check it into version control `docker compose up create-gold`.

Updates to the python module and sql code shall verify that the gold file has not changed using gold file validation `docker compose up validate gold`.

## Secrets / Env files

Do not check secrets into version control. Keep secrets in ./secrets/, ./predict/secrets/ directories that are protected by .gitignore rules.

Files:

    example.env     # in version control (DO NOT PUT REAL SECRETS HERE)
    docker.env      # use with local python venv or docker (NOT IN VERSION CONTROL)

Create a file for your development / docker secrets and update it:

    cp ./predict/secrets/example.env ./predict/secrets/docker.env

## Configuration

A single configuration is used across staging and production since env variables hide the variance in configuration. Update the model paths.

Files:

    configuration.yaml # in version control (PUSHED DURING DEPLOYMENT)
    docker.yaml        # in version control identical to configuration.yaml except with an as_of datetime for gold file creation
    test.yaml          # in version control used with pytest

### Brew python venv:

Install python once per development machine if needed:

    brew install python@3.9

Create a virtual env:

    /opt/homebrew/Cellar/python@3.9/3.9.&lt;tab-complete&gt;/bin/python3.8 -m venv .venv

Activate the virtual env:

    . .venv/bin/activate

Install module and pre-commit once per project:

    pip install -e ".[dev]"
    pre-commit install

Development Session:

    pytest
    ...
    pre-commit run --all-files
    ...
    git commit -m '...'
    ...

Deactivate:

    deactivate

### Brew conda venv:

This script will create the conda env and install pre-commit and the {{cookiecutter.name}} package

    ./scripts/create_conda.sh
    conda activate {{cookiecutter.name}}
    ...
    conda deactivate

To run the tests in a continuous TDD loop, where the tests will run whenever there are changes to the code:

    ./scripts/tdd.sh

Development Session:

    pytest
    ...
    pre-commit run --all-files
    ...
    git commit -m '...'
    ...

Deactivate:

    conda deactivate

## Pytest:

    pytest

Pytest uses ./predict/local/test.yaml and ./predict/secrets/example.env

## Pre-commit:

    pre-commit run --all-files

Black and some file format fixers run during pre-commit. All are fairly safe. A failed commit due to reformatting WILL require you to simply re-add the files modified and commit.

Specifically, black modifies code ONLY in a way that ensures that the code's meaning (parse tree) hasn't changed, so it is very safe.

The linters like pylint and flake8 that run during pre-commitand likely indicate real problems with the code.

The tests that run with pytest that run during pre-commit indicate real problems with the code.

## Git commit:

    git commit -m 'Fixed all the things'

Git commit runs pre-commit, but ONLY USING the files that are staged for commit. It will then unstash any modified files.

This ensures that pre-commit and the tests run on the code that will be checked in.

## Rebuild the postgres container and remove the docker volume if the database schema is changed.

    docker system prune
    docker volume prune

## CI/CD Lint & Test:

Runs pre-commit inside an isolated container. This is also what runs remotely in CI / CD:

    docker compose up --build test
    docker compose up --build pre-commit
    ...
    docker compose down

## Validation

Uses as_of from the docker.yaml configuration file and overwrites the gold file.

    create-gold -c ./predict/local/docker.yaml -e ./predict/secrets/docker.env

Uses as_of EMBEDED IN THE GOLD FILE from docker.yaml, not the as_of in the docker.yaml

    validate-gold -c ./predict/local/docker.yaml -e ./predict/secrets/docker.env

## Deploy Configuration

Deploy configuration will be found and used with partial automation speficied in `local/deploy_config.yml` to push service configuration to consul, and schedule templated nomad jobs.

CI / CD automation is incomplete for secrets, and postgres schema migration.
