-- Referrals + public scoreboard stats.
-- The anon key still cannot read responses or roster. It gets SELECT only on
-- these views, which expose aggregates and a first-name recent list; never
-- phone numbers or emails.

alter table public.responses add column if not exists referred_by text not null default '';

-- Redefine the validation trigger with referred_by clipping added.
create or replace function public.validate_response() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  rec roster%rowtype;
  nm text; hits int; hit_id text; d text; phone_ok boolean; dup int;
begin
  new.name         := left(coalesce(new.name,''), 200);
  new.id_no        := regexp_replace(left(coalesce(new.id_no,''),200), '[^0-9]', '', 'g');
  new.branch       := left(coalesce(new.branch,''), 200);
  new.mobile       := public.normalize_phone(left(coalesce(new.mobile,''),200));
  new.current_city := left(coalesce(new.current_city,''), 200);
  new.email        := left(coalesce(new.email,''), 200);
  new.referred_by  := left(coalesce(new.referred_by,''), 200);
  new.created_at   := now();

  if new.id_no = '' then
    new.status := 'Check: no ID given';
    nm := regexp_replace(lower(new.name), '[^a-z]', '', 'g');
    select count(*), min(id_no) into hits, hit_id from roster
     where regexp_replace(lower(name), '[^a-z]', '', 'g') = nm;
    if hits = 1 then
      new.status := 'Check: no ID given | name matches roster ' || hit_id;
    end if;
  else
    select * into rec from roster where id_no = new.id_no;
    if not found then
      new.status := 'Check: ID not on batch roster';
    elsif rec.branch <> new.branch then
      new.status := 'Check: branch differs (records: ' || rec.branch || ')';
    else
      new.status := 'Verified';
    end if;
  end if;

  d := regexp_replace(new.mobile, '[^0-9+]', '', 'g');
  if left(d,1) = '+' then
    d := regexp_replace(substr(d,2), '[^0-9]', '', 'g');
    phone_ok := length(d) between 8 and 15;
  else
    if length(d) = 12 and left(d,2) = '91' then d := substr(d,3); end if;
    if length(d) = 11 and left(d,1) = '0'  then d := substr(d,2); end if;
    phone_ok := length(d) = 10 and left(d,1) in ('6','7','8','9');
  end if;
  if not phone_ok then new.status := new.status || ' | Check: phone'; end if;

  if new.id_no <> '' then
    select count(*) into dup from responses where id_no = new.id_no;
    if dup > 0 then new.status := new.status || ' | duplicate of an earlier entry'; end if;
  end if;

  return new;
end $$;

-- Scoreboard views (definer rights: they read past RLS, exposing only what they select)
create or replace view public.stats_totals as
  select (select count(*) from roster)                                    as batch_size,
         (select count(*) from roster where registered_at is not null)    as registered;

create or replace view public.stats_branches as
  select branch,
         count(*)             as batch,
         count(registered_at) as registered
    from roster
   group by branch;

create or replace view public.stats_recent as
  select split_part(trim(name),' ',1)                         as first_name,
         left(split_part(trim(name) || ' ',' ',2),1)          as last_initial,
         branch, current_city, created_at
    from responses
   order by id desc
   limit 12;

create or replace view public.stats_referrers as
  select initcap(trim(referred_by)) as referrer, count(*) as brought
    from responses
   where trim(referred_by) <> ''
   group by 1
   order by brought desc, referrer
   limit 10;

grant select on public.stats_totals, public.stats_branches,
                public.stats_recent, public.stats_referrers to anon;
