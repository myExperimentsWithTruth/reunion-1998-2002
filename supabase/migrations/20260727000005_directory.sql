-- Public register: name + branch + registered flag, nothing else. No IDs, no
-- contact data, no timestamps. Lets the batch see who is still missing.
-- Second arm surfaces registrants not (yet) on the roster, so nobody who
-- registered is ever invisible.

create or replace view public.stats_directory as
  select r.name, r.branch, (r.registered_at is not null) as registered
    from roster r
  union all
  select p.name, nullif(p.branch, ''), true
    from responses p
   where p.id_no = ''
      or not exists (select 1 from roster r2 where r2.id_no = p.id_no);

grant select on public.stats_directory to anon;
