-- Privacy tightening: the public recent-arrivals view carries no location.
-- First name + last initial + branch + arrival time only.

drop view public.stats_recent;
create view public.stats_recent as
  select split_part(trim(name), ' ', 1)                as first_name,
         left(split_part(trim(name) || ' ', ' ', 2), 1) as last_initial,
         branch, created_at
    from responses
   order by id desc
   limit 12;

grant select on public.stats_recent to anon;

-- Recruit mechanic dropped: no public referrer board.
drop view if exists public.stats_referrers;
