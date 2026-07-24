# Delivery — Aurora MVP test builds

APKs in `apks/`. All are signed with a **debug/test key** — **not** a Google Play
production signature. Do not publish; create a real keystore first.

| File | Type | Cleartext HTTP | Use it for |
|---|---|---|---|
| `aurora-mvp-v1-arm64-v8a-debug.apk` | debug | **allowed** | Testing on a real arm64 phone against a **local** backend (`http://<LAN-IP>:3000/api`) |
| `aurora-mvp-v1-arm64-v8a-release.apk` | release | **blocked (HTTPS only)** | Demonstrates the production-safe network policy; point it at an HTTPS API |

`arm64-v8a` covers virtually all Android phones from the last several years. To
produce `armeabi-v7a` (older 32-bit) or `x86_64` (emulator) variants, run
`flutter build apk --debug --split-per-abi` (or `--release`).

## Install on a phone

1. Run the backend and DB (see repo `README.md` / `FINAL_MVP_REPORT.md`), listening on `0.0.0.0:3000`.
2. Transfer `aurora-mvp-v1-arm64-v8a-debug.apk` to the phone and install (allow "unknown sources").
3. The debug build defaults to `http://10.0.2.2:3000/api` (emulator). For a real phone,
   build/run with `--dart-define=API_BASE=http://<your-computer-LAN-IP>:3000/api`,
   or use the emulator.

Checksums: see `apks/CHECKSUMS.txt`.
