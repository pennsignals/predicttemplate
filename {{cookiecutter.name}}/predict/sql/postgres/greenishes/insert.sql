insert into greenishes (
    run_id,
    subject_id,
    normal,
    at
)
select
    %(run_id)s,
    %(subject_id)s,
    %(normal)s,
    %(at)s
returning *
