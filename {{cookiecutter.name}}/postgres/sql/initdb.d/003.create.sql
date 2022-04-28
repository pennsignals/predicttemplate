set search_path = public;

create extension if not exists btree_gist;
create extension if not exists tablefunc;
create extension if not exists pgtap;

create schema if not exists {{cookiecutter.name}};
grant usage on schema {{cookiecutter.name}} to public;
grant create on schema {{cookiecutter.name}} to public;
