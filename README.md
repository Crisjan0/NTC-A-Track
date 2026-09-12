# QR Code-Based Student Attendance System (Flutter)

A complete Flutter attendance app with two roles — **Admin** and **Student** —
built for a local demo. Attendance is recorded by scanning each student's QR
code with the device camera.

The database is **Firebase Cloud Firestore** — admin accounts, students,
events and attendance sync through Firestore. Seed data is created
automatically on first launch (see demo accounts below).

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

## 🗄️ Database (Firebase Cloud Firestore + Auth)

- **Collections:** `users`, `students`, `courses`, `events`, `attendance`,
  plus `authdir` (login directory) and `roles` (per-account access records).
- **Auth:** Firebase Authentication (Email/Password provider) is the login
  gate. Each admin/student owns a synthetic versioned login
  (`a_<id>.v1@ntc-atrack.local`); `authdir` maps username / student ID to
  the current login, `roles` ties each Auth uid to `admin` / `student`.
  Passwords live only in Firebase Auth.
- **Rules:** see `firestore.rules` — role-based. Admins can read/write
  everything; students can read (never write); `authdir` lookups are public
  (no secrets inside); unwprovisioned accounts are denied everywhere.
- **Seed data** (admin `admin` / `admin123`, 5 students / `student123`) is
  inserted on first launch, including Auth accounts and roles.

### Firebase setup (one time, in order)

1. Console > your project > **Authentication > Get started > Sign-in
   method > Email/Password > Enable > Save**.
2. If the database already has pre-Auth data, **delete all documents**
   (or the whole database) so the seed can re-run with Auth accounts.
3. Keep the **open** rules published, run the app once (seed provisions
   everything), verify login works.
4. Paste `firestore.rules` into **Firestore > Rules > Publish** to lock it.
5. To wipe and start over later: temporarily re-publish open rules, wipe,
   run once, re-publish locked rules.

### Firebase setup (one time, in order)

1. Console > your project > **Authentication > Get started > Sign-in
   method > Email/Password > Enable > Save**.
2. If the database already has pre-Auth data, **delete all documents**
   (or the whole database) so the seed can re-run with Auth accounts.
3. Keep the **open** rules published, run the app once (seed provisions
   everything), verify login works.
4. Paste `firestore.rules` into **Firestore > Rules > Publish** to lock it.
5. To wipe and start over later: temporarily re-publish open rules, wipe,
   run once, re-publish locked rules.

### Data model

```
students (1) ──────── (N) attendance
student_id  text, UNIQUE     student_id   text (e.g. 2026-0001)
last_name                  date         yyyy-MM-dd
first_name                 time         HH:mm
course                     status       PRESENT / ABSENT
year_level                 check_type   PRESENT / AM_IN / AM_OUT / PM_IN / PM_OUT
password_hash / salt       event_id     event document ID
```

## 📦 Packages used

| Package            | Purpose                                        |
| ------------------ | ---------------------------------------------- |
| `firebase_core` + `cloud_firestore` | Cloud database (users, students, events, attendance) |
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
│   ├── firebase_database_service.dart # Firestore collections, seeding, queries
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
3. The app looks the student up in Firestore.
4. If the student already has a record **today for the active event**, it shows
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

Runs a boot/smoke widget test plus unit tests (CSV parsing, login rate
limiter). Firestore integration tests need a configured Firebase project /
emulator.

## 📝 Notes for the demo

- Attendance "today" follows the device clock — a nice trick for demos is
  scanning before/after midnight to show the duplicate-prevention and
  per-day reset behavior. The scanner needs a real device; the Android
  emulator camera can scan from a still image feed if configured.
