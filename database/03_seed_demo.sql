-- =====================================================================
-- 03_seed_demo.sql — OPTIONAL demo data (skip it in production)
--
-- Creates one demo academy with FIXED invite codes so you can test every
-- sign-up path immediately:
--     admin  code : ACAD-DEMO0001
--     coach  code : COACH-DEMO0001
--     player code : PLAYER-DEMO0001
-- plus 2 teams, 4 players, 2 trainings, 2 matches, 1 tournament, standings
-- and a welcome notification.
--
-- ⚠️ The codes are public (they are in this file): delete the demo before
--    going live →   delete from public.academies where name = 'Demo Academy';
--    (everything that belongs to it is removed by ON DELETE CASCADE)
-- Safe to run twice (it does nothing if the demo already exists).
-- =====================================================================
do $$
declare v_ac uuid;
begin
  if exists (select 1 from public.academies where name = 'Demo Academy') then
    raise notice 'Demo Academy already exists — skipped';
    return;
  end if;

  insert into public.academies (name) values ('Demo Academy') returning id into v_ac;

  insert into public.academy_codes (academy_id, admin_code, coach_code, player_code)
  values (v_ac, 'ACAD-DEMO0001', 'COACH-DEMO0001', 'PLAYER-DEMO0001');

  insert into public.teams (id, name, category, coach_name, color, icon_name, description, academy_id) values
    ('team_demo_1', 'الفريق الأول',  'تحت 16', '', 4279612550, 'shield', 'فريق تجريبي', v_ac),
    ('team_demo_2', 'فريق الناشئين', 'تحت 12', '', 4280391411, 'shield', 'فريق تجريبي', v_ac);

  insert into public.players (id, name, position, team_id, team_name, rating, goals, assists, matches, age, academy_id) values
    ('pl_demo_1', 'محمد علي',   'مهاجم',     'team_demo_1', 'الفريق الأول',  '8.1', 7, 3, 9, '16', v_ac),
    ('pl_demo_2', 'عمر خالد',   'وسط ميدان', 'team_demo_1', 'الفريق الأول',  '7.6', 2, 6, 9, '16', v_ac),
    ('pl_demo_3', 'يوسف حسن',   'مدافع',     'team_demo_1', 'الفريق الأول',  '7.2', 0, 1, 8, '15', v_ac),
    ('pl_demo_4', 'كريم أحمد',  'حارس مرمى', 'team_demo_2', 'فريق الناشئين', '7.9', 0, 0, 7, '12', v_ac);

  insert into public.trainings (id, title, type, location, date, time, duration_minutes, team_id, team_name, notes, academy_id) values
    ('tr_demo_1', 'تدريب لياقة', 'تدريب', 'ملعب الأكاديمية', date_trunc('day', now()) + interval '1 day', '05:00 م', 90, 'team_demo_1', 'الفريق الأول',  '', v_ac),
    ('tr_demo_2', 'تدريب مهارات', 'تدريب', 'ملعب الأكاديمية', date_trunc('day', now()) + interval '2 day', '04:00 م', 60, 'team_demo_2', 'فريق الناشئين', '', v_ac);

  insert into public.matches (id, team_id, team_name, opponent_name, venue, date, time, home_score, away_score, status, academy_id) values
    ('match_demo_1', 'team_demo_1', 'الفريق الأول', 'أكاديمية الأهلي',   'ملعب الأكاديمية', to_char(now() - interval '5 day', 'YYYY/MM/DD'), '05:00 م', 3, 1, 'finished', v_ac),
    ('match_demo_2', 'team_demo_1', 'الفريق الأول', 'أكاديمية الزمالك', 'ملعب الأكاديمية', to_char(now() + interval '6 day', 'YYYY/MM/DD'), '06:00 م', 0, 0, 'upcoming', v_ac);

  insert into public.tournaments (id, name, subtitle, date, status, teams_count, icon_name, academy_id) values
    ('tour_demo_1', 'دوري الناشئين', 'موسم تجريبي', to_char(now(), 'YYYY/MM/DD'), 'ongoing', 8, 'trophy', v_ac);

  insert into public.standings (team_id, team_name, played, won, drawn, lost, academy_id) values
    ('team_demo_1', 'الفريق الأول',  1, 1, 0, 0, v_ac),
    ('team_demo_2', 'فريق الناشئين', 1, 0, 1, 0, v_ac);

  insert into public.notifications (id, title, message, time, category, academy_id) values
    ('notif_demo_1', 'أهلاً بك في أكاديمية النخبة', 'ده حساب تجريبي — جرّب كل المزايا.', '09:00 ص', 'general', v_ac);
end $$;
