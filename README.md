# MoTirong

> Geo-tagged, biometrically verified staff attendance for Mangaung Metro Municipality — built to make clock-in/clock-out records trustworthy and auditable.

## About

MoTirong is a cross-platform mobile app for municipal staff attendance. Employees clock in and out using their phone's biometric sensor (Face ID, fingerprint) or a PIN, combined with GPS geofence validation. HR and management get verifiable, tamper-resistant attendance records, and no raw biometric data is ever collected or stored.

This repo is the Flutter app. It is one of three parts:

| Repo | What it is |
|---|---|
| **motiroong-mobile** (this repo) | Flutter app for employees (Android & iOS) |
| [motiroong-backend](https://github.com/Jabulile1704/motiroong-backend) | Firebase backend: Firestore, Auth and Cloud Functions (TypeScript) |
| [admin-motiroong](https://github.com/Jabulile1704/admin-motiroong) | Next.js admin dashboard for admins and supervisors |

## Features

- 📍 **Geofenced clock-in/out** — the phone's GPS position is checked against the assigned site's radius. Clocking in off-site is recorded and flagged, not refused.
- 👆 **Biometric or PIN sign-in** — Face ID / fingerprint is checked by the OS on the phone and never sent to the server. A PIN is available as a fallback.
- 🪪 **Staff-card sign-up** — new employees register with their staff number and wait in a pending state until an admin approves them.
- 🛠 **Exception requests** — employees explain flagged shifts; supervisors approve or deny them in the admin dashboard, with a full audit trail.
- 🕘 **Home, History and Profile screens** backed by live data from the backend.

## How it works

The app never writes attendance data itself. It reads its own profile, history and site geofences from Firestore, and calls **callable Cloud Functions** for everything that changes state (sign-up, device enrollment, clock in/out, exceptions). The server sets the timestamps and decides the geofence verdict, so a phone with a wrong clock or a spoofed position can't author its own shift.

### Biometric sign-in

1. On enrollment the phone generates a random **device secret** and stores it in the iOS Keychain / Android Keystore behind a biometric gate (`flutter_secure_storage`).
2. Only a hash of the secret is sent to the backend (`enrollDevice`).
3. To sign in, the OS checks the user's face or fingerprint (`local_auth`). Passing releases the secret, which the app presents to `signInWithDevice`.
4. The backend compares the hash and returns a Firebase custom token.

The server verifies possession of an enrolled device plus a local user-presence check, the same guarantee as a passkey. See the [backend README](https://github.com/Jabulile1704/motiroong-backend#how-biometric-sign-in-works) for the full design.

## Tech Stack

| Layer | Technology |
|---|---|
| App | Flutter (Android & iOS) |
| Backend | Firebase Cloud Functions (TypeScript), region `africa-south1` |
| Database | Cloud Firestore |
| Auth | Firebase Auth + custom tokens for device sign-in |
| On-device security | `local_auth`, `flutter_secure_storage` (Keychain / Keystore) |
| Location | `geolocator` |
| Admin | Next.js dashboard ([admin-motiroong](https://github.com/Jabulile1704/admin-motiroong)) |

## Project Structure

```
lib/
├── main.dart            → Firebase init, optional emulator switch
├── app.dart             → MaterialApp, theme and routing
├── core/
│   ├── network/         → FunctionsClient (callable functions, emulator config)
│   ├── services/        → biometric, location and secure storage services
│   ├── theme/           → colours, typography, brand
│   └── widgets/         → shared UI (glass nav bar, status pills, splash, …)
└── features/
    ├── auth/            → sign-up, login, PIN setup, device enrollment, pending approval
    ├── attendance/      → home (clock in/out), history
    ├── exceptions/      → exception request screen
    └── profile/         → profile screen
```

## Getting Started

### Prerequisites

- Flutter SDK (stable channel)
- Firebase CLI and Node.js (to run the backend locally)
- Xcode (iOS) and/or Android Studio (Android)

### 1. Start the backend

Cloud Functions need Firebase's Blaze plan, so during development the backend runs in the **Firebase Emulator Suite**. Follow the setup in [motiroong-backend](https://github.com/Jabulile1704/motiroong-backend#setup) and start the emulators (Auth, Firestore, Functions).

### 2. Run the app

```bash
flutter pub get

# iOS simulator or Flutter web
flutter run --dart-define=USE_EMULATORS=true

# Android emulator
flutter run --dart-define=USE_EMULATORS=true --dart-define=EMULATOR_HOST=10.0.2.2

# Physical phone on the same Wi-Fi (use your computer's LAN IP)
flutter run --dart-define=USE_EMULATORS=true --dart-define=EMULATOR_HOST=192.168.x.x
```

Without `USE_EMULATORS` the app connects to the deployed Firebase project configured in `lib/firebase_options.dart`.

## Branching Strategy

| Branch | Purpose |
|---|---|
| `main` | Production-ready code only. Merges via pull request. |
| `feature/<short-desc>` | One branch per user story/task, branched from `main`. |

## Contributing

1. Create a `feature/` branch from `main`
2. Open a pull request against `main` and link the related issue
3. At least one review is required before merging

## Author

**Jabulile Mashibini** — [GitHub](https://github.com/Jabulile1704) · [LinkedIn](https://linkedin.com/in/jabulile-mashibini)

## License

*(To be determined — add the municipality's licensing terms here.)*
