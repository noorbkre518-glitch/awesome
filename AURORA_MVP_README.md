# Aurora MVP — delivery on this branch

This branch (`claude/aurora-mvp-production-dyfonm`) carries the **Aurora Social
Discovery MVP** under [`aurora-mvp/`](aurora-mvp/) — a runnable NestJS + Prisma +
PostgreSQL backend and a Flutter (Android) client. It is unrelated to this
repository's main content and is placed here only as the working branch for the task.

## Start here
- [`aurora-mvp/FINAL_MVP_REPORT.md`](aurora-mvp/FINAL_MVP_REPORT.md) — what was fixed, security closures, run steps, real test results, APK hashes.
- [`aurora-mvp/README.md`](aurora-mvp/README.md) — how to run the DB, backend, and Flutter app.
- [`aurora-mvp/HANDOFF.md`](aurora-mvp/HANDOFF.md) — quick handoff.

## What's here vs. the full package
This subdirectory is the **source snapshot** (plus the small HTTPS-only release
APK). The complete deliverable — including the project's own `.git` history and
the larger debug/test APK — is the file `AURORA_MVP_FINAL_COMPLETE.zip`
(SHA-256 `5a001bf80917fba06c185d1e43f09f1d35ca8f792a55d579782a990f1e62e068`)
delivered separately.

- `aurora-mvp/delivery/apks/aurora-mvp-v1-arm64-v8a-release.apk` — release build (HTTPS only, production-safe).
- The debug/test APK (allows local HTTP for on-device testing) is in the zip, omitted here to keep the repo lean.

> APKs are debug/test-signed only — not a Google Play production signature.
> The final on-device test on a real Android phone is still required.
