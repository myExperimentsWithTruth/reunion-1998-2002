-- Repeat registrations are how people complete or correct their details.
-- On a duplicate ID: fill any blank fields on the earlier registration row(s)
-- from the new submission (never overwrite), and let the roster take the
-- latest NON-BLANK value per field (blanks never erase good data).
-- The duplicate row itself still lands, flagged, as an audit trail.

create or replace function public.update_roster_from_response() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.id_no <> '' then
    update responses r set
      mobile       = case when coalesce(r.mobile,'')       = '' then new.mobile       else r.mobile       end,
      current_city = case when coalesce(r.current_city,'') = '' then new.current_city else r.current_city end,
      email        = case when coalesce(r.email,'')        = '' then new.email        else r.email        end
    where r.id_no = new.id_no and r.id < new.id;

    update roster set
      mobile        = coalesce(nullif(new.mobile,''),       mobile),
      email         = coalesce(nullif(new.email,''),        email),
      current_city  = coalesce(nullif(new.current_city,''), current_city),
      registered_at = new.created_at,
      match_note    = case
                        when new.status like 'Check: branch differs%' then 'branch differs on form'
                        when new.status like '%Check: phone%'         then 'phone looks off'
                        else match_note
                      end
    where id_no = new.id_no;
  end if;
  return new;
end $$;
