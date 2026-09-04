# QR Code-Based Student Attendance System (Flutter)

A complete Flutter attendance app with two roles — **Admin** and **Student** —
built for a local demo. Attendance is recorded by scanning each student's QR
code with the device camera.

The database is **100% local** (SQLite via `sqflite`) — no server, no internet,
and no Firebase required. Everything runs on the device, which makes it ideal
for classroom demos and presentations.

## ✨ Features

### Admin
- Login with username + password (role-based auth)
- Dashboard with stats: Total Students, Present Today, Absent Today, Total Attendance
- Student management: add, edit, delete, view, search, filter by course & year level
- Automatic unique QR code per student (encodes the Student ID)
- **QR scanner** (device camera) → auto-records attendance
- Duplicate-attendance prevention (one record per student per day — enforced
  by the database with a `UNIQUE(student_id, date)` constraint)
- Invalid / unknown QR handling ("Student Not Found")
- Attendance records: search + filter by date, course, year level and status
- Recent attendance feed on the dashboard

### Student
- Login with Student ID + password
- Sees **only their own** info, QR code and attendance history
- Attendance summary: days attended, missed, total, attendance rate
- Cannot access any admin screen (role guards on every shell/scanner)

## 🔐 Demo accounts (seeded automatically on first launch)

| Role    | Username / ID | Password   |
| ------- | ------------- | ---------- |
| Admin   | `admin`       | `admin123` |
| Student | `2026-0001`   | `student123` |

Five sample students are seeded (`2026-0001` … `2026-0005`) along with several
days of attendance history so the dashboards look alive immediately.

## 🚀 Getting started

```bash
flutter pub get
flutter run        # on an Android device/emulator
```

> The QR scanner uses the device camera, so run on a **physical Android
> device** for the full demo. The app also runs on iOS, but the demo is
> targeted at Android.

### Android camera permission

Already configured — `android/app/src/main/AndroidManifest.xml` includes:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

The app requests camera access at runtime when the scanner first opens. If
permission is denied, the scanner shows a friendly error with a retry button
instead of crashing.

### iOS camera permission

`ios/Runner/Info.plist` includes `NSCameraUsageDescription`, so iOS builds are
ready to go as well.

## 🗄️ Database (local demo)

- **Engine:** SQLite through `sqflite`, stored on-device at
  `attendance_system.db` (created on first run).
- **Tables:**
  - `users` — admin account (username, salted password hash, role)
  - `students` — student records + credentials (student ID, name, course, year
    level, salted password hash)
  - `attendance` — one row per student per day
    (`UNIQUE (student_id, date)` blocks duplicates at the DB level)
- **Seed data** is inserted on first launch (see demo accounts above).
- To start fresh: uninstall the app or delete the database file.

### Data model

```
students (1) ──────── (N) attendance
student_id  PK, UNIQUE     student_id   FK → students.student_id (CASCADE)
last_name                  date         yyyy-MM-dd
first_name                 time         HH:mm
course                     status       PRESENT / ABSENT
year_level                 created_at
password_hash / salt
```

## 📦 Packages used

| Package            | Purpose                                        |
| ------------------ | ---------------------------------------------- |
| `sqflite` + `path` | Local SQLite database                          |
| `qr_flutter`       | QR code generation (renders Student ID)        |
| `mobile_scanner`   | Camera QR scanning (Android/iOS, ML Kit)       |
| `shared_preferences` | Persists the login session across restarts   |
| `crypto`           | Salted SHA-256 password hashing                |
| `intl`             | Date / time formatting                         |

## 🏗️ Architecture

Clean, layered structure — UI screens talk to services, services own all
database access:

```
lib/
├── main.dart               # App entry, theme, session-aware splash routing
├── models/                 # User, Student, Attendance
├── screens/
│   ├── auth/               # Role selection + login (admin/student)
│   ├── admin/              # Dashboard, students CRUD, QR scanner, attendance,
│   │                       # profile — wrapped in AdminShell (bottom nav)
│   └── student/            # Dashboard, My QR, My Attendance, Profile —
│                           # wrapped in StudentShell (bottom nav)
├── services/
│   ├── database_service.dart   # SQLite schema, seeding, queries
│   ├── auth_service.dart       # Login/logout per role, hashing
│   ├── student_service.dart    # Student CRUD + search/filter
│   ├── attendance_service.dart # Scan→record, duplicate checks, stats
│   └── session_service.dart    # Persistent login session
├── widgets/                # Reusable cards, buttons, empty states, QR card
└── utils/                  # Theme, colors, validators, formatters
```

### How the core flows work

**Admin records attendance**
1. Admin opens **Scan** → camera opens (`mobile_scanner`).
2. A QR code is decoded → its payload is the Student ID (e.g. `2026-0001`).
3. The app looks the student up in SQLite.
4. If the student already has a record **today**, it shows
   "Attendance Already Recorded" — no new row is created.
5. Otherwise a `PRESENT` row is inserted and the confirmation screen shows the
   student's details, date and time.

**QR generation** — a QR is not stored as an image; it is rendered on demand
from the Student ID (`QrImageView(data: student.studentId)`). Adding or editing
a student therefore always yields a unique, correct QR automatically.

**Security** — passwords are stored as salted SHA-256 hashes (never plain
text). Every admin screen and the scanner re-checks the active session role
before rendering, so a student can never reach admin features by navigating.

## 🧪 Tests

```bash
flutter test
```

Runs a boot/smoke widget test plus service-level tests (auth, CRUD, duplicate
attendance prevention, stats) against an in-memory SQLite database.

## 📝 Notes for the demo

- The camera scanner needs a real device; the Android emulator camera can scan
  from a still image feed if configured.
- Since everything is local, attendance "today" follows the device clock — a
  nice trick for demos is scanning before/after midnight to show the
  duplicate-prevention and per-day reset behavior.
