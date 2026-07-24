# DELIVERY MANIFEST — Aurora Social Discovery MVP

**اسم الحزمة:** `AURORA_MVP_FINAL_COMPLETE.zip`
**تاريخ الإنشاء:** 2026-07-24
**الفرع:** `finish/mvp-production-readiness`

> **ملاحظة صدق:** هذا الملف يُلتزَم قبل إنشاء الأرشيف، لذا `HEAD` داخل `.git` في الحزمة = التزام هذا المانيفست (لا يمكن لالتزام أن يحتوي بصمة نفسه). حجم الأرشيف وبصمته النهائية (SHA-256) وكذلك آخر Commit مذكورة في رسالة التسليم المرافقة.

---

## محتوى الحزمة
- جذر المشروع كاملًا عند آخر Commit: Flutter (`apps/mobile`) + NestJS/Prisma (`services/api`) + Docker (`infrastructure`) + الاختبارات + CI + التوثيق.
- `.git/` كاملًا مع سجل الالتزامات وفرع العمل `finish/mvp-production-readiness`.
- `delivery/apks/` — APK التجريبي النهائي (debug) + APK الإنتاج الآمن (release).
- `.env.example` (بلا أسرار) على مستوى الجذر و`services/api/`.

## الملفات المهمة
- `FINAL_MVP_REPORT.md` (التقرير النهائي) · `HANDOFF.md` · `README.md` · `DELIVERY_MANIFEST.md`
- `docs/LOCAL_RUNTIME_VERIFICATION.md` · `docs/test_results.log`
- `services/api/` — `src/` (auth, users, profiles, discovery, interactions, messaging, moderation, health, prisma, common), `prisma/schema.prisma` + `migrations/` (3), `test/` (unit + 3 e2e specs), `package.json`, `.env.example`
- `apps/mobile/` — `lib/` (main + api client + 7 شاشات + widgets/safety_actions), `test/` (3 ملفات), `pubspec.yaml`, `android/`, `windows/`
- `.github/workflows/` — `ci-api.yml`, `ci-flutter.yml`, `docs-quality.yml`

## ملفات APK (توقيع Debug/اختباري — ليست توقيع Google Play)
| الملف | النوع | الحجم (بايت) | SHA-256 |
|---|---|---|---|
| `delivery/apks/aurora-mvp-v1-arm64-v8a-debug.apk` | debug (HTTP محلي مسموح) | 75,609,345 | `e4876fcc7a0ee477c13884327a508d6f825fc3f131082193c7d6ba3964c0f3e0` |
| `delivery/apks/aurora-mvp-v1-arm64-v8a-release.apk` | release (HTTPS فقط) | 17,624,661 | `ae9a647ab9d2a0b2a9b6a32662d9ea9a7dd2aa6dffba4c69433182b84d30d4fe` |

## ما تم اختباره (مُتحقَّق منه حيًّا — انظر docs/LOCAL_RUNTIME_VERIFICATION.md)
- PostgreSQL 16 + Prisma: 3 مهاجرات مطبّقة، لا انحراف.
- NestJS build (exit 0) · `/api/health` → 200 `{"status":"ok","db":"up"}`.
- Backend: unit **5/5** · e2e **26/26** (10 أساس + 9 MVP-A + 7 أمان).
- سيناريو حي عبر curl (11 خطوة: تسجيل→…→حذف→رفض التوكن فورًا) — كله ✅.
- Flutter analyze **No issues** · flutter test **13/13** · APK debug+release مبنيان.
- تحقّق aapt2: cleartext مغلق في Release، مفتوح في Debug، INTERNET موجود.

## ما لم يُختبر (بصدق)
- الفتح على **جهاز/محاكي Android حقيقي** (لا محاكي/شاشة) — **الاختبار النهائي على هاتف حقيقي ما زال مطلوبًا**.
- بناء/تشغيل **Windows** (عبر CI `windows-latest`).
- **توقيع Release إنتاجي** (توقيع Debug فقط — لا أسرار).

## المستثنى من الحزمة (عمدًا)
`node_modules/` · `services/api/dist/` · `apps/mobile/build/` و`.dart_tool/` و`android/.gradle/` · أي `.env` حقيقي · caches · ملفات مؤقتة · APKs الوسيطة (v7a/x86_64) والـ debug الكامل غير المقسّم.

## طريقة التشغيل (مختصر — التفصيل في README.md / FINAL_MVP_REPORT.md)
```bash
docker compose -f infrastructure/docker-compose.dev.yml up -d
cd services/api && cp .env.example .env && npm ci && npx prisma generate && npx prisma migrate deploy && npm run build && npm run start:prod
curl http://localhost:3000/api/health
cd ../../apps/mobile && flutter pub get && flutter analyze && flutter test
```

---
**آخر Commit وبصمة الأرشيف النهائية:** في رسالة التسليم المرافقة (يتعذّر وضعهما داخل الأرشيف نفسه).
