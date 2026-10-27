## 1. Design review
- [ ] 1.1 Uncle reviews this change (proposal, design, spec)
- [x] 1.2 Tim creates the Firebase project and puts `google-services.json` into `android/app/` (git-ignored)

## 2. Detached install and checkpoints
- [x] 2.1 Checkpoint model and parser (`lib/features/monitor/domain/checkpoint.dart`)
- [x] 2.2 Detached start already existed in `DeployEngine`; `RunMonitor` polls it, reconnects after a drop
- [x] 2.3 Tests with a fake SSH session (connection loss, junk lines, give-up)
- [x] 2.4 `checkpointPrelude`: shell helper that prints the marker and reports to the relay

## 3. Foreground service
- [x] 3.1 Dependency `flutter_foreground_task` approved and added
- [x] 3.2 Manifest, service type `dataSync`, notification channel, notification permission request
- [x] 3.3 `followRun` drives the notification from monitor snapshots
- [x] 3.4 Check on a real phone (service survives the screen off)

## 4. Relay and FCM
- [x] 4.1 `firebase_core` and `firebase_messaging` added; Google services Gradle plugin applied
- [x] 4.2 Relay endpoints in `rag_server`: `POST /v1/runs`, `POST /v1/runs/{id}/checkpoints`, hashed run tokens, limits
- [x] 4.3 Server tests: auth, rate limit, expiry, payload without sensitive data
- [x] 4.4 Client: `HttpRunRelay`, FCM token, Firebase init (not yet wired into a screen)
- [x] 4.5 Server: install `solrag[push]`, put the FCM service account on the VDS, set `SOLRAG_FCM_CREDENTIALS`
- [x] 4.6a Demo run wired: `FixRun` starts the notification and puts the checkpoint helper in front of the script
- [x] 4.6b Check a push on the phone

## 5. Docs and release
- [x] 5.1 Update `docs/ARCHITECTURE.md`, `docs/SECURITY.md`, `docs/STATUS.md`
- [ ] 5.2 Check on a real phone with the demo script, then archive this change