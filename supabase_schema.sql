-- Supabase Database Schema for NTC-A-Track
-- Run this in Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (admins)
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  username TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  salt TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'admin',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Courses table
CREATE TABLE courses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  course_name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Students table
CREATE TABLE students (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id TEXT NOT NULL UNIQUE,
  last_name TEXT NOT NULL,
  first_name TEXT NOT NULL,
  course TEXT NOT NULL,
  year_level TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  salt TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Events table
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT FALSE,
  flow_type TEXT NOT NULL DEFAULT 'ONE_TIME',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Attendance table
CREATE TABLE attendance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  time TIME NOT NULL,
  status TEXT NOT NULL DEFAULT 'PRESENT',
  check_type TEXT NOT NULL DEFAULT 'PRESENT',
  event_id UUID REFERENCES events(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, date, event_id, check_type)
);

-- Indexes for performance
CREATE INDEX idx_attendance_date ON attendance (date);
CREATE INDEX idx_attendance_student_id ON attendance (student_id);
CREATE INDEX idx_attendance_event_id ON attendance (event_id);
CREATE INDEX idx_students_student_id ON students (student_id);
CREATE INDEX idx_users_username ON users (username);

-- Row Level Security (RLS) Policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

-- Public read access for authenticated users (adjust as needed)
CREATE POLICY "Allow authenticated read users" ON users
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated read courses" ON courses
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated read students" ON students
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated read events" ON events
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated read attendance" ON attendance
  FOR SELECT TO authenticated USING (true);

-- Admin write policies (using service role key in backend)
CREATE POLICY "Allow service role full access users" ON users
  FOR ALL TO service_role USING (true);

CREATE POLICY "Allow service role full access courses" ON courses
  FOR ALL TO service_role USING (true);

CREATE POLICY "Allow service role full access students" ON students
  FOR ALL TO service_role USING (true);

CREATE POLICY "Allow service role full access events" ON events
  FOR ALL TO service_role USING (true);

CREATE POLICY "Allow service role full access attendance" ON attendance
  FOR ALL TO service_role USING (true);

-- Seed default courses
INSERT INTO courses (course_name) VALUES
  ('BSIT'),
  ('BSCS'),
  ('BSCE'),
  ('BSECE'),
  ('BSME')
ON CONFLICT (course_name) DO NOTHING;

-- Note: You'll need to create an admin user through the app or manually
-- Default admin: username='admin', password='admin123' (will be hashed by the app)