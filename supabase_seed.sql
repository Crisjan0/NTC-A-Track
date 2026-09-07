-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- USERS (Admins) - password: admin123
-- ============================================
INSERT INTO users (id, username, password_hash, salt, role, created_at)
VALUES (
  uuid_generate_v4(),
  'admin',
  'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3',
  'static_salt_for_demo',
  'admin',
  NOW()
)
ON CONFLICT (username) DO NOTHING;

-- ============================================
-- COURSES
-- ============================================
INSERT INTO courses (course_name, created_at) VALUES
  ('BS Information Technology', NOW()),
  ('BS Computer Science', NOW()),
  ('BS Accountancy', NOW()),
  ('BS Business Administration', NOW()),
  ('BS Nursing', NOW()),
  ('BS Engineering', NOW())
ON CONFLICT (course_name) DO NOTHING;

-- ============================================
-- STUDENTS - password: student123
-- ============================================
INSERT INTO students (id, student_id, last_name, first_name, course, year_level, password_hash, salt, created_at)
VALUES
  (uuid_generate_v4(), '2026-0001', 'Dela Cruz', 'Juan', 'BS Information Technology', '2nd Year', 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3', 'static_salt_for_demo', NOW()),
  (uuid_generate_v4(), '2026-0002', 'Santos', 'Maria', 'BS Computer Science', '1st Year', 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3', 'static_salt_for_demo', NOW()),
  (uuid_generate_v4(), '2026-0003', 'Reyes', 'Jose', 'BS Information Technology', '3rd Year', 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3', 'static_salt_for_demo', NOW()),
  (uuid_generate_v4(), '2026-0004', 'Garcia', 'Ana', 'BS Accountancy', '2nd Year', 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3', 'static_salt_for_demo', NOW()),
  (uuid_generate_v4(), '2026-0005', 'Mendoza', 'Carlos', 'BS Computer Science', '4th Year', 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3', 'static_salt_for_demo', NOW())
ON CONFLICT (student_id) DO NOTHING;

-- ============================================
-- EVENTS
-- ============================================
INSERT INTO events (id, name, is_active, flow_type, created_at)
VALUES
  (uuid_generate_v4(), 'General Attendance', true, 'ONE_TIME', NOW()),
  (uuid_generate_v4(), 'Intrams', false, 'TIME_IN_OUT', NOW())
ON CONFLICT DO NOTHING;

-- ============================================
-- ATTENDANCE (sample data for this week)
-- ============================================
DO $$
DECLARE
  default_event_id UUID;
  intrams_event_id UUID;
  student_uuids UUID[];
BEGIN
  SELECT id INTO default_event_id FROM events WHERE name = 'General Attendance' LIMIT 1;
  SELECT id INTO intrams_event_id FROM events WHERE name = 'Intrams' LIMIT 1;
  
  -- Get student UUIDs in order
  SELECT array_agg(id ORDER BY student_id) INTO student_uuids FROM students WHERE student_id LIKE '2026-%';
  
  -- General Attendance: Day 0 (today) - students 1,2,4
  INSERT INTO attendance (student_id, date, time, status, check_type, event_id, created_at)
  SELECT student_uuids[s.idx], CURRENT_DATE, '08:05'::TIME, 'PRESENT', 'PRESENT', default_event_id, NOW()
  FROM (VALUES (1), (2), (4)) s(idx)
  ON CONFLICT DO NOTHING;
  
  -- Day 1 (yesterday) - students 1,2,3,4
  INSERT INTO attendance (student_id, date, time, status, check_type, event_id, created_at)
  SELECT student_uuids[s.idx], CURRENT_DATE - 1, '08:06'::TIME, 'PRESENT', 'PRESENT', default_event_id, NOW() - INTERVAL '1 day'
  FROM (VALUES (1), (2), (3), (4)) s(idx)
  ON CONFLICT DO NOTHING;
  
  -- Day 2 - students 1,2,3,5
  INSERT INTO attendance (student_id, date, time, status, check_type, event_id, created_at)
  SELECT student_uuids[s.idx], CURRENT_DATE - 2, '08:07'::TIME, 'PRESENT', 'PRESENT', default_event_id, NOW() - INTERVAL '2 days'
  FROM (VALUES (1), (2), (3), (5)) s(idx)
  ON CONFLICT DO NOTHING;
  
  -- Day 3 - students 2,3,4,5
  INSERT INTO attendance (student_id, date, time, status, check_type, event_id, created_at)
  SELECT student_uuids[s.idx], CURRENT_DATE - 3, '08:08'::TIME, 'PRESENT', 'PRESENT', default_event_id, NOW() - INTERVAL '3 days'
  FROM (VALUES (2), (3), (4), (5)) s(idx)
  ON CONFLICT DO NOTHING;

  -- Intrams event: Time In/Out for students 2 (Maria) and 4 (Ana) - TODAY
  INSERT INTO attendance (student_id, date, time, status, check_type, event_id, created_at)
  VALUES
    (student_uuids[2], CURRENT_DATE, '08:00'::TIME, 'PRESENT', 'AM_IN', intrams_event_id, CURRENT_DATE::TIMESTAMPTZ),
    (student_uuids[2], CURRENT_DATE, '12:00'::TIME, 'PRESENT', 'AM_OUT', intrams_event_id, CURRENT_DATE::TIMESTAMPTZ),
    (student_uuids[2], CURRENT_DATE, '13:00'::TIME, 'PRESENT', 'PM_IN', intrams_event_id, CURRENT_DATE::TIMESTAMPTZ),
    (student_uuids[2], CURRENT_DATE, '17:00'::TIME, 'PRESENT', 'PM_OUT', intrams_event_id, CURRENT_DATE::TIMESTAMPTZ),
    (student_uuids[4], CURRENT_DATE, '08:05'::TIME, 'PRESENT', 'AM_IN', intrams_event_id, CURRENT_DATE::TIMESTAMPTZ),
    (student_uuids[4], CURRENT_DATE, '12:05'::TIME, 'PRESENT', 'AM_OUT', intrams_event_id, CURRENT_DATE::TIMESTAMPTZ),
    (student_uuids[4], CURRENT_DATE, '13:05'::TIME, 'PRESENT', 'PM_IN', intrams_event_id, CURRENT_DATE::TIMESTAMPTZ),
    (student_uuids[4], CURRENT_DATE, '17:05'::TIME, 'PRESENT', 'PM_OUT', intrams_event_id, CURRENT_DATE::TIMESTAMPTZ)
  ON CONFLICT DO NOTHING;

  -- Intrams event: Time In/Out for students 2 and 4 - YESTERDAY
  INSERT INTO attendance (student_id, date, time, status, check_type, event_id, created_at)
  VALUES
    (student_uuids[2], CURRENT_DATE - 1, '08:00'::TIME, 'PRESENT', 'AM_IN', intrams_event_id, (CURRENT_DATE - 1)::TIMESTAMPTZ),
    (student_uuids[2], CURRENT_DATE - 1, '12:00'::TIME, 'PRESENT', 'AM_OUT', intrams_event_id, (CURRENT_DATE - 1)::TIMESTAMPTZ),
    (student_uuids[2], CURRENT_DATE - 1, '13:00'::TIME, 'PRESENT', 'PM_IN', intrams_event_id, (CURRENT_DATE - 1)::TIMESTAMPTZ),
    (student_uuids[2], CURRENT_DATE - 1, '17:00'::TIME, 'PRESENT', 'PM_OUT', intrams_event_id, (CURRENT_DATE - 1)::TIMESTAMPTZ),
    (student_uuids[4], CURRENT_DATE - 1, '08:05'::TIME, 'PRESENT', 'AM_IN', intrams_event_id, (CURRENT_DATE - 1)::TIMESTAMPTZ),
    (student_uuids[4], CURRENT_DATE - 1, '12:05'::TIME, 'PRESENT', 'AM_OUT', intrams_event_id, (CURRENT_DATE - 1)::TIMESTAMPTZ),
    (student_uuids[4], CURRENT_DATE - 1, '13:05'::TIME, 'PRESENT', 'PM_IN', intrams_event_id, (CURRENT_DATE - 1)::TIMESTAMPTZ),
    (student_uuids[4], CURRENT_DATE - 1, '17:05'::TIME, 'PRESENT', 'PM_OUT', intrams_event_id, (CURRENT_DATE - 1)::TIMESTAMPTZ)
  ON CONFLICT DO NOTHING;
END $$;