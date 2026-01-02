# table_checking_app
Flutter app that signs users in with Firebase Auth, fetches an ID token, and calls a Cloud Run backend. Cloud Run verifies the Firebase ID token before any read/write and owns all backend logic.

## What changed
- Firebase Auth sign-in/sign-up UI (email + password)
- Cloud Run base URL is configurable via `--dart-define=CLOUD_RUN_BASE_URL=...`
- All requests include `Authorization: Bearer <idToken>`; unauthenticated calls are rejected
- Cloud Run backend sample added in `cloudrun_backend/` (Express + Firebase Admin) with token verification and Firestore-backed `/table` endpoints
- MVVM structure in the Flutter app:
  - **Models:** `lib/models/table_entry.dart`
  - **ViewModels:** `lib/viewmodels/auth_view_model.dart`, `lib/viewmodels/table_lookup_view_model.dart`
  - **Views:** `lib/auth_screen.dart`, `lib/auth_gate.dart`, `lib/enterphone.dart`, `lib/tableno.dart`
  - **Services:** `lib/services/auth_service.dart`, `lib/services/table_lookup_service.dart`

## Prerequisites
- Flutter SDK and the Firebase CLI
- Firebase project with Authentication enabled
- Cloud Run service deployed (see `cloudrun_backend/README.md`) that verifies Firebase ID tokens

## Configure Firebase in the app
1. Generate `lib/firebase_options.dart` with your project settings:
   ```bash
   flutter pub get
   flutterfire configure --project <your-project-id> --out lib/firebase_options.dart
   ```
2. Or manually replace the placeholder values in `lib/firebase_options.dart`.

## Running the app
```bash
flutter pub get
flutter run --dart-define=CLOUD_RUN_BASE_URL=https://<your-cloud-run-host>.a.run.app
```

## Cloud Run backend
- Code lives in `cloudrun_backend/` (Node/Express + Firebase Admin)
- Verifies `Authorization: Bearer <idToken>` on every endpoint
- `POST /table` – lookup table by phone
- `PUT /table` – upsert mapping (writes require valid ID token)
- Optional `POST /auth/signup` helper that creates Firebase users (lock down with `ADMIN_SECRET`)

Deploy instructions are in `cloudrun_backend/README.md`. Point the Flutter app’s `CLOUD_RUN_BASE_URL` at the deployed service.
