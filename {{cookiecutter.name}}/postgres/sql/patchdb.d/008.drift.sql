set search_path = {{cookiecutter.name}};

create or replace function up_drift()
returns void as
$$
begin
    if not install('drift'::varchar, array['public']::varchar[]) then
        return;
    end if;

    create type doublerange as range (
        subtype=double precision
    );

    -- testing indicates that repeated calculations like count(1), variance(...), avg(...)
    --    are computed once for a query (they are stable because the dataset doesn't change)
    --    this allows us to select d.* without duplicating calculations
    -- if this ends up not being the case, do primary calculations in the lateral join
    --    and use the results in compount calculations instead of `select ... d.*`
    --    but this is verbose and requires yet more column names
    -- one weakness is potentially mismatched return table definitions and query columns
    --    when adding more columns during revision.
    -- stable and immutable functions can be inlined by the optimizer only if they do indeed
    --    call only stable and immutable functions.

    create function duration_drift(
        _microservice_versions varchar[],
        _model_versions varchar[],
        _from timestamptz,
        _to timestamptz
    )
    returns table (
        "time" timestamptz,
        duration double precision
    )
    as $function$
    begin
        return query
        with args as (
            select tstzrange(_from, _to, '[)') as _range
        ), microservice_ids as (
            select
                microservices.id
            from
                unnest(_microservice_versions) as versions
            join microservices on
                microservices.version = versions
        ), model_ids as (
            select
                models.id
            from
                unnest(_model_versions) as versions
            join models on
                models.version = versions
        )
        select
            r.as_of,
            extract(epoch from (upper(r.duration) - lower(r.duration))) as duration
        from
            microservice_ids
            cross join model_ids
            join runs as r
                on r.microservice_id = microservice_ids.id
                and r.model_id = model_ids.id
                and upper(r.duration) != 'infinity'
        order by as_of;
    end;
    $function$
        language plpgsql
        stable
        parallel safe
        set search_path = {{cookiecutter.name}};

    create function count_drift(
        _microservice_versions varchar[],
        _model_versions varchar[],
        _from timestamptz,
        _to timestamptz
    )
    returns table (
        "time" timestamptz,
        "count" bigint
    )
    as $function$
    begin
        return query
        with args as (
            select tstzrange(_from, _to, '[)') as _range
        ), microservice_ids as (
            select
                microservices.id
            from
                unnest(_microservice_versions) as versions
            join microservices on
                microservices.version = versions
        ), model_ids as (
            select
                models.id
            from
                unnest(_model_versions) as versions
            join models on
                models.version = versions
        )
        select
            r.as_of,
            d.*
        from
            args as a
            cross join microservice_ids
            cross join model_ids
            join runs as r
                on r.microservice_id = microservice_ids.id
                and r.model_id = model_ids.id
                and upper(r.duration) != 'infinity'
                and r.as_of <@ a._range -- element contained in range
            join lateral (
                select
                    count(1) as _count
                from
                    predictions as p
                where
                    p.run_id = r.id
                group by
                    p.run_id
        ) as d on true
        order by as_of;
    end;
    $function$
        language plpgsql
        stable
        parallel safe
        set search_path = {{cookiecutter.name}};

    create function score_drift(
        _microservice_versions varchar[],
        _model_versions varchar[],
        _from timestamptz,
        _to timestamptz,
        _ci_value double precision default 1.960
    )
    returns table (
        "time" timestamptz,
        average double precision,
        lower_ci double precision,
        upper_ci double precision
    )
    as $function$
    begin
        return query
        with args as (
            select tstzrange(_from, _to, '[)') as _range
        ), microservice_ids as (
            select
                microservices.id
            from
                unnest(_microservice_versions) as versions
            join microservices on
                microservices.version = versions
        ), model_ids as (
            select
                models.id
            from
                unnest(_model_versions) as versions
            join models on
                models.version = versions
        )
        select
            r.as_of,
            d.*
        from
            args as a
            cross join microservice_ids
            cross join model_ids
            join runs as r
                on r.microservice_id = microservice_ids.id
                and r.model_id = model_ids.id
                and upper(r.duration) != 'infinity'
                and r.as_of <@ a._range -- element contained in range
            join lateral (
                select
                    avg(p.score) as average
                from
                    predictions as p
                where
                    p.run_id = r.id
                group by
                    p.run_id
            ) as d on true
        order by as_of;
    end;
    $function$
        language plpgsql
        stable
        parallel safe
        set search_path = {{cookiecutter.name}};

    create function drift_panels()
    returns table (
        id int,
        title varchar,
        name varchar
    )
    as $function$
    begin
        return query
        with panels as (
            select
                cast(null as int) as id,
                cast(null as varchar) as title,
                cast(null as varchar) as name
            union all select 0, 'Example Duration', '{{cookiecutter.name}}.duration_drift'
            union all select 1, 'Example Count', '{{cookiecutter.name}}.count_drift'
            union all select 2, 'Example Score', '{{cookiecutter.name}}.score_drift'
        )
        select
            p.*
        from
            panels as p
        where
            p.id is not null
        order by
            p.id;
    end;
    $function$
        language plpgsql
        immutable
        parallel safe
        set search_path = {{cookiecutter.name}};
end;
$$
    language plpgsql
    set search_path = {{cookiecutter.name}};


create or replace function down_drift()
returns void as
$$
begin
    if not uninstall('drift'::varchar) then
        return;
    end if;

    drop function score_drift(varchar[], varchar[], timestamptz, timestamptz, double precision);
    drop function count_drift(varchar[], varchar[], timestamptz, timestamptz);
    drop function duration_drift(varchar[], varchar[], timestamptz, timestamptz);
    drop function drift_panels();
    drop type doublerange;
end;
$$
    language plpgsql
    set search_path = {{cookiecutter.name}};

select up_drift();
