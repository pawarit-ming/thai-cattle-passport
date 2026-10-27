-- Stop anonymous clients from reading people's profiles and farm locations.
--
-- Before this migration `users` and `farms` had a SELECT policy of USING (true)
-- for every role, so anyone holding the app's publishable key could list
-- every user's name and mobile number and every farm's address and GPS
-- position without signing in.
--
-- After it:
--   * anonymous clients can no longer read `users` or `farms`; the public
--     passport only needs `animals` and `activities`, which stay readable;
--   * signed-in users can read other people's names and verification status
--     (marketplace, offers) but not their phone, address or birth date;
--   * a user reads their own full profile through get_my_profile();
--   * phone sign-in looks the email up through email_for_phone(), which
--     returns one email for one number instead of exposing the table.

begin;

-- users ---------------------------------------------------------------------

drop policy if exists "Enable read access for all users" on public.users;

create policy "Signed-in users can read profiles"
  on public.users for select to authenticated
  using (true);

revoke select on public.users from anon, authenticated;
grant select (id, role, title, first_name, last_name, province,
              is_dld_verified, created_at, updated_at)
  on public.users to authenticated;

create or replace function public.get_my_profile()
returns setof public.users
language sql
stable
security definer
set search_path = ''
as $$
  select * from public.users where id = auth.uid();
$$;

revoke execute on function public.get_my_profile() from public, anon;
grant execute on function public.get_my_profile() to authenticated;

create or replace function public.email_for_phone(p_phone text)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select au.email
  from public.users u
  join auth.users au on au.id = u.id
  where u.mobile_phone = p_phone
  limit 1;
$$;

revoke execute on function public.email_for_phone(text) from public;
grant execute on function public.email_for_phone(text) to anon, authenticated;

-- farms ---------------------------------------------------------------------

drop policy if exists "Enable read access for all users" on public.farms;

create policy "Signed-in users can read farms"
  on public.farms for select to authenticated
  using (true);

-- animals -------------------------------------------------------------------

-- The policy had no role, so with WITH CHECK (true) an anonymous client could
-- insert animals. Writes only ever come from signed-in owners.
alter policy "Users can manage own animals" on public.animals to authenticated;

commit;
