-- =====================================================================
-- 09_admin_wipe_function.sql — one-call "wipe everything" function
--
-- Used by tool/wipe_all.dart. Callable ONLY with the service_role key
-- (anon / authenticated users — i.e. the app — can NOT run it).
-- It deletes: every row of every public table (except the QR secret),
--             every login account (auth.users), the old login audit log,
-- and rotates the QR signing key.
-- Storage files are deleted by the script (SQL is not allowed to do that).
--
-- After launch you may remove it:  drop function public.admin_wipe_all();
-- =====================================================================
create or replace function public.admin_wipe_all()
returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
declare r record;
begin
  for r in select tablename from pg_tables
            where schemaname = 'public' and tablename <> 'app_secrets'
  loop
    execute format('truncate table public.%I restart identity cascade', r.tablename);
  end loop;

  delete from auth.users;

  begin
    execute 'truncate table auth.audit_log_entries';
  exception when others then
    null;  -- not allowed on some projects: harmless
  end;

  update public.app_secrets
     set value = extensions.gen_random_bytes(32)
   where key = 'checkin_hmac';

  return 'ok';
end $$;

revoke all on function public.admin_wipe_all() from public, anon, authenticated;
grant execute on function public.admin_wipe_all() to service_role;
notify pgrst, 'reload schema';
