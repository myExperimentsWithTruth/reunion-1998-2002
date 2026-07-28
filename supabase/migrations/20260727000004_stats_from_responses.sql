-- Scoreboard counts come from responses (every registration counts, roster-matched
-- or not). Distinct IDs so duplicates never inflate the board; blank-ID entries
-- count one each. Batch sizes per branch still come from the roster.

create or replace view public.stats_totals as
  select (select count(*) from roster) as batch_size,
         (select count(distinct id_no) from responses where id_no <> '')
       + (select count(*) from responses where id_no = '')            as registered;

create or replace view public.stats_branches as
  with b as (select branch, count(*) as batch from roster group by branch)
  select b.branch, b.batch, coalesce(x.reg, 0) as registered
    from b
    left join (
      select branch,
             count(distinct id_no) filter (where id_no <> '')
           + count(*) filter (where id_no = '') as reg
        from responses
       group by branch
    ) x using (branch);

grant select on public.stats_totals, public.stats_branches to anon;
