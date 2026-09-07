-- Clear all tables (preserves schema, removes data)
TRUNCATE TABLE attendance, events, students, courses, users RESTART IDENTITY CASCADE;