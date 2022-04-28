insert into cohorts (
    run_id,
    subject_id,
    description,
    kind,
    at
)
select
    %(run_id)s,
    %(subject_id)s,
    %(description)s,
    %(kind)s,
    %(at)s
returning *
