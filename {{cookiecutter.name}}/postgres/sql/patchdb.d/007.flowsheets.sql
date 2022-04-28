set search_path = {{cookiecutter.name}};


create or replace function up_flowsheets()
returns void as $$
begin
    if not install('flowsheets'::varchar, array['public']::varchar[]) then
        return;
    end if;

    create table flowsheets (
        id int primary key,
        created_on timestamptz not null default now(),
        profile int8range not null,
        constraint only_one_flowsheet_per_prediction
            unique (id),
        constraint flowsheets_requires_a_prediction
            foreign key (id) references predictions (id)
            on delete cascade
            on update cascade
    );

    create table flowsheet_errors (
        id int primary key generated always as identity,
        prediction_id int not null,
        recorded_on timestamptz not null default now(),
        acknowledged_on timestamptz default null,
        name varchar not null,
        description varchar,
        status_code int,
        text varchar,
        profile int8range not null,

        constraint flowsheet_errors_requires_a_prediction
            foreign key (prediction_id) references predictions (id)
            on delete cascade
            on update cascade
    );

    create function missing_flowsheets(
        begin_id int default 0,
        end_id int default 2147483647,
        dry_run int default 0
    )
    returns table (
        id int,
        run_id int,
        csn int,
        empi varchar(64),
        score double precision,
        as_of timestamptz
    ) as
    $function$
    begin
        return query
        select
            p.id,
            p.run_id,
            p.csn,
            p.empi,
            p.score,
            r.as_of
        from
            predictions as p
            join runs as r
                on r.id = p.run_id
                and upper(r.duration) != 'infinity'
                and dry_run = 0
                and begin_id <= p.id and p.id < end_id
                -- cannonical, correct form is a closed-open interval: begin_id <= target < end_id
                -- end_id IS NOT included in the range
                -- Use `select last_value + 1 from predictions_id_seq` to get end_id beyond the max(id)
                --    without even touching the table
            left join flowsheets as f
                on f.id = p.id
            left join flowsheet_errors as e
                on e.prediction_id = p.id
                and e.acknowledged_on is null
        where
            f.id is null
            and e.id is null
        order by
            r.id desc, p.id desc;
    end
    $function$
        language plpgsql
        set search_path = {{cookiecutter.name}};
end;
$$ language plpgsql;


create or replace function down_flowsheets()
returns void as
$$
begin
    if not uninstall('epic.flowsheets'::varchar) then
        return;
    end if;

    drop function missing_flowsheets;
    drop table flowsheet_errors;
    drop table flowsheets;
end;
$$ language plpgsql;


select up_flowsheets();
