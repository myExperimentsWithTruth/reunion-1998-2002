-- Recent arrivals must follow the clock, not the insert order. Registrations
-- recovered from the old backend land with a backdated created_at; ordering by
-- id would push them to the front of the board months after they actually came
-- home. Order by the timestamp, with id only as a tie-break within the same
-- instant (the replayed batches share a second).

create or replace view public.stats_recent as
  select split_part(trim(name), ' ', 1)                 as first_name,
         left(split_part(trim(name) || ' ', ' ', 2), 1) as last_initial,
         branch, created_at
    from responses
   order by created_at desc, id desc
   limit 12;

grant select on public.stats_recent to anon;
