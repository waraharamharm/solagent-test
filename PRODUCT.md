# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users
A non-administrator who wants their own SIP telephony (Flexisip) running on their own rented VDS, driving the whole job from an Android phone, without knowing Linux. They paste a server address and a password or key, start the deployment, and come back to it while it runs for tens of minutes. When something fails, they are not expected to read the log; they need to understand what went wrong in plain Russian and decide whether to let the app fix it.

## Product Purpose
SolAgent turns "rent a VDS" into "my own communication server works" from a phone. It connects to the user's server over SSH, runs the deployment detached on the server, shows progress, and when a step fails, an AI the user brings (their own API key) diagnoses the log and proposes one fix command that runs only after the user approves it. Success: a working server without the user ever opening a terminal, and without any secret leaving the phone.

## Positioning
Both halves are the claim, equally: private (server credentials and the AI key live only in the phone's secure storage; logs are scrubbed of IPs, hosts, tokens and passwords before the AI sees them; the AI never runs anything without explicit approval) and zero-skill (a non-admin gets a self-hosted server, the AI repairs failures). A hosted control panel cannot make the first claim; a terminal app cannot make the second.

## Operating Context
- Used on the phone, often in passing: start a deployment, lock the phone, come back to progress or a notification.
- Long-running jobs (a full Flexisip build is around 40 minutes); the SSH connection may drop and the job keeps running on the server.
- Every security-sensitive screen (server, deployment, fix approval) sits behind a fingerprint / device PIN check.
- Bring-your-own-key AI: presets DeepSeek, Grok, OpenRouter, OpenAI, or a custom OpenAI-compatible endpoint.
- Supported servers: Ubuntu and Debian.

## Capabilities and Constraints
- Built: AI settings and key, server profile (host, port, login, password or key) with host-key fingerprint pinning (TOFU), server check (OS, arch, root), detached deployment engine with progress, AI self-fix loop with command approval, denylist and warnings for proposed commands.
- Planned: RAG knowledge server, real Flexisip deployment, foreground service and push notifications, release build.
- Russian-language UI.
- Undecided: product name may stay "SolAgent"; no logo or brand colors exist yet.

## Brand Commitments
Name: SolAgent. No logo, palette, or typeface has been committed.

## Evidence on Hand
No customers, testimonials, pricing, or metrics exist. Do not invent them.

## Product Principles
1. Nothing runs on the user's server without them seeing it first.
2. Secrets never leave the phone; say so where it matters, not everywhere.
3. Explain outcomes in plain Russian; the raw log is available, never required.
4. Long work is resumable: the user can leave and come back without losing state.
5. Safe by default: dangerous actions are refused, risky ones are flagged.
