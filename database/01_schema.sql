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
create table public.attendance (
  player_id  text not null,
  team_id    text,
  academy_id uuid not null references public.academies(id) on delete cascade,
  date       date not null,
  status     text not null check (status in ('present','absent','late')),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  primary key (player_id, date)               -- required by upsert onConflict 'player_id,date'
);
create index attendance_academy_date_idx on public.attendance (academy_id, date);
