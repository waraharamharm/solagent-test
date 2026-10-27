## Context

The app opens SSH sessions through `ISshConnector` and runs scripts via
`DeployEngine`. Every AI command still needs user confirmation. The knowledge
server (`rag_server`, FastAPI, Bearer `sol_...` keys) already runs at
`https://rag.mtoper.ru`.

## Decisions

1. **Detached install on the VDS.** Already done in stage 1: `DeployEngine`
   starts the script with `setsid nohup` and the app polls its log. Losing SSH
   does not kill the build; `RunMonitor` reconnects.
2. **Checkpoint format.** A log line `@@SOLAGENT {"step":"...","state":"started|done|failed|finished"}`.
   No logs and no secrets in checkpoints; logs stay on the VDS and are
   redacted by `LogRedactor` before the AI sees them.
3. **Relay lives in `rag_server`.** One more FastAPI router, same key auth and
   rate limits, so no new host. The FCM service account exists only on the
   server, never in the app or the repo.
4. **Who pushes.** The user's VDS posts a checkpoint to the relay using a
   per-run token issued when the run starts. The relay validates the token,
   looks up the device token registered for that run, and sends a data-free
   notification (step name and state only).
5. **App-side monitoring.** A foreground service (`dataSync`) holds a wake lock
   only while a run is active; the monitor polls the job log over SSH; push is
   the fallback when the service is killed.
   Push uses `notification` messages rendered by the system, so no local
   notification dependency is needed.
6. **Permissions.** Android 13+ `POST_NOTIFICATIONS` asked at the first run,
   not at launch. Foreground service type `dataSync`; verify against current
   Play policy before release.

## Risks / Trade-offs

- Battery optimizations on some phones kill foreground services; push covers it.
- The VDS must reach the relay over HTTPS; if blocked, the app still polls.
- A leaked run token allows spam pushes for that run only; tokens expire when the
  run ends and the relay rate-limits per token.

## Open Questions

- Firebase project and `google-services.json` from Tim.
- Package name of the Android app registered in Firebase.
- Whether the uncle wants the relay inside `rag_server` or as a separate service.
