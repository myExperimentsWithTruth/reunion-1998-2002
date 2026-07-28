-- The public register lists only those who registered. Names of batchmates who
-- have not registered never leave the database; they did not opt in to appear.

drop view public.stats_directory;
create view public.stats_directory as
  select r.name, r.branch
    from roster r
   where r.registered_at is not null
  union all
  select p.name, nullif(p.branch, '')
    from responses p
   where p.id_no = ''
      or not exists (select 1 from roster r2 where r2.id_no = p.id_no);

grant select on public.stats_directory to anon;
