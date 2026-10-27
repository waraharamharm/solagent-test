## Why

A real Flexisip build takes about 40 minutes. Today the app must stay open and
the SSH session must stay alive for the whole run; if Android freezes the app
or the connection drops, the user does not know whether the install finished.
Stage 9 of the product plan (`docs/STATUS.md`) adds a foreground service, push
notifications (FCM) and a relay that sends checkpoint pushes.

## What Changes

- Android foreground service keeps a long install monitored and visible in a
  persistent notification with the current step.
- Long installs run on the VDS detached from the SSH session (survives a lost
  connection) and write checkpoints to a file on the VDS.
- The app registers its FCM token with a relay on the knowledge server host.
- The relay sends a push when a checkpoint arrives (step done, failed, finished)
  while the app is not in the foreground.
- Android 13+ notification permission flow and Firebase setup
  (`google-services.json`, not committed).

Out of scope: the real Flexisip install scripts (stage 10), iOS push,
multi-server installs.

## Capabilities

### New Capabilities
- `background-monitoring`: foreground service, detached install, checkpoints,
  relay and push notifications.

### Modified Capabilities
- none (no specs exist yet; older stages are documented in `docs/`).

## Impact

- New: `lib/features/monitor/**`, Android manifest, `rag_server` relay endpoints
  (or a sibling `relay/` service), docs.
- New dependencies (each needs approval): `firebase_core`, `firebase_messaging`,
  a foreground-service plugin.
- Security-sensitive: remote command execution on the VDS, token handling, relay
  authentication. The orchestrator implements these parts, not subagents.
