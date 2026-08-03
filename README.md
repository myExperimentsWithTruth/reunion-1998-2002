# PCT Batch 1998-2002 · Silver Jubilee registration

Static registration form for the Pant College of Technology batch of 1998-2002 reunion, hosted on GitHub Pages.

The form collects six fields: name, college ID, branch, mobile, current city, email. Submissions insert into a private Supabase database through a public key that Row Level Security restricts to insert-only: it cannot read, change, or delete anything. Validation against the batch roster, duplicate flagging, and roster contact updates all run inside the database. The visitor is then handed a WhatsApp message carrying the full registration, addressed to the committee, as a second channel and a reachability check.

No roster data, readable credentials, or contact numbers live in this repository. The committee WhatsApp number is served at runtime by a private function, and the button does not render when it is unreachable. A scheduled workflow pings the backend so the free-tier project never sleeps.

`supabase/migrations` carries the schema: tables, row level security, validation, and the public views. It carries no data. The batch roster is loaded separately from a private seed that stays out of this repository, because it carries ID numbers, phone numbers and email addresses for the whole batch.

The public scoreboard shows the register as a roll call: every name in the batch, marked home or still to register, branch by branch. Names and branch only. Nothing else about a batchmate who has not registered is exposed.
