-- The register shows the whole batch again: who is home and who is still out.
-- This reverses 20260727000007, which listed only registrants. The board is a
-- roll call for the batch's own people, and a name that is missing is the point
-- of it: batchmates can see who to call. Names and branch only. Nothing else
-- about an unregistered batchmate leaves the database -- no ID number, no
-- phone, no email, no city.

drop view public.stats_directory;
create view public.stats_directory as
  select r.name, r.branch, (r.registered_at is not null) as registered
    from roster r
  union all
  select p.name, nullif(p.branch, ''), true
    from responses p
   where p.id_no = ''
      or not exists (select 1 from roster r2 where r2.id_no = p.id_no);

grant select on public.stats_directory to anon;
