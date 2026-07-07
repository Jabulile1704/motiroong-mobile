# MoTiroong

> Geo-tagged, biometrically verified staff attendance for Mangaung Metro Municipality — built to make clock-in/clock-out records trustworthy and auditable.

## About

MoTiroong is a cross-platform mobile solution for municipal staff attendance. Employees clock in and out using their device's on-device biometric sensor combined with GPS geofence validation, giving HR and management verifiable, tamper-resistant attendance records without collecting or storing raw biometric data.

## Features

- 📍 **Geofenced clock-in/out** — location must fall within an assigned site's radius
- 👆 **On-device biometric verification** — fingerprint/face auth via the OS, never transmitted to the server
- 📶 **Offline-first** — clock events queue locally and sync automatically once connectivity returns
- 🛠 **Exception handling workflow** — employees can explain flagged events; supervisors approve/reject with a full audit trail
- 🗺 **Admin console** — manage sites, employees, devices, and export attendance reports
- 🔒 **JWT + refresh token auth** with device binding

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Android & iOS) |
| Backend | ASP.NET Core Web API |
| Database | PostgreSQL |
| Auth | JWT + Refresh Tokens |
| Cloud | Microsoft Azure (App Service, Key Vault, Application Insights) |
| CI/CD | GitHub Actions |
| API Docs | Swagger / OpenAPI |

## Project Structure

```
/mobile        → Flutter application
/api           → ASP.NET Core Web API
/docs          → SDLC documentation (use cases, ERD, API reference)
```

See [`/docs`](./docs) for the full use case documentation, entity relationship diagram, and API endpoint reference produced during the analysis and design phases.

## Getting Started

### Prerequisites
- Flutter SDK (stable channel)
- .NET 8 SDK
- PostgreSQL 15+ (or an Azure Database for PostgreSQL instance)
- An Azure subscription (for Key Vault / App Service if running cloud-connected)

### Backend setup
```bash
cd api
dotnet restore
dotnet ef database update
dotnet run
```
Swagger UI will be available at `https://localhost:<port>/swagger`.

### Mobile app setup
```bash
cd mobile
flutter pub get
flutter run
```

### Environment variables
Create a `.env` (mobile) and `appsettings.Development.json` (API) — **do not commit either file.** Required values:
- `API_BASE_URL`
- `JWT_SIGNING_KEY` (API only — store in Key Vault for non-local environments)
- `POSTGRES_CONNECTION_STRING`

## Branching Strategy

| Branch | Purpose |
|---|---|
| `main` | Production-ready code only. Protected — merges via PR from `release/*` or `hotfix/*`. |
| `develop` | Integration branch for completed features. |
| `feature/<short-desc>` | One branch per user story/task, branched from `develop`. |
| `release/x.y.z` | Cut from `develop` when preparing a release; only bug fixes allowed. |
| `hotfix/<short-desc>` | Urgent production fixes, branched from `main`, merged into both `main` and `develop`. |

## Contributing

1. Create a branch from `develop` following the naming convention above
2. Open a pull request against `develop` and link the related issue
3. At least one review is required before merging
4. Squash-merge to keep history clean

## License

