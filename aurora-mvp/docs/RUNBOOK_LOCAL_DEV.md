# RUNBOOK — تشغيل الشريحة الأساس محليًا

هذه المرحلة: **base slice** — تسجيل/دخول + بوابة عمر 18+ + ملف شخصي (عرض/تحرير) + حظر + إبلاغ + حذف حساب + لوحة بلاغات للمشرف. **لا** دفع/Coins/بث/لايف خاص (مؤجلة).

## المتطلبات
- Node.js 20+ ، Docker + Docker Compose ، Flutter 3.44+ (Android SDK 36 + build-tools).

## 1) قاعدة البيانات (PostgreSQL عبر Docker)
```bash
cd infrastructure
docker compose -f docker-compose.dev.yml up -d
# انتظر حتى healthy:
docker inspect --format '{{.State.Health.Status}}' aurora-db-dev
```

## 2) الخادم (NestJS API)
```bash
cd services/api
cp .env.example .env            # DATABASE_URL, JWT_SECRET, PORT
npm ci
npx prisma generate
npx prisma migrate deploy       # أو: npx prisma migrate dev
npm run start                   # يستمع على :3000، المسارات تحت /api
```
تحقق: `curl http://localhost:3000/api/health` → `{"status":"ok","db":"up",...}`

### مسارات API
| Method | Path | الوصف | مصادقة |
|---|---|---|---|
| GET | /api/health | فحص صحة + DB | لا |
| POST | /api/auth/register | تسجيل (يرفض <18) | لا |
| POST | /api/auth/login | دخول | لا |
| GET | /api/profiles/me | ملفي | JWT |
| PATCH | /api/profiles/me | تحديث ملفي | JWT |
| POST | /api/users/block | حظر مستخدم | JWT |
| POST | /api/users/report | إبلاغ عن مستخدم | JWT |
| DELETE | /api/users/me | حذف حسابي | JWT |
| GET | /api/admin/reports | قائمة البلاغات | JWT (ADMIN/MOD) |
| PATCH | /api/admin/reports/:id | تغيير حالة بلاغ | JWT (ADMIN/MOD) |
| GET | /api/discovery | مرشحون للاكتشاف (واعٍ بالحظر) | JWT |
| POST | /api/interactions/like | إعجاب/Super Like (ينشئ Match عند التبادل) | JWT |
| GET | /api/interactions/matches | مطابقاتي | JWT |
| POST | /api/messaging/send | إرسال رسالة داخل مطابقة | JWT |
| GET | /api/messaging/:matchId | رسائل المطابقة | JWT |

## 3) العميل (Flutter — Android / Windows)
```bash
cd apps/mobile
flutter pub get
# Android (محاكي): يصل للـ API عبر 10.0.2.2 تلقائيًا
flutter run -d android
# Windows (على جهاز Windows):
flutter run -d windows
# تجاوز عنوان الخادم يدويًا:
flutter run --dart-define=API_BASE=http://192.168.1.10:3000/api
```

## 4) الاختبارات
```bash
# Backend
cd services/api
npx jest src --runInBand                                   # وحدات (بوابة العمر)
npx jest --config ./test/jest-e2e.json --runInBand         # e2e مقابل Postgres حقيقي
# Flutter
cd apps/mobile
flutter analyze
flutter test
```

## 5) بناء النسخ
```bash
# Android APK (debug)
cd apps/mobile && flutter build apk --debug
# → build/app/outputs/flutter-apk/app-debug.apk
# Windows (يتطلب جهاز/CI ويندوز — المضيف Linux لا يبنيه):
flutter build windows --release
```

## ملاحظات بيئة
- بناء Windows يتم عبر GitHub Actions (`.github/workflows/ci-flutter.yml`, job `windows`) لأن التطوير هنا على Linux.
- في هذه البيئة السحابية جرى تثبيت Flutter وAndroid SDK وتشغيل Postgres عبر Docker وبناء APK فعلي.
