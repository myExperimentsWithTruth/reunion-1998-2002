-- PCT 1998-2002 reunion backend: schema, RLS, validation.
-- The anon key may only INSERT into responses. Roster is invisible to the public.

create table public.roster (
  id_no  text primary key,
  name   text not null,
  branch text not null
);
alter table public.roster enable row level security;
-- no policies: anon and authenticated see nothing

create table public.responses (
  id           bigint generated always as identity primary key,
  created_at   timestamptz not null default now(),
  name         text not null default '',
  id_no        text not null default '',
  branch       text not null default '',
  mobile       text not null default '',
  current_city text not null default '',
  email        text not null default '',
  status       text not null default ''
);
alter table public.responses enable row level security;
create policy anon_insert_responses on public.responses
  for insert to anon with check (true);
-- no select/update/delete policies: write-only for the public key

-- Canonical phone form: '+91 XXXXX XXXXX' for Indian numbers, '+<digits>' international.
create or replace function public.normalize_phone(v text) returns text
language plpgsql immutable as $$
declare d text;
begin
  v := regexp_replace(coalesce(v,''), '[^0-9+]', '', 'g');
  if left(v,1) = '+' then
    d := regexp_replace(substr(v,2), '[^0-9]', '', 'g');
    if length(d) between 8 and 15 then return '+' || d; end if;
    return v;
  end if;
  d := regexp_replace(v, '[^0-9]', '', 'g');
  if length(d) = 12 and left(d,2) = '91' then d := substr(d,3); end if;
  if length(d) = 11 and left(d,1) = '0'  then d := substr(d,2); end if;
  if length(d) = 10 and left(d,1) in ('6','7','8','9') then
    return '+91 ' || substr(d,1,5) || ' ' || substr(d,6);
  end if;
  return v;
end $$;

-- Mirrors the old Apps Script doPost validation: roster match, branch check,
-- name-match assist when no ID, phone plausibility, duplicate flag.
-- SECURITY DEFINER so the anon insert can read the (RLS-hidden) roster.
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
  new.created_at   := now();   -- server clock, never client-supplied

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

create trigger validate_response
  before insert on public.responses
  for each row execute function public.validate_response();

-- The batch roster is data, not schema, and it is not loaded here. It carries
-- names and ID numbers for the whole batch, including people who never
-- registered, so it must never enter this public repository. It is seeded from
-- the private, gitignored supabase/seed/roster_seed.sql, which the backup
-- script regenerates on every run. See backend/backup-supabase.py.
