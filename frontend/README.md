# Productivity Companion (Flutter + Backend)

Cross-platform personal productivity app scaffold with:
- Flutter UI for `Dashboard`, `Calendar`, `Settings`
- Backend APIs for analysis, AI scheduling, habits logic, Google Calendar, Supermemory
- Modal integration for LLM-powered automatic task/event gap filling
- GPS vs Google Calendar location trust checks (with manual confirmation fallback)
- Open-source location resolution using OpenStreetMap Nominatim

## Monorepo Structure

- `apps/flutter_app`: Flutter client (desktop, iOS, Android once Flutter tooling runs)
- `backend`: Node + TypeScript API service
- `.env.example`: root env key reference

## Feature Mapping

1. GPS location compared to GCal location (GCal optional, multiple okay)
- Endpoint: `POST /calendar/compare-location`
- Supports multiple GCal locations and optional manual confirmation requirement
- Can resolve plain-text GCal location labels via `POST /calendar/resolve-location`

2. Analysis
- Endpoint: `POST /analysis/summary`
- Returns:
  - on-task percentage
  - average focus minutes/day
  - week-over-week focus improvement
- Dashboard page includes chart and metric cards

3. LLM auto add tasks/events
- Endpoint: `POST /ai/fill-gaps`
- Uses Modal API integration

4. Habits prompt after two weeks
- Endpoint: `POST /habits/should-suggest-event`
- Trigger logic based on 14-day streak + completion rate

5. Pages
- Dashboard: analysis + focus graph
- Calendar: editable list, location compare, AI fill gaps
- Settings: habit prompt toggle, key/config visibility

## Environment

Copy examples:

```bash
cp .env.example .env
cp backend/.env.example backend/.env
cp apps/flutter_app/.env.example apps/flutter_app/.env
```

## Backend Setup

```bash
cd backend
npm install
npm run dev
```

## Quick GPS Difference Test

Run this while backend is running:

```bash
curl -X POST http://localhost:8787/calendar/compare-location \
  -H 'content-type: application/json' \
  -d '{
    "events":[
      {
        "id":"evt1",
        "title":"Library Session",
        "startIso":"2026-02-28T10:00:00.000Z",
        "endIso":"2026-02-28T11:00:00.000Z",
        "gcalLocations":[{"label":"Austin Central Library","source":"gcal"}],
        "gpsPoints":[{"lat":30.2659,"lng":-97.7494}],
        "requiresManualConfirmation":false
      }
    ]
  }'
```

## Flutter Setup

Flutter is not installed in this environment, so platform folders were not generated here.
When you have Flutter locally:

```bash
cd apps/flutter_app
flutter create .
flutter pub get
flutter run
```

Then keep the generated platform folders (`android/`, `ios/`, `macos/`, etc.) and existing `lib/` code.

## API Overview

- `GET /health`
- `POST /analysis/summary`
- `POST /ai/fill-gaps`
- `POST /calendar/compare-location`
- `POST /calendar/resolve-location`
- `GET /calendar/google-events`
- `POST /calendar/google-events`
- `POST /habits/should-suggest-event`
- `GET /memory/:key`
- `POST /memory`
