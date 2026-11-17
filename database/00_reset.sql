-- =====================================================================
-- 00_reset.sql — DROP EVERYTHING the old backends created
-- Elite Football Academy · Supabase SQL Editor
--
-- ⚠️  DESTRUCTIVE: deletes ALL app tables + data, ALL functions/triggers/
--     policies in schema "public" and the storage policies of the app.
--     It does NOT delete auth.users (accounts) and does NOT touch the
--     "avatars" bucket files.  Run it ONLY on a project dedicated to this app.
--
-- After it: run 01_schema.sql -> 02_security_rpc.sql -> (optional) 03_seed_demo.sql
-- (or just run FULL_SETUP.sql which contains all of them in order)
-- =====================================================================

do $$
declare r record;
begin
  -- 1) triggers on auth.users that call functions of schema public
  --    (typical leftover: "on_auth_user_created -> handle_new_user")
  for r in
    select t.tgname
      from pg_trigger t
      join pg_proc p      on p.oid = t.tgfoid
      join pg_namespace n on n.oid = p.pronamespace
     where t.tgrelid = 'auth.users'::regclass
       and not t.tgisinternal
       and n.nspname = 'public'
  loop
    raise notice 'dropping trigger % on auth.users', r.tgname;
    execute format('drop trigger if exists %I on auth.users', r.tgname);
  end loop;

  -- 2) storage policies created by the app (bucket + files are kept)
  for r in
    select policyname from pg_policies
     where schemaname = 'storage' and tablename = 'objects'
       and (policyname like 'avatars%' or policyname like 'reports%')
  loop
    raise notice 'dropping storage policy %', r.policyname;
    execute format('drop policy if exists %I on storage.objects', r.policyname);
  end loop;

  -- 3) every table any version of the backend ever created
  --    (CASCADE removes their policies, triggers, indexes, constraints)
  for r in
    select unnest(array[
      'notification_reads','notification_receipts','player_bookmarks','match_events',
      'audit_log','attendance','reports','standings','tournaments','matches','trainings',
      'players','teams','coaches','guardians','subscriptions_payments','player_evaluations',
      'academy_codes','users','academies'
    ]) as t
  loop
    execute format('drop table if exists public.%I cascade', r.t);
  end loop;

  -- 4) every remaining function / procedure in schema public (not owned by an extension)
  for r in
    select p.oid::regprocedure as sig
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public'
       and p.prokind in ('f', 'p')
       and not exists (select 1 from pg_depend d where d.objid = p.oid and d.deptype = 'e')
  loop
    execute 'drop function if exists ' || r.sig || ' cascade';
  end loop;

  -- 5) leftover enum types in public
  for r in
    select t.typname
      from pg_type t join pg_namespace n on n.oid = t.typnamespace
     where n.nspname = 'public' and t.typtype = 'e'
  loop
    execute format('drop type if exists public.%I cascade', r.typname);
  end loop;
end $$;

-- sanity check: must return 0 rows
select tablename from pg_tables where schemaname = 'public';
