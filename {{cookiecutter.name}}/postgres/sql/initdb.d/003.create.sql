set search_path = public;

create extension if not exists btree_gist;
create extension if not exists tablefunc;

create schema if not exists {{cookiecutter.name}};
grant usage on schema {{cookiecutter.name}} to public;

create user if not exists {{cookiecutter.name}} with password 'password';
grant usage on schema {{coockiecutter.name}} to {{cookiecutter.name}};
grant all privileges on all tables in schema {{cookiecutter.name}} to {{cookiecutter.name}};
alter default privileges in schema {{cookiecutter.name}} grant all privileges on tables to {{cookiecutter.name}};
