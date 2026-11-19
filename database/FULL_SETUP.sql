-- =====================================================================
-- FULL_SETUP.sql — قاعدة بيانات أكاديمية النخبة كاملة في ملف واحد
--
--   00_reset         : يمسح كل جداول ودوال وسياسات schema public
--   01_schema        : الجداول (الحضور فيه training_id) 
--   02_security_rpc  : الأمان (RLS) + دوال التسجيل والأكواد
--   04_qr_attendance : مسح الـ QR وتسجيل الحضور
--   08_lineups       : تشكيلة المباراة (أساسيين + بدلاء)
--   09_admin_wipe    : دالة المسح الشامل (تُستدعى من tool/wipe_all.dart بمفتاح service_role فقط)
--   05_grants        : صلاحيات الجداول للتطبيق
--
-- طريقة التشغيل: Supabase > SQL Editor > New query > الصق الملف كله > Run
-- ⚠️ بيمسح كل بيانات التطبيق (مش حسابات Authentication).
-- بيانات تجريبية (اختياري): 06_seed_test_accounts.sql  |  مسح كل شيء: 07_wipe_all_data.sql
-- =====================================================================

-- >>>>>>>>>>>>>>>>>>>> 00_reset.sql <<<<<<<<<<<<<<<<<<<<
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

  -- 3) EVERY table in schema public (CASCADE removes policies, triggers, indexes, constraints)
  for r in select tablename from pg_tables where schemaname = 'public'
  loop
    execute format('drop table if exists public.%I cascade', r.tablename);
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

-- >>>>>>>>>>>>>>>>>>>> 01_schema.sql <<<<<<<<<<<<<<<<<<<<
-- =====================================================================
-- 01_schema.sql  —  NEW DATABASE (tables, types, constraints, indexes)
-- Run AFTER 00_reset.sql. Column names/types match the Dart models
-- (toMap/fromMap) exactly. Safe to re-run only on an empty schema.
-- =====================================================================

-- ---------- academies ------------------------------------------------
create table public.academies (
  id         uuid primary key default gen_random_uuid(),
  name       text not null check (char_length(btrim(name)) between 2 and 80),
  owner_id   uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);
create unique index academies_name_uq on public.academies (lower(btrim(name)));

-- Invite codes live in their own table so that no client can ever read
-- them with a plain SELECT (an "admin" code would grant admin rights).
create table public.academy_codes (
  academy_id  uuid primary key references public.academies(id) on delete cascade,
  admin_code  text not null unique,
  coach_code  text not null unique,
  player_code text not null unique,
  updated_at  timestamptz not null default now()
);

-- ---------- users (profile, 1:1 with auth.users) --------------------
create table public.users (
  id           uuid primary key references auth.users(id) on delete cascade,
  name         text not null default '',
  email        text not null default '',
  role         text not null default 'player' check (role in ('admin','coach','player')),
  team_id      text,                         -- kept in sync by triggers (see 02)
  academy_id   uuid not null references public.academies(id) on delete cascade,
  academy_name text not null default '',
  phone        text not null default '',
  address      text not null default '',
  job_number   text not null default '',
  join_date    text not null default '',
  photo        text,
  created_at   timestamptz not null default now()
);
create index users_academy_idx on public.users (academy_id);

-- ---------- coaches --------------------------------------------------
create table public.coaches (
  id         text primary key,               -- = auth uid for self-registered coaches
  name       text not null default '',
  specialty  text not null default 'مدرب',
  category   text not null default 'فني',
  years      int  not null default 0 check (years >= 0),
  photo      text not null default '',
  phone      text not null default '',
  email      text not null default '',
  academy_id uuid not null references public.academies(id) on delete cascade
);
create index coaches_academy_idx on public.coaches (academy_id);

-- ---------- teams ----------------------------------------------------
create table public.teams (
  id          text primary key,
  name        text not null default '',
  category    text not null default '',
  coach_id    text references public.coaches(id) on delete set null,
  coach_name  text not null default '',
  color       bigint not null default 4279612550,   -- 0xFF12B886
  icon_name   text not null default 'shield',
  description text not null default '',
  academy_id  uuid not null references public.academies(id) on delete cascade
);
create index teams_academy_idx on public.teams (academy_id);
create index teams_coach_idx   on public.teams (coach_id);

-- ---------- players --------------------------------------------------
create table public.players (
  id           text primary key,
  user_id      text,                         -- auth uid (text) when the player has an account
  name         text not null default '',
  position     text not null default 'لاعب',
  team_id      text references public.teams(id) on delete set null,
  team_name    text not null default 'بدون فريق',
  photo        text not null default '',
  rating       text not null default '0.0',
  goals        int  not null default 0 check (goals >= 0),
  assists      int  not null default 0 check (assists >= 0),
  matches      int  not null default 0 check (matches >= 0),
  yellow_cards int  not null default 0 check (yellow_cards >= 0),
  red_cards    int  not null default 0 check (red_cards >= 0),
  age          text not null default '—',
  height       text not null default '—',
  weight       text not null default '—',
  foot         text not null default '—',
  nationality  text not null default '—',
  academy_id   uuid not null references public.academies(id) on delete cascade
);
create index players_academy_idx on public.players (academy_id);
create index players_team_idx    on public.players (team_id);
create unique index players_user_uq on public.players (user_id) where user_id is not null;

-- ---------- trainings ------------------------------------------------
-- `date` is "timestamp WITHOUT time zone" on purpose: the app sends
-- DateTime.toIso8601String() of a LOCAL date, and reads it back as local.
-- (timestamptz would shift the day for users away from UTC.)
create table public.trainings (
  id               text primary key,
  title            text not null default '',
  type             text not null default 'تدريب',
  location         text not null default '',
  date             timestamp not null default now(),
  time             text not null default '',
  duration_minutes int  not null default 60 check (duration_minutes > 0),
  team_id          text references public.teams(id) on delete set null,
  team_name        text not null default '',
  coach_id         text,
  coach_name       text not null default '',
  notes            text not null default '',
  academy_id       uuid not null references public.academies(id) on delete cascade
);
create index trainings_academy_date_idx on public.trainings (academy_id, date);
create index trainings_team_idx         on public.trainings (team_id);

-- ---------- matches --------------------------------------------------
create table public.matches (
  id            text primary key,
  team_id       text references public.teams(id) on delete set null,
  team_name     text not null default '',
  opponent_name text not null default '',
  venue         text not null default '',
  date          text not null default '',          -- 'yyyy/MM/dd' (Match.dateTime parses it)
  time          text not null default '',
  home_score    int  not null default 0 check (home_score >= 0),
  away_score    int  not null default 0 check (away_score >= 0),
  status        text not null default 'upcoming' check (status in ('upcoming','live','finished')),
  player_rating text not null default '',
  academy_id    uuid not null references public.academies(id) on delete cascade
);
create index matches_academy_idx on public.matches (academy_id);
create index matches_team_idx    on public.matches (team_id);

-- ---------- tournaments / standings ---------------------------------
create table public.tournaments (
  id          text primary key,
  name        text not null default '',
  subtitle    text not null default '',
  date        text not null default '',
  status      text not null default 'upcoming'
              check (status in ('ongoing','upcoming','scheduled','finished')),
  teams_count int  not null default 0 check (teams_count >= 0),
  icon_name   text not null default 'trophy',
  academy_id  uuid not null references public.academies(id) on delete cascade
);
create index tournaments_academy_idx on public.tournaments (academy_id);

create table public.standings (
  team_id    text not null references public.teams(id) on delete cascade,
  team_name  text not null default '',
  played     int  not null default 0 check (played >= 0),
  won        int  not null default 0 check (won    >= 0),
  drawn      int  not null default 0 check (drawn  >= 0),
  lost       int  not null default 0 check (lost   >= 0),
  academy_id uuid not null references public.academies(id) on delete cascade,
  primary key (team_id, academy_id)        -- required by upsert onConflict
);

-- ---------- reports --------------------------------------------------
create table public.reports (
  id         text primary key,
  title      text not null default '',
  subtitle   text not null default '',
  date       text not null default '',               -- 'yyyy/MM/dd'
  size       text not null default '',
  type       text not null default '',
  category   text not null default 'performance'
             check (category in ('performance','attendance','financial','other')),
  team_id    text references public.teams(id) on delete set null,
  academy_id uuid not null references public.academies(id) on delete cascade,
  created_at timestamptz not null default now()
);
create index reports_academy_idx on public.reports (academy_id);

-- ---------- notifications (+ per-user read state) -------------------
create table public.notifications (
  id         text primary key,
  title      text not null default '',
  message    text not null default '',
  time       text not null default '',
  is_unread  boolean not null default true,   -- legacy column (the app now uses notification_reads)
  category   text not null default 'general' check (category in ('general','matches','trainings')),
  academy_id uuid not null references public.academies(id) on delete cascade,
  created_at timestamptz not null default now()
);
create index notifications_academy_idx on public.notifications (academy_id, created_at desc);

-- "read" is per USER. (A single is_unread flag made one person's tap
-- mark the notification as read for the whole academy.)
create table public.notification_reads (
  notification_id text not null references public.notifications(id) on delete cascade,
  user_id         uuid not null references auth.users(id) on delete cascade,
  read_at         timestamptz not null default now(),
  primary key (notification_id, user_id)
);
create index notification_reads_user_idx on public.notification_reads (user_id);

-- ---------- attendance ----------------------------------------------
-- training_id IS NULL  => whole-day row (what the attendance screen + QR scanner write).
-- UNIQUE NULLS NOT DISTINCT (PostgreSQL 15+, the Supabase default) makes the
-- upsert onConflict 'player_id,date,training_id' work even when training_id is NULL.
create table public.attendance (
  id          bigint generated always as identity primary key,
  player_id   text not null references public.players(id) on delete cascade,
  team_id     text,                              -- filled by trg_attendance_check
  academy_id  uuid not null references public.academies(id) on delete cascade,
  date        date not null,
  training_id text,
  status      text not null check (status in ('present','absent','late')),
  source      text not null default 'manual' check (source in ('manual','qr')),
  checked_in_at timestamptz,
  created_by  uuid default auth.uid(),
  created_at  timestamptz not null default now(),
  constraint attendance_uq unique nulls not distinct (player_id, date, training_id)
);
create index attendance_academy_date_idx on public.attendance (academy_id, date);

-- >>>>>>>>>>>>>>>>>>>> 02_security_rpc.sql <<<<<<<<<<<<<<<<<<<<
-- =====================================================================
-- 02_security_rpc.sql  —  helpers, RPCs, triggers, RLS, storage
-- Run AFTER 01_schema.sql.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1) HELPERS (SECURITY DEFINER so policies can read public.users safely)
-- ---------------------------------------------------------------------
create or replace function public.my_academy_id()
returns uuid language sql stable security definer set search_path = public as $$
  select academy_id from public.users where id = auth.uid()
$$;

create or replace function public.my_role()
returns text language sql stable security definer set search_path = public as $$
  select role from public.users where id = auth.uid()
$$;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select role = 'admin' from public.users where id = auth.uid()), false)
$$;

create or replace function public.is_staff()      -- admin or coach
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select role in ('admin','coach') from public.users where id = auth.uid()), false)
$$;

create or replace function public.my_player_id()
returns text language sql stable security definer set search_path = public as $$
  select id from public.players where user_id = auth.uid()::text limit 1
$$;

create or replace function public._uuid_or_null(p text)
returns uuid language plpgsql immutable as $$
begin
  if p is null then return null; end if;
  return p::uuid;
exception when others then
  return null;
end $$;

-- 8-char invite code from a CSPRNG source (uuid v4), 32^8 ≈ 1e12 combinations
create or replace function public._gen_code(p_prefix text)
returns text language plpgsql volatile set search_path = public as $$
declare
  v_chars constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_hex   text := replace(gen_random_uuid()::text, '-', '');
  v_out   text := '';
  i       int;
begin
  for i in 0..7 loop
    v_out := v_out || substr(v_chars, (('x' || substr(v_hex, i * 2 + 1, 2))::bit(8)::int % 32) + 1, 1);
  end loop;
  return p_prefix || '-' || v_out;
end $$;

create or replace function public._create_academy_codes(p_academy uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_try int := 0;
begin
  loop
    v_try := v_try + 1;
    begin
      insert into public.academy_codes (academy_id, admin_code, coach_code, player_code)
      values (p_academy, public._gen_code('ACAD'), public._gen_code('COACH'), public._gen_code('PLAYER'));
      return;
    exception when unique_violation then
      if v_try >= 5 then raise; end if;
    end;
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 2) SIGN-UP / ACCOUNT RPCs
--    The client can no longer insert its own role / academy (that was a
--    privilege-escalation hole). The server decides everything.
-- ---------------------------------------------------------------------
create or replace function public.academy_name_available(p_name text)
returns boolean language sql stable security definer set search_path = public as $$
  select not exists (
    select 1 from public.academies
    where lower(btrim(name)) = lower(btrim(coalesce(p_name, '')))
  )
$$;

-- New academy  -> caller becomes its ADMIN.
create or replace function public.register_academy(
  p_name text, p_user_name text, p_phone text default '', p_address text default '')
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_uid     uuid := auth.uid();
  v_aname   text := btrim(coalesce(p_name, ''));
  v_uname   text := btrim(coalesce(p_user_name, ''));
  v_email   text;
  v_academy uuid;
  v_job     text;
  v_join    text := to_char(now() at time zone 'utc', 'YYYY/MM/DD');
begin
  if v_uid is null then raise exception 'not_authenticated' using errcode = '28000'; end if;
  if exists (select 1 from public.users where id = v_uid) then
    raise exception 'profile_exists' using errcode = 'P0001';
  end if;
  if char_length(v_aname) < 2 then
    raise exception 'invalid_academy_name' using errcode = 'P0001';
  end if;

  select email into v_email from auth.users where id = v_uid;
  if v_uname = '' then v_uname := split_part(coalesce(v_email, ''), '@', 1); end if;

  begin
    insert into public.academies (name, owner_id) values (v_aname, v_uid) returning id into v_academy;
  exception when unique_violation then
    raise exception 'academy_name_taken' using errcode = 'P0001';
  end;

  perform public._create_academy_codes(v_academy);

  v_job := 'ADMIN-' || right(v_uid::text, 4);
  insert into public.users (id, name, email, role, academy_id, academy_name, phone, address, job_number, join_date)
  values (v_uid, v_uname, coalesce(v_email, ''), 'admin', v_academy, v_aname,
          coalesce(p_phone, ''), coalesce(p_address, ''), v_job, v_join);

  return jsonb_build_object('id', v_uid, 'academy_id', v_academy, 'academy_name', v_aname,
                            'role', 'admin', 'job_number', v_job, 'join_date', v_join);
end $$;

-- Join with an invite code -> role comes FROM THE CODE (admin/coach/player).
create or replace function public.join_academy(
  p_code text, p_user_name text, p_phone text default '', p_address text default '')
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_uid     uuid := auth.uid();
  v_code    text := upper(btrim(coalesce(p_code, '')));
  v_uname   text := btrim(coalesce(p_user_name, ''));
  v_email   text;
  v_academy uuid;
  v_aname   text;
  v_role    text;
  v_job     text;
  v_join    text := to_char(now() at time zone 'utc', 'YYYY/MM/DD');
begin
  if v_uid is null then raise exception 'not_authenticated' using errcode = '28000'; end if;
  if exists (select 1 from public.users where id = v_uid) then
    raise exception 'profile_exists' using errcode = 'P0001';
  end if;

  select c.academy_id,
         case when c.admin_code = v_code then 'admin'
              when c.coach_code = v_code then 'coach'
              else 'player' end
    into v_academy, v_role
    from public.academy_codes c
   where c.admin_code = v_code or c.coach_code = v_code or c.player_code = v_code
   limit 1;

  if v_academy is null then raise exception 'invalid_academy_code' using errcode = 'P0001'; end if;

  select name into v_aname from public.academies where id = v_academy;
  select email into v_email from auth.users where id = v_uid;
  if v_uname = '' then v_uname := split_part(coalesce(v_email, ''), '@', 1); end if;

  v_job := case v_role when 'admin' then 'ADMIN-' when 'coach' then 'COACH-' else 'PLAYER-' end
           || right(v_uid::text, 4);

  insert into public.users (id, name, email, role, academy_id, academy_name, phone, address, job_number, join_date)
  values (v_uid, v_uname, coalesce(v_email, ''), v_role, v_academy, v_aname,
          coalesce(p_phone, ''), coalesce(p_address, ''), v_job, v_join);

  if v_role = 'player' then
    insert into public.players (id, user_id, name, position, team_name, academy_id)
    values ('pl_' || substr(md5(gen_random_uuid()::text), 1, 8), v_uid::text, v_uname,
            'لاعب', 'بدون فريق', v_academy);

  elsif v_role = 'coach' then
    insert into public.coaches (id, name, specialty, category, phone, email, academy_id)
    values (v_uid::text, v_uname, 'مدرب', 'فني', coalesce(p_phone, ''), coalesce(v_email, ''), v_academy);

    -- The Team form only has a free-text "coach name". If an admin already
    -- typed this coach's name on a team, link it now (only if unambiguous).
    update public.teams t
       set coach_id = v_uid::text
     where t.academy_id = v_academy
       and t.coach_id is null
       and btrim(t.coach_name) not in ('', '—')
       and lower(btrim(t.coach_name)) = lower(v_uname)
       and (select count(*) from public.coaches c
             where c.academy_id = v_academy and lower(btrim(c.name)) = lower(v_uname)) = 1;
  end if;

  return jsonb_build_object('id', v_uid, 'academy_id', v_academy, 'academy_name', v_aname,
                            'role', v_role, 'job_number', v_job, 'join_date', v_join);
end $$;

-- Codes visible to the caller:  admin -> all 3 | coach -> player code | player -> none
create or replace function public.get_academy_codes()
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_role text := public.my_role();
  v_aid  uuid := public.my_academy_id();
  c      public.academy_codes;
begin
  if v_aid is null or coalesce(v_role, '') not in ('admin', 'coach') then
    return jsonb_build_object('admin', '', 'coach', '', 'player', '');
  end if;
  select * into c from public.academy_codes where academy_id = v_aid;
  return jsonb_build_object(
    'admin',  case when v_role = 'admin' then coalesce(c.admin_code, '') else '' end,
    'coach',  case when v_role = 'admin' then coalesce(c.coach_code, '') else '' end,
    'player', coalesce(c.player_code, ''));
end $$;

-- admin may regenerate any code; coach may regenerate the player code only
create or replace function public.regenerate_academy_code(p_role text)
returns text language plpgsql security definer set search_path = public as $$
declare
  v_role   text := public.my_role();
  v_aid    uuid := public.my_academy_id();
  v_new    text;
  v_prefix text;
  v_try    int := 0;
begin
  if v_aid is null then raise exception 'not_authenticated' using errcode = '28000'; end if;
  if p_role not in ('admin', 'coach', 'player') then
    raise exception 'invalid_role' using errcode = '22023';
  end if;
  if not (v_role = 'admin' or (v_role = 'coach' and p_role = 'player')) then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  v_prefix := case p_role when 'admin' then 'ACAD' when 'coach' then 'COACH' else 'PLAYER' end;
  loop
    v_try := v_try + 1;
    v_new := public._gen_code(v_prefix);
    begin
      update public.academy_codes set
        admin_code  = case when p_role = 'admin'  then v_new else admin_code  end,
        coach_code  = case when p_role = 'coach'  then v_new else coach_code  end,
        player_code = case when p_role = 'player' then v_new else player_code end,
        updated_at  = now()
      where academy_id = v_aid;
      return v_new;
    exception when unique_violation then
      if v_try >= 5 then raise; end if;
    end;
  end loop;
end $$;

-- Account deletion (the app promises it in Settings → Privacy)
create or replace function public.delete_my_account()
returns void language plpgsql security definer set search_path = public as $$
declare
  v_uid  uuid := auth.uid();
  v_role text;
  v_aid  uuid;
begin
  if v_uid is null then raise exception 'not_authenticated' using errcode = '28000'; end if;
  select role, academy_id into v_role, v_aid from public.users where id = v_uid;

  if v_role = 'admin'
     and not exists (select 1 from public.users where academy_id = v_aid and role = 'admin' and id <> v_uid) then
    if exists (select 1 from public.users where academy_id = v_aid and id <> v_uid) then
      raise exception 'last_admin_has_members' using errcode = 'P0001';
    end if;
    delete from public.academies where id = v_aid;       -- cascades all academy data
  end if;

  delete from public.players where user_id = v_uid::text;
  delete from public.coaches where id = v_uid::text;
  delete from auth.users where id = v_uid;               -- cascades public.users
end $$;

-- ---------------------------------------------------------------------
-- 3) TRIGGERS
-- ---------------------------------------------------------------------
-- 3a) academy_id is ALWAYS taken from the signed-in user's profile on
--     INSERT (nobody can write into another academy) and is immutable.
create or replace function public.trg_set_academy_id()
returns trigger language plpgsql security definer set search_path = public as $$
declare v uuid;
begin
  if tg_op = 'INSERT' then
    if auth.uid() is not null then
      v := public.my_academy_id();
      if v is null then raise exception 'no_academy' using errcode = '42501'; end if;
      new.academy_id := v;
    end if;
  else
    new.academy_id := old.academy_id;
  end if;
  return new;
end $$;

do $$
declare t text;
begin
  foreach t in array array['coaches','teams','players','trainings','matches','tournaments',
                           'standings','reports','notifications','attendance']
  loop
    execute format('create trigger trg_%1$s_academy before insert or update on public.%1$I
                    for each row execute function public.trg_set_academy_id()', t);
  end loop;
end $$;

-- 3b) users: a user can edit only name / phone / address / photo of self
create or replace function public.trg_users_protect()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is not null and auth.uid() = old.id
     and coalesce(current_setting('app.sync', true), '') <> '1' then
    new.id           := old.id;
    new.role         := old.role;
    new.academy_id   := old.academy_id;
    new.academy_name := old.academy_name;
    new.team_id      := old.team_id;
    new.email        := old.email;
    new.job_number   := old.job_number;
    new.join_date    := old.join_date;
    new.created_at   := old.created_at;
  end if;
  return new;
end $$;
create trigger trg_users_protect before update on public.users
  for each row execute function public.trg_users_protect();

-- 3c) keep players/coaches rows in step with the profile (name/photo/phone)
create or replace function public.trg_users_sync_profiles()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.name is distinct from old.name
     or new.photo is distinct from old.photo
     or new.phone is distinct from old.phone then
    perform set_config('app.sync', '1', true);
    update public.players set name = new.name, photo = coalesce(new.photo, photo)
     where user_id = new.id::text;
    update public.coaches set name = new.name, photo = coalesce(new.photo, photo), phone = new.phone
     where id = new.id::text;
  end if;
  return new;
end $$;
create trigger trg_users_sync_profiles after update on public.users
  for each row execute function public.trg_users_sync_profiles();

-- 3d) a player may only change name/photo of his own row; staff change anything
create or replace function public.trg_players_guard_self()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  new.id := old.id;
  if auth.uid() is not null and not public.is_staff()
     and coalesce(current_setting('app.sync', true), '') <> '1' then
    new.user_id      := old.user_id;
    new.position     := old.position;
    new.team_id      := old.team_id;
    new.team_name    := old.team_name;
    new.rating       := old.rating;
    new.goals        := old.goals;
    new.assists      := old.assists;
    new.matches      := old.matches;
    new.yellow_cards := old.yellow_cards;
    new.red_cards    := old.red_cards;
    new.age          := old.age;
    new.height       := old.height;
    new.weight       := old.weight;
    new.foot         := old.foot;
    new.nationality  := old.nationality;
    new.academy_id   := old.academy_id;
  end if;
  return new;
end $$;
create trigger trg_players_guard_self before update on public.players
  for each row execute function public.trg_players_guard_self();

-- 3e) users.team_id  <-  players.team_id   (every "my team" screen reads it)
create or replace function public.trg_players_sync_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_uid uuid;
begin
  if tg_op = 'DELETE' then
    v_uid := public._uuid_or_null(old.user_id);
    if v_uid is not null then
      perform set_config('app.sync', '1', true);
      update public.users set team_id = null where id = v_uid and role = 'player' and team_id is not null;
    end if;
    return old;
  end if;
  v_uid := public._uuid_or_null(new.user_id);
  if v_uid is not null then
    perform set_config('app.sync', '1', true);
    update public.users set team_id = new.team_id
     where id = v_uid and role = 'player' and team_id is distinct from new.team_id;
  end if;
  return new;
end $$;
create trigger trg_players_sync_user_iu after insert or update of team_id, user_id on public.players
  for each row execute function public.trg_players_sync_user();
create trigger trg_players_sync_user_d after delete on public.players
  for each row execute function public.trg_players_sync_user();

-- 3f) teams.coach_id: the Team form only sends a coach NAME. Resolve it to a
--     coach id when exactly one coach in the academy has that name.
create or replace function public.trg_teams_resolve_coach()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_cnt int;
  v_id  text;
  v_nm  text := btrim(coalesce(new.coach_name, ''));
begin
  new.coach_id := nullif(btrim(coalesce(new.coach_id, '')), '');

  if coalesce(current_setting('app.sync', true), '') <> '1' then
    -- name edited by a user while the old id was re-sent -> re-resolve
    if tg_op = 'UPDATE'
       and new.coach_name is distinct from old.coach_name
       and new.coach_id   is not distinct from old.coach_id then
      new.coach_id := null;
    end if;

    if new.coach_id is null and v_nm not in ('', '—') then
      select count(*), min(c.id) into v_cnt, v_id
        from public.coaches c
       where c.academy_id = new.academy_id and lower(btrim(c.name)) = lower(v_nm);
      if v_cnt = 1 then new.coach_id := v_id; end if;
    end if;
  end if;
  return new;
end $$;
create trigger trg_teams_resolve_coach before insert or update of coach_id, coach_name on public.teams
  for each row execute function public.trg_teams_resolve_coach();

-- users.team_id  <-  teams.coach_id
create or replace function public.trg_teams_sync_coach()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform set_config('app.sync', '1', true);
  if tg_op = 'UPDATE' and old.coach_id is not null and old.coach_id is distinct from new.coach_id then
    update public.users set team_id = null
     where id = public._uuid_or_null(old.coach_id) and role = 'coach' and team_id = new.id;
  end if;
  if new.coach_id is not null then
    update public.users set team_id = new.id
     where id = public._uuid_or_null(new.coach_id) and role = 'coach' and team_id is distinct from new.id;
  end if;
  return new;
end $$;
create trigger trg_teams_sync_coach after insert or update of coach_id on public.teams
  for each row execute function public.trg_teams_sync_coach();

-- deleting a team: detach everybody first (FKs then null the team_id columns)
create or replace function public.trg_teams_before_delete()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform set_config('app.sync', '1', true);
  update public.users   set team_id = null where team_id = old.id;
  update public.players set team_name = 'بدون فريق' where team_id = old.id;
  return old;
end $$;
create trigger trg_teams_before_delete before delete on public.teams
  for each row execute function public.trg_teams_before_delete();

-- denormalised names stay correct after a rename
create or replace function public.trg_teams_after_rename()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.name is distinct from old.name then
    perform set_config('app.sync', '1', true);
    update public.players   set team_name = new.name where team_id = new.id;
    update public.trainings set team_name = new.name where team_id = new.id;
    update public.matches   set team_name = new.name where team_id = new.id;
    update public.standings set team_name = new.name where team_id = new.id;
  end if;
  return new;
end $$;
create trigger trg_teams_after_rename after update of name on public.teams
  for each row execute function public.trg_teams_after_rename();

create or replace function public.trg_coaches_after_rename()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.name is distinct from old.name then
    perform set_config('app.sync', '1', true);
    update public.teams     set coach_name = new.name where coach_id = new.id;
    update public.trainings set coach_name = new.name where coach_id = new.id;
  end if;
  return new;
end $$;
create trigger trg_coaches_after_rename after update of name on public.coaches
  for each row execute function public.trg_coaches_after_rename();

create or replace function public.trg_coaches_before_delete()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform set_config('app.sync', '1', true);
  update public.users set team_id = null where id = public._uuid_or_null(old.id) and role = 'coach';
  update public.teams set coach_name = '—' where coach_id = old.id;
  return old;
end $$;
create trigger trg_coaches_before_delete before delete on public.coaches
  for each row execute function public.trg_coaches_before_delete();

-- renaming the academy keeps users.academy_name correct
create or replace function public.trg_academies_after_rename()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.name is distinct from old.name then
    perform set_config('app.sync', '1', true);
    update public.users set academy_name = new.name where academy_id = new.id;
  end if;
  return new;
end $$;
create trigger trg_academies_after_rename after update of name on public.academies
  for each row execute function public.trg_academies_after_rename();

-- ---------------------------------------------------------------------
-- 4) ROW LEVEL SECURITY  (replaces the old "... or true" policies)
--    Roles (as the UI already behaves):
--      admin  : everything inside his academy
--      coach  : read all; write players, trainings, matches, tournaments,
--               standings, reports, notifications, attendance
--      player : read own academy; own attendance only; edit own name/photo
-- ---------------------------------------------------------------------
alter table public.academies          enable row level security;
alter table public.academy_codes      enable row level security;   -- no policy = RPC only
alter table public.users              enable row level security;
alter table public.coaches            enable row level security;
alter table public.teams              enable row level security;
alter table public.players            enable row level security;
alter table public.trainings          enable row level security;
alter table public.matches            enable row level security;
alter table public.tournaments        enable row level security;
alter table public.standings          enable row level security;
alter table public.reports            enable row level security;
alter table public.notifications      enable row level security;
alter table public.notification_reads enable row level security;
alter table public.attendance         enable row level security;

-- academies
create policy academies_select on public.academies for select to authenticated
  using (id = (select public.my_academy_id()));
create policy academies_update on public.academies for update to authenticated
  using (id = (select public.my_academy_id()) and (select public.is_admin()))
  with check (id = (select public.my_academy_id()));

-- users (profile rows contain phone/address -> staff only; everyone sees self)
create policy users_select on public.users for select to authenticated
  using (id = (select auth.uid())
         or (academy_id = (select public.my_academy_id()) and (select public.is_staff())));
create policy users_update on public.users for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

-- read access: every member of the academy
do $$
declare t text;
begin
  foreach t in array array['coaches','teams','players','trainings','matches',
                           'tournaments','standings','reports','notifications']
  loop
    execute format('create policy %I on public.%I for select to authenticated
                    using (academy_id = (select public.my_academy_id()))', t || '_select', t);
  end loop;
end $$;

-- write access: admin only
do $$
declare t text;
begin
  foreach t in array array['coaches','teams']
  loop
    execute format('create policy %I on public.%I for insert to authenticated
                    with check (academy_id = (select public.my_academy_id()) and (select public.is_admin()))', t || '_insert', t);
    execute format('create policy %I on public.%I for update to authenticated
                    using (academy_id = (select public.my_academy_id()) and (select public.is_admin()))
                    with check (academy_id = (select public.my_academy_id()))', t || '_update', t);
    execute format('create policy %I on public.%I for delete to authenticated
                    using (academy_id = (select public.my_academy_id()) and (select public.is_admin()))', t || '_delete', t);
  end loop;
end $$;

-- write access: admin + coach
do $$
declare t text;
begin
  foreach t in array array['players','trainings','matches','tournaments','standings',
                           'reports','notifications','attendance']
  loop
    execute format('create policy %I on public.%I for insert to authenticated
                    with check (academy_id = (select public.my_academy_id()) and (select public.is_staff()))', t || '_insert', t);
    execute format('create policy %I on public.%I for update to authenticated
                    using (academy_id = (select public.my_academy_id()) and (select public.is_staff()))
                    with check (academy_id = (select public.my_academy_id()))', t || '_update', t);
    execute format('create policy %I on public.%I for delete to authenticated
                    using (academy_id = (select public.my_academy_id()) and (select public.is_staff()))', t || '_delete', t);
  end loop;
end $$;

-- a player can edit his own row (trigger limits it to name/photo)
create policy players_self_update on public.players for update to authenticated
  using (user_id = (select auth.uid())::text) with check (user_id = (select auth.uid())::text);

-- attendance: players only see their own rows (replaces the generic select)
create policy attendance_select on public.attendance for select to authenticated
  using (academy_id = (select public.my_academy_id())
         and ((select public.is_staff()) or player_id = (select public.my_player_id())));

-- notification read-state: strictly per user
create policy notification_reads_select on public.notification_reads for select to authenticated
  using (user_id = (select auth.uid()));
create policy notification_reads_insert on public.notification_reads for insert to authenticated
  with check (user_id = (select auth.uid())
              and exists (select 1 from public.notifications n
                           where n.id = notification_id
                             and n.academy_id = (select public.my_academy_id())));
create policy notification_reads_update on public.notification_reads for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy notification_reads_delete on public.notification_reads for delete to authenticated
  using (user_id = (select auth.uid()));

-- ---------------------------------------------------------------------
-- 4b) E-MAIL VERIFICATION SUPPORT
--   * check_signup_code : lets the app validate the code BEFORE creating the
--                         auth user (callable before login, returns the role)
--   * complete_signup   : after the user confirmed the e-mail (6-digit code),
--                         builds the profile from the sign-up metadata. The
--                         role is still decided by the invite code, never by
--                         the client.
-- ---------------------------------------------------------------------
create or replace function public.check_signup_code(p_code text)
returns text language sql stable security definer set search_path = public as $$
  select case
           when c.admin_code = upper(btrim(coalesce(p_code, ''))) then 'admin'
           when c.coach_code = upper(btrim(coalesce(p_code, ''))) then 'coach'
           else 'player'
         end
    from public.academy_codes c
   where c.admin_code  = upper(btrim(coalesce(p_code, '')))
      or c.coach_code  = upper(btrim(coalesce(p_code, '')))
      or c.player_code = upper(btrim(coalesce(p_code, '')))
   limit 1
$$;

create or replace function public.complete_signup()
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_uid   uuid := auth.uid();
  v_meta  jsonb;
  v_row   public.users%rowtype;
  v_new   text;
  v_code  text;
begin
  if v_uid is null then raise exception 'not_authenticated' using errcode = '28000'; end if;

  -- idempotent: profile already there -> just return it
  select * into v_row from public.users where id = v_uid;
  if found then
    return jsonb_build_object('id', v_row.id, 'academy_id', v_row.academy_id,
                              'academy_name', v_row.academy_name, 'role', v_row.role,
                              'job_number', v_row.job_number, 'join_date', v_row.join_date);
  end if;

  select raw_user_meta_data into v_meta from auth.users where id = v_uid;
  v_new  := btrim(coalesce(v_meta->>'new_academy_name', ''));
  v_code := btrim(coalesce(v_meta->>'academy_code', ''));

  if v_new <> '' then
    return public.register_academy(v_new, coalesce(v_meta->>'name', ''),
                                   coalesce(v_meta->>'phone', ''), coalesce(v_meta->>'address', ''));
  elsif v_code <> '' then
    return public.join_academy(v_code, coalesce(v_meta->>'name', ''),
                               coalesce(v_meta->>'phone', ''), coalesce(v_meta->>'address', ''));
  end if;

  raise exception 'missing_signup_data' using errcode = 'P0001';
end $$;

-- ---------------------------------------------------------------------
-- 5) GRANTS (least privilege)
-- ---------------------------------------------------------------------
revoke all on all tables in schema public from anon;
revoke all on public.academy_codes from anon, authenticated;

do $$
declare f text;
begin
  -- callable by signed-in users
  foreach f in array array[
    'register_academy(text,text,text,text)', 'join_academy(text,text,text,text)',
    'get_academy_codes()', 'regenerate_academy_code(text)', 'delete_my_account()',
    'complete_signup()']
  loop
    execute format('revoke all on function public.%s from public, anon, authenticated', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;

  -- name check is allowed before login
  revoke all on function public.academy_name_available(text) from public;
  grant execute on function public.academy_name_available(text) to anon, authenticated;
  revoke all on function public.check_signup_code(text) from public;
  grant execute on function public.check_signup_code(text) to anon, authenticated;

  -- internal helpers: never callable from the API
  foreach f in array array['_gen_code(text)', '_create_academy_codes(uuid)', '_uuid_or_null(text)']
  loop
    execute format('revoke all on function public.%s from public, anon, authenticated', f);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 6) STORAGE: the "avatars" bucket used by player + profile photo upload
--    (it did not exist in the old scripts -> every upload failed)
-- ---------------------------------------------------------------------
do $$
begin
  insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
  values ('avatars', 'avatars', true, 2097152,
          array['image/jpeg', 'image/png', 'image/webp', 'image/gif'])
  on conflict (id) do update
    set public = true,
        file_size_limit = excluded.file_size_limit,
        allowed_mime_types = excluded.allowed_mime_types;
exception when others then
  raise notice 'Bucket setup skipped (%). Create a PUBLIC bucket named "avatars" in Dashboard > Storage.', sqlerrm;
end $$;

do $$
begin
  create policy avatars_read on storage.objects for select to public
    using (bucket_id = 'avatars');
  create policy avatars_insert on storage.objects for insert to authenticated
    with check (bucket_id = 'avatars');
  create policy avatars_update on storage.objects for update to authenticated
    using (bucket_id = 'avatars' and owner_id = (select auth.uid())::text)
    with check (bucket_id = 'avatars');
  create policy avatars_delete on storage.objects for delete to authenticated
    using (bucket_id = 'avatars' and owner_id = (select auth.uid())::text);
exception when others then
  raise notice 'Storage policies skipped (%). Add them in Dashboard > Storage > Policies.', sqlerrm;
end $$;

-- >>>>>>>>>>>>>>>>>>>> 04_qr_attendance.sql <<<<<<<<<<<<<<<<<<<<
-- =====================================================================
-- 04_qr_attendance.sql — QR check-in (signed token) + attendance trigger
-- Run AFTER 02_security_rpc.sql (FULL_SETUP.sql already includes it).
--
-- Flow:
--   player phone : issue_checkin_token(player_id)  -> "EFA.<player>.<exp>.<hmac>"  (shown as QR)
--   coach phone  : scan_attendance(token, date)    -> verifies + records "present" in ONE call
--                  returns {result: recorded | already, player_id, name, status}
--   errors (exception message): invalid_token | token_expired | player_not_found | forbidden
-- =====================================================================

create extension if not exists pgcrypto with schema extensions;

-- ---------------------------------------------------------------------
-- 1) Secret used to sign tokens. RLS on + NO policy = no client can read it.
-- ---------------------------------------------------------------------
create table public.app_secrets (
  key   text primary key,
  value bytea not null
);
alter table public.app_secrets enable row level security;
revoke all on public.app_secrets from anon, authenticated;

insert into public.app_secrets (key, value)
values ('checkin_hmac', extensions.gen_random_bytes(32));

create or replace function public._checkin_sig(p_payload text)
returns text language sql stable security definer set search_path = public, extensions as $$
  select encode(
    hmac(convert_to(p_payload, 'UTF8'),
         (select value from public.app_secrets where key = 'checkin_hmac'),
         'sha256'),
    'hex')
$$;
revoke all on function public._checkin_sig(text) from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- 2) Attendance trigger: team_id comes from the player row; the player must
--    belong to the same academy as the row (nobody can mark foreign players).
-- ---------------------------------------------------------------------
create or replace function public.trg_attendance_check()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_team text; v_ac uuid;
begin
  select team_id, academy_id into v_team, v_ac from public.players where id = new.player_id;
  if v_ac is null then raise exception 'player_not_found' using errcode = 'P0001'; end if;
  if new.academy_id is not null and new.academy_id <> v_ac then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  new.academy_id := v_ac;
  new.team_id    := v_team;
  return new;
end $$;

create trigger trg_attendance_check before insert or update on public.attendance
  for each row execute function public.trg_attendance_check();

-- ---------------------------------------------------------------------
-- 3) Issue a token (valid 10 minutes) — the player himself, or staff of the same academy
-- ---------------------------------------------------------------------
create or replace function public.issue_checkin_token(p_player text)
returns text language plpgsql security definer set search_path = public as $$
declare
  v_ac  uuid;
  v_exp bigint := extract(epoch from now())::bigint + 600;
  v_pl  text   := btrim(coalesce(p_player, ''));
begin
  if auth.uid() is null then raise exception 'forbidden' using errcode = '42501'; end if;

  select academy_id into v_ac from public.players where id = v_pl;
  if v_ac is null then raise exception 'player_not_found' using errcode = 'P0001'; end if;
  if v_ac is distinct from public.my_academy_id() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if not (public.is_staff() or public.my_player_id() = v_pl) then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  return 'EFA.' || v_pl || '.' || v_exp || '.' || public._checkin_sig(v_pl || '.' || v_exp);
end $$;

-- ---------------------------------------------------------------------
-- 4) Verify + record attendance (staff only). One round trip, instant DB write.
-- ---------------------------------------------------------------------
create or replace function public.scan_attendance(p_token text, p_date date default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  m        text[];
  v_pl     text;
  v_exp    bigint;
  v_ac     uuid;
  v_name   text;
  v_old    text;
  v_date   date := coalesce(p_date, (now() at time zone 'utc')::date);
begin
  if auth.uid() is null or not public.is_staff() then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  m := regexp_match(btrim(coalesce(p_token, '')), '^EFA\.(.+)\.([0-9]+)\.([0-9a-f]{64})$');
  if m is null then raise exception 'invalid_token' using errcode = 'P0001'; end if;
  v_pl  := m[1];
  v_exp := m[2]::bigint;

  if public._checkin_sig(v_pl || '.' || v_exp) <> m[3] then
    raise exception 'invalid_token' using errcode = 'P0001';
  end if;
  if v_exp < extract(epoch from now())::bigint then
    raise exception 'token_expired' using errcode = 'P0001';
  end if;

  select academy_id, name into v_ac, v_name from public.players where id = v_pl;
  if v_ac is null or v_ac is distinct from public.my_academy_id() then
    raise exception 'player_not_found' using errcode = 'P0001';
  end if;

  select status into v_old from public.attendance
   where player_id = v_pl and date = v_date and training_id is null;

  if v_old in ('present', 'late') then
    return jsonb_build_object('result', 'already', 'player_id', v_pl, 'name', v_name, 'status', v_old);
  end if;

  insert into public.attendance (player_id, academy_id, date, training_id, status, source, checked_in_at)
  values (v_pl, v_ac, v_date, null, 'present', 'qr', now())
  on conflict (player_id, date, training_id)
  do update set status = 'present', source = 'qr', checked_in_at = now();

  return jsonb_build_object('result', 'recorded', 'player_id', v_pl, 'name', v_name, 'status', 'present');
end $$;

revoke all on function public.issue_checkin_token(text)       from public, anon;
revoke all on function public.scan_attendance(text, date)     from public, anon;
grant execute on function public.issue_checkin_token(text)    to authenticated;
grant execute on function public.scan_attendance(text, date)  to authenticated;

-- >>>>>>>>>>>>>>>>>>>> 08_lineups.sql <<<<<<<<<<<<<<<<<<<<
-- =====================================================================
-- 08_lineups.sql — match line-ups (starters + substitutes)
-- Safe to run on its own on an existing database (no data is touched) and
-- safe to run twice. FULL_SETUP.sql already includes it.
--
--   role       : 'starter' (يلعب) | 'sub' (بديل)
--   sort_order : ترتيب اللاعب داخل القائمة
--   squad_size : عدد الأساسيين اللي المدرب حدّده للماتش (مكرر في كل صف)
-- Staff (admin + coach) edit; every member of the academy can read.
-- =====================================================================

create table if not exists public.match_lineups (
  match_id    text not null references public.matches(id) on delete cascade,
  player_id   text not null references public.players(id) on delete cascade,
  academy_id  uuid not null references public.academies(id) on delete cascade,
  role        text not null check (role in ('starter', 'sub')),
  sort_order  int  not null default 0,
  squad_size  int  not null default 11 check (squad_size between 1 and 30),
  created_at  timestamptz not null default now(),
  primary key (match_id, player_id)
);
create index if not exists match_lineups_academy_idx on public.match_lineups (academy_id);

alter table public.match_lineups enable row level security;

drop policy if exists match_lineups_select on public.match_lineups;
drop policy if exists match_lineups_insert on public.match_lineups;
drop policy if exists match_lineups_update on public.match_lineups;
drop policy if exists match_lineups_delete on public.match_lineups;

create policy match_lineups_select on public.match_lineups for select to authenticated
  using (academy_id = (select public.my_academy_id()));
create policy match_lineups_insert on public.match_lineups for insert to authenticated
  with check (academy_id = (select public.my_academy_id()) and (select public.is_staff()));
create policy match_lineups_update on public.match_lineups for update to authenticated
  using (academy_id = (select public.my_academy_id()) and (select public.is_staff()))
  with check (academy_id = (select public.my_academy_id()));
create policy match_lineups_delete on public.match_lineups for delete to authenticated
  using (academy_id = (select public.my_academy_id()) and (select public.is_staff()));

-- academy_id always comes from the signed-in user (same rule as every other table)
drop trigger if exists trg_match_lineups_academy on public.match_lineups;
create trigger trg_match_lineups_academy before insert or update on public.match_lineups
  for each row execute function public.trg_set_academy_id();

-- the match and the player must belong to the same academy (a player of ANOTHER team
-- of the same academy is allowed on purpose: coaches borrow players between teams)
create or replace function public.trg_match_lineups_check()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if not exists (
    select 1 from public.matches m
      join public.players p on p.academy_id = m.academy_id
     where m.id = new.match_id and p.id = new.player_id
  ) then
    raise exception 'invalid_lineup' using errcode = 'P0001';
  end if;
  return new;
end $$;

drop trigger if exists trg_match_lineups_check on public.match_lineups;
create trigger trg_match_lineups_check before insert or update on public.match_lineups
  for each row execute function public.trg_match_lineups_check();

grant select, insert, update, delete on public.match_lineups to authenticated;
grant all on public.match_lineups to service_role;
notify pgrst, 'reload schema';

-- >>>>>>>>>>>>>>>>>>>> 09_admin_wipe_function.sql <<<<<<<<<<<<<<<<<<<<
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

-- >>>>>>>>>>>>>>>>>>>> 05_grants.sql <<<<<<<<<<<<<<<<<<<<
-- =====================================================================
-- 05_grants.sql — table-level privileges for the Data API (PostgREST)
-- Without these every client query fails with:
--   42501 permission denied for table ...   (RLS only filters rows; the role
--   still needs GRANTs on the table itself).
-- Safe to run on its own at any time (no data is touched).
-- =====================================================================

grant usage on schema public to anon, authenticated;

grant select, insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;
grant all on all tables in schema public to service_role;
grant all on all sequences in schema public to service_role;

-- future tables get the same grants
alter default privileges in schema public
  grant select, insert, update, delete on tables to authenticated;
alter default privileges in schema public
  grant usage, select on sequences to authenticated;

-- never exposed to the client (RLS also blocks them, this is a second lock)
revoke all on all tables in schema public from anon;
do $$
begin
  revoke all on public.academy_codes from anon, authenticated;
  revoke all on public.app_secrets   from anon, authenticated;
exception when undefined_table then null;
end $$;

notify pgrst, 'reload schema';

