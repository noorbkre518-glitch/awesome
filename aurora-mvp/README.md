# Aurora — Social Discovery MVP (Working Codename)

**الاسم المؤقت:** Aurora — اسم عمل مؤقت وليس علامة تجارية نهائية.

تطبيق تعارف اجتماعي للبالغين (18+): تسجيل، ملف شخصي، اكتشاف، إعجاب/مطابقة، محادثات، حظر وإبلاغ. هذا المستودع يحتوي **النواة القابلة للتشغيل (MVP)**: خادم NestSJ + Prisma + PostgreSQL، وتطبيق Flutter (Android + Windows).

> **حدود المحتوى:** المحتوى الجنسي الصريح والخدمات الجنسية ممنوعة — راجع `CONTENT_POLICY.md`.
> الميزات المتقدمة (البث المباشر، الدفع، الهدايا) موثّقة في `PROJECT_MASTER_PLAN.md` لكنها **خارج نطاق هذا الـ MVP**.

## بنية المشروع (monorepo)

```
services/api/        خادم NestJS (modular monolith) + Prisma + PostgreSQL
apps/mobile/         تطبيق Flutter (Android + Windows)
infrastructure/      docker-compose للتطوير (PostgreSQL)
docs/                سجلات القرارات، التحقق المحلي، القوالب
packages/, services/*  بنية مستقبلية (README فقط)  — خارج نطاق MVP
```

## المتطلبات

Node.js 22 · PostgreSQL 16 · Flutter 3.44 (Dart 3.12) · JDK 21 · Android SDK 36 (لبناء APK).

## 1) تشغيل PostgreSQL

عبر Docker Compose (مستحسن):

```bash
docker compose -f infrastructure/docker-compose.dev.yml up -d
```

أو باستخدام PostgreSQL محلي: أنشئ مستخدمًا `aurora`/`aurora` وقاعدة `aurora`.

## 2) تشغيل الـ Backend

```bash
cd services/api
cp .env.example .env            # عدّل القيم؛ لا تضع أسرارًا حقيقية في المستودع
npm ci
npx prisma generate
npx prisma migrate deploy       # يطبّق المهاجرات على PostgreSQL
npm run build
npm run start:prod              # أو: npm run start:dev
# صحة الخدمة:
curl http://localhost:3000/api/health   # -> {"status":"ok","db":"up",...}
```

## 3) تشغيل تطبيق Flutter

```bash
cd apps/mobile
flutter pub get
flutter run                     # على جهاز/محاكي متصل
```

### تحديد عنوان الـ API

العنوان قابل للتغيير عبر `--dart-define=API_BASE=...` (بدون أي قيمة سرية):

| الهدف | العنوان |
|---|---|
| محاكي Android | `http://10.0.2.2:3000/api` (الافتراضي على Android) |
| هاتف Android حقيقي على نفس الشبكة | `http://<عنوان-الكمبيوتر-على-LAN>:3000/api` (مثال `http://192.168.1.20:3000/api`) |
| سطح المكتب / الويب | `http://localhost:3000/api` (الافتراضي) |
| الإنتاج | `https://api.yourdomain.com/api` (HTTPS إلزامي) |

مثال لهاتف حقيقي:

```bash
flutter run --dart-define=API_BASE=http://192.168.1.20:3000/api
```

> **الشبكة على Android:** نسخة Debug تسمح باتصال HTTP المحلي فقط (network-security-config خاص بالـ debug)؛
> نسخة Release **لا تسمح** بالـ cleartext وتتطلب HTTPS. تأكد أن الخادم يستمع على `0.0.0.0` وأن جدار الحماية يسمح بالمنفذ 3000 لاختبار الهاتف الحقيقي.

## الاختبارات

```bash
# Backend (يتطلب PostgreSQL يعمل):
cd services/api
npx jest src --runInBand                                   # unit
npx jest --config ./test/jest-e2e.json --runInBand         # e2e (أساسي + MVP-A + أمان)

# Flutter:
cd apps/mobile
flutter analyze
flutter test
```

## الأمان والجلسات (باختصار)

- كل طلب محمي يُعاد فيه التحقق من حالة المستخدم في قاعدة البيانات (موجود، غير محذوف، غير موقوف، إصدار التوكن مطابق) — توقيع JWT صحيح وحده لا يكفي.
- تسجيل الخروج وحذف الحساب يرفعان `tokenVersion` فيُبطلان التوكن **فورًا** (وليس بعد 15 دقيقة).
- تفاصيل كاملة في [`FINAL_MVP_REPORT.md`](FINAL_MVP_REPORT.md).

## التوثيق

- [`FINAL_MVP_REPORT.md`](FINAL_MVP_REPORT.md) — تقرير الـ MVP النهائي (ما أُصلح، الأمان، النتائج الفعلية، البصمات).
- [`HANDOFF.md`](HANDOFF.md) — تسليم عملي سريع.
- [`docs/LOCAL_RUNTIME_VERIFICATION.md`](docs/LOCAL_RUNTIME_VERIFICATION.md) — نتائج التشغيل والتحقق المحلي.
- [`PROJECT_MASTER_PLAN.md`](PROJECT_MASTER_PLAN.md) — الخطة الأم الكاملة (المرجع الشامل، يتجاوز نطاق الـ MVP).
