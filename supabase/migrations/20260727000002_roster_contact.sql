-- The roster becomes the living master list. When a registration arrives with an
-- ID that matches the roster (ID is the matching key), the roster row is updated
-- with the contact details from the form. Re-registration overwrites: latest wins.
-- Non-matching registrations never touch the roster; they surface in reports.

alter table public.roster
  add column if not exists mobile        text,
  add column if not exists email         text,
  add column if not exists current_city  text,
  add column if not exists registered_at timestamptz,
  add column if not exists match_note    text;

create or replace function public.update_roster_from_response() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.id_no <> '' then
    update roster set
      mobile        = new.mobile,
      email         = new.email,
      current_city  = new.current_city,
      registered_at = new.created_at,
      match_note    = case
                        when new.status like 'Check: branch differs%' then 'branch differs on form'
                        when new.status like '%Check: phone%'         then 'phone looks off'
                        else null
                      end
    where id_no = new.id_no;
  end if;
  return new;
end $$;

drop trigger if exists update_roster_from_response on public.responses;
create trigger update_roster_from_response
  after insert on public.responses
  for each row execute function public.update_roster_from_response();
