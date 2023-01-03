# ---
# pylint: disable=pointless-statement
# jupyter:
#   jupytext:
#     cell_metadata_filter: -all
#     formats: ipynb,py:light
#     notebook_metadata_filter: -all,jupytext
#     text_representation:
#       extension: .py
#       format_name: light
#       format_version: '1.5'
#       jupytext_version: 1.14.4
# ---

"""Example."""

# +
from __future__ import annotations

from os import chdir
from typing import Any

from cfgenvy import Parser, YamlMapping, yaml_dumps
from dsdk import Mssql, Postgres
from pandas import DataFrame
from psycopg2.errors import UndefinedTable

# -

# ## Install
#
# If the module is needed, install it once, and reload the kernel:

chdir("/tmp")
try:
    from {{cookiecutter.name}} import Service

    _ = Service
except ImportError as error:
    # !pip install -e ".[dev]"
    raise RuntimeError(
        "Module has been installed, please restart the kernel"
    ) from error

# ## 2. Manage Configuration & Environment
#
# ### 2.1. Files
#
# Because deserializing objects is less error prone than (re-)configuring previously existing python objects, use cfgenvy to load and dump yaml as configuration. Merge environment variable files into yaml configuration during deserialization, and keep your secrets separate and safe.
#
# Secrets as well as differences among deployment environments are placed in .env files: `./predict/secrets/`.
#
# Configurations are placed in .yaml files: `./predict/local/`.
#
# These directories have .gitignore protection from accidental inclusion in version control. See the `./predict/secrets/.gitignore` and `./predict/local/.gitignore` files for file names that *ARE* included in version control.

chdir("/tmp")
config_file = "./predict/local/notebook.example.yaml"
env_file = "./predict/secrets/notebook.example.env"

# Service names are resolved to host ip addresses by docker DNS as listed in docker-compose.override.yaml, and later by consul DNS in production. Use service names when possible instead of ip addresses. Even names for external services external like clarity, and epic can be registered in consul DNS to keep ip addresses out of configuration files.
#
# Here the MSSQL_HOST and POSTGRES_HOST are service names:

envs_str = """
EPIC_COOKIE=cookie
MSSQL_DATABASE=clarity
MSSQL_HOST=mssql
MSSQL_PASSWORD=password
MSSQL_PORT=1433
MSSQL_USERNAME=username
POSTGRES_DATABASE=test
POSTGRES_HOST=postgres
POSTGRES_PASSWORD=password
POSTGRES_PORT=5432
POSTGRES_SCHEMA=test
POSTGRES_USERNAME=postgres"""

with open(env_file, "w", encoding="utf-8") as fout:
    fout.write(envs_str)

cfgs_str = """
elixhauser:
  key1: val1
  key2: val2
  key3: val3
mssql: !mssql
  database: ${MSSQL_DATABASE}
  host: ${MSSQL_HOST}
  password: ${MSSQL_PASSWORD}
  port: ${MSSQL_PORT}
  schema: test
  sql: !asset
    path: ./predict/sql/mssql
    ext: .sql
  username: ${MSSQL_USERNAME}
postgres: !postgres
  database: ${POSTGRES_DATABASE}
  host: ${POSTGRES_HOST}
  password: ${POSTGRES_PASSWORD}
  port: ${POSTGRES_PORT}
  schema: test
  sql: !asset
    path: ./predict/sql/postgres
    ext: .sql
  username: ${POSTGRES_USERNAME}
stages:
- first
- second
- third"""

with open(config_file, "w", encoding="utf-8") as fout:
    fout.write(cfgs_str)

# Register classes as yaml types so they may be deserialized as instaces of python classes:

# +
Mssql.as_yaml_type()
Postgres.as_yaml_type()

cfg = Parser.load(
    config_file=config_file,
    env_file=env_file,
)

print(f"type(cfg): {type(cfg)}")
print(f"type(cfg['elixhauser']: {type(cfg['elixhauser'])}")
print(f"type(cfg['postgres']: {type(cfg['postgres'])}")
print(f"type(cfg['postgres'].sql: {type(cfg['postgres'].sql)}")
print(f"type(cfg['stages']): {type(cfg['stages'])}")
# -

# Create and register a class to provide better validation for confguration and by ensuring that the configuration file is not mismatched, use explicit yaml `!<type>` and a class. Unlike a python dictionary, unexpected or missing keywords will raise early exceptions.

with open(config_file, "w", encoding="utf-8") as fout:
    fout.write("!cfg" + cfgs_str)


class Cfg(YamlMapping):
    """Cfg."""

    YAML = "!cfg"

    def __init__(
        self,
        *,
        elixhauser: dict[str, str],
        mssql: Mssql,
        postgres: Postgres,
        stages: list,
    ):
        """__init__."""
        self.elixhauser = elixhauser
        self.mssql = mssql
        self.postgres = postgres
        self.stages = stages

    def as_yaml(self) -> dict[str, Any]:
        """As yaml."""
        return {
            "elixhauser": self.elixhauser,
            "mssql": self.mssql,
            "postgres": self.postgres,
            "stages": self.stages,
        }


# +
Cfg.as_yaml_type()

cfg = Parser.load(
    config_file=config_file,
    env_file=env_file,
)

print(f"type(cfg): {type(cfg)}")
print(f"type(cfg.elixhauser): {type(cfg.elixhauser)}")
print(f"type(cfg.postgres): {type(cfg.postgres)}")
print(f"type(cfg.postgres.sql): {type(cfg.postgres.sql)}")
print(f"type(cfg.stages): {type(cfg.stages)}")
# -

postgres = cfg.postgres

# Debug the final merged configuration:

print(yaml_dumps(postgres))

# ## 3. Check Database Connectivity

with postgres.rollback() as cursor:
    cursor.execute("""select 'Very database, much wow!' as doge""")
    rows = cursor.fetchall()
    print(rows[0])

# ## 4. Manage SQL & Other Text Assets
#
# Assets loads text files from disk. Unlike SQL embedded in python strings, SQL syntax highlighting may be available in text editor. The python placeholders expected by psycopg2 and pymssql will still be marked as errors.

print(postgres.sql.predictions.gold)

# # 5. Rethink SQL

# +
keys = {
    "cohort": ("00001", "00002", "00003"),
    "conditions": ("sleepy", "happy", "grumpy"),
}

parameters = {
    "cohort_begin": "2021-05-05",
    "cohort_end": "2021-05-06",
    "dry_run": 0,
}
# -

# ## 5.1. Prefer `with` over `in (?, ...)`:
#
# Avoid `in` for more than a few elements:
#
# `select * from patients where id in ('00001', '00002', '00003', ...);`
#
# Unfortunately, the execution plan renders `in` similar to multiple `or`:
#
# `select * from patients where id = '00001' or id = '00002' or id = '00003' ...;`
#
# The performance is terrible. The database has limits on the number of elements that may be included using `in (?, ...)`. Fundamentally, the database does not treat `in` like a table with a single column, in part because the column data type is not known. Client languages like python typically only have data types that approximately match the database's data types. For example the pymssql driver passes all python strings to mssql as `nvarchar` literals ('n' is not a typo). Each element is coherced to the most permissive data type during comparison. This implicit, permissive casting and cohersion prevents indices from being used.
#
# Use `with` instead and `cast` the column to the appropriate data type.

# ### 5.1.1. Example:
#
# An easy example in templated sql for python and dsdk looks like this:

# +
query_5_1_1 = """
with cohort as (
    -- data type is on the cohort.id column, not just this first row
    select cast(null as varchar(8)) as id
    {cohort}
)
select
    id
from
    cohort
where
    id is not null;"""

with postgres.rollback() as cur:
    df = postgres.df_from_query(
        cur,
        query_5_1_1,
        keys=keys,
        parameters=parameters,
    )
df
# -

# ### 5.1.2. Example:
#
# A more useful example using dsdk looks like this:

# +
query_5_1_2 = """
with args as (
    select
        cast(%(cohort_begin)s as timestamptz) as cohort_begin,
        cast(%(cohort_end)s as timestamptz) as cohort_end
), cohort as (
    select cast(null as varchar(8)) as id
    {cohort}
), conditions as (
    select cast(null as varchar(16)) as name
    {conditions}
)
select
    cohort_begin,
    cohort_end,
    id,
    name
from
    args
    join cohort
        on id is not null
    join conditions
        on name is not null;
"""

with postgres.rollback() as cur:
    df = postgres.df_from_query(
        cur,
        query_5_1_2,
        keys=keys,
        parameters=parameters,
    )
df
# -

# ### 5.1.3. Example
#
# Implementation of dsdk for df_from_query_by_keys uses `union all select` implementation. This formulation avoids item limits as well as comma counting of `insert (...) values (...), ...`. Unlike `in` and `insert (...) values (...), ...` it also results in perfectly valid sql even when the cohort or conditions lists are empty, because the empty lists render as code while retaining the column data type(s) using the "null row".
#
# Unwind the sequences and replace the placeholders in pgadmin, DBeaver, Data Grip, and Microsort Sql Server Management Studio to test and explain your queries:

# +
query_5_1_3 = """
with args as (
    select
        cast('2021-05-05' as timestamptz) as cohort_begin,
        cast('2021-05-06' as timestamptz) as cohort_end
), cohort as (
    select cast(null as varchar) as id
    union all select '00001'
    union all select '00002'
    union all select '00003'
), conditions as (
    select cast(null as varchar) as name
    union all select 'happy'
    union all select 'sleepy'
    union all select 'grumpy'
)
select
    cohort_begin,
    cohort_end,
    id,
    name
from
    args
    join cohort
        on id is not null
    join conditions
        on name is not null;"""

with postgres.rollback() as cur:
    cur.execute(query_5_1_3)
    rows = cur.fetchall()
    df = DataFrame(rows)
    columns = (each[0] for each in cur.description)
    df.columns = columns

df
# -

# ## 5.2 Use dry run to fail early
#
# Make the database do more work for you. This includes validating some syntax and all permission on the service accounts BEFORE passing actual useful data to the database.

query_5_2 = """
with vars as (
    select
        cast(coalesce(%(dry_run)s, 1) as int) as dry_run,
        cast(%(cohort_begin)s as timestamptz) as cohort_begin,
        cast(%(cohort_end)s as timestamptz) as cohort_end
), cohort as (
    select cast(null as varchar) as id
    {cohort}
)
select
    no_such_table.*
from
    vars as v
    join cohort as c
        on v.dry_run = 0
        and c.id is not null;"""

try:
    postgres.dry_run_query(query_5_2, parameters)
except UndefinedTable as e:
    print(e)
else:
    raise RuntimeError("UndefinedTable exceptions expected.")

# Persistors can dry run all sql queries in an asset if all parameters are provided. All queries must be written to select, insert, update or delete no data when dry_run is 1, but should be written to produce empty data sets for insert, update, and delete instead of merely exiting early which will NOT check privileges.
#
# Typically, this means using a `with` clause to build a data set for insert, update or delete and performing a join on `dry_run = 0` that knocks out all rows from the data manipulation operators.
#
# More examples to come, and all queries in the postgres persistor asset must be revised for dry_run compatibility.
#
# More examples to come on when to add unused tables to aquire indices.
#
# More examples to come on sql performance profiling and explain.
#
# More example on when using temp tables may be an advantage, and the impact on readability, maintainability, and testing.
#
