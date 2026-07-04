# FamilyPulse 📅

A Flutter + Firebase family calendar app that finds shared free time across school, hobbies, and work schedules.

---

## Getting Started

### Prerequisites

- Flutter 3.44.4+
- Dart 3.12+
- VS Code with Flutter + Dart extensions
- Android Studio (for emulator)
- Firebase CLI

### Setup

```bash
# 1. Clone the repo
git clone https://github.com/rex-daworker/family_pulse.git

# 2. Enter the project
cd family_pulse

# 3. Install packages
flutter pub get

# 4. Run the app
flutter run
```

---

## Project Structure

```
family_pulse/
│
├── .github/workflows/
│   └── ci.yml                  # CI/CD — runs on every push automatically
│
├── lib/
│   ├── main.dart               # App entry point
│   ├── firebase_options.dart   # Auto-generated Firebase config
│   │
│   ├── core/
│   │   ├── constants/          # Colours, text styles, sizes
│   │   ├── theme/              # Light and dark mode
│   │   └── utils/              # Shared helper functions
│   │
│   ├── models/                 # Data shapes
│   │   ├── family_model.dart
│   │   ├── user_model.dart
│   │   └── event_model.dart
│   │
│   ├── services/               # Firebase backend logic (backend team)
│   │   ├── auth_service.dart   # Sign up, sign in, sign out
│   │   ├── event_service.dart  # CRUD + free-time finder algorithm
│   │   └── family_service.dart # Family creation and management
│   │
│   ├── providers/              # Riverpod state management
│   │   ├── auth_provider.dart
│   │   └── event_provider.dart
│   │
│   ├── screens/                # UI screens (frontend team)
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── home/
│   │   │   └── pulse_screen.dart
│   │   ├── calendar/
│   │   │   ├── calendar_screen.dart
│   │   │   └── event_form_screen.dart
│   │   └── finder/
│   │       └── free_time_screen.dart
│   │
│   └── widgets/                # Reusable UI components
│       ├── event_card.dart
│       ├── member_avatar.dart
│       └── free_slot_card.dart
│
├── test/                       # Unit tests
│   ├── auth_service_test.dart
│   └── event_service_test.dart
│
├── pubspec.yaml                # Dependencies
└── README.md
```

---

## Tech Stack

| Tool             | Purpose                             |
| ---------------- | ----------------------------------- |
| Flutter 3.44.4   | Mobile + web UI framework           |
| Dart 3.12        | Programming language                |
| Firebase Auth    | User login and registration         |
| Cloud Firestore  | Database — families, users, events  |
| Flutter Riverpod | State management                    |
| go_router        | Navigation between screens          |
| GitHub Actions   | CI/CD — auto test and build on push |

---

## Firestore Structure

```
families/
└── {family_id}/
    ├── name: String
    ├── created_at: Timestamp
    ├── users/
    │   └── {user_id}/
    │       ├── name: String
    │       ├── role: "parent" | "child"
    │       └── email: String
    └── events/
        └── {event_id}/
            ├── title: String
            ├── description: String
            ├── start_time: Timestamp
            ├── end_time: Timestamp
            ├── category: "school" | "hobby" | "work" | "other"
            ├── user_id: String
            └── user_name: String
```

---

## Task Division

### Backend team

- `lib/services/` — all Firebase logic
- `lib/models/` — data models
- `lib/providers/` — Riverpod state management
- Firebase security rules
- CI/CD pipeline

### Frontend team

- `lib/screens/` — all UI screens
- `lib/widgets/` — reusable components
- `lib/core/theme/` — app styling

---

## Git Workflow

Everyone works on their own branch. Never commit directly to `main`.

```bash
# Start of every session
git checkout your-branch
git pull origin main

# End of every session
git add .
git commit -m "feat: what you built"
git push origin your-branch

# When a feature is done — open a Pull Request on GitHub
```

### Branch naming

- `rex/backend`
- `member-name/feature-name`

---

## CI/CD Pipeline

Every push and pull request automatically runs:

1. `flutter analyze` — checks for code issues
2. `dart format` — checks code formatting
3. `flutter test` — runs all unit tests
4. `flutter build apk` — builds a debug APK

A pull request must pass all checks before it can be merged to `main`.

---

## Key Features

- Family shared calendar with member columns (school / hobbies / work)
- Free-time finder — filters when all selected members are free
- Real-time updates via Firestore streams
- Secure data — each family's data is isolated by Firestore security rules
- Supports iOS, Android, and Web
