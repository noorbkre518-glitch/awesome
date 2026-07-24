# Local Runtime Verification — تقرير التشغيل والتحقق المحلي

**الفرع:** `finish/mvp-production-readiness` · **التاريخ:** 2026-07-24 · **الحالة:** ✅ PASS

نُفِّذت السلسلة كاملة فعليًا في هذه البيئة (لا اعتماد على تقارير سابقة):
`PostgreSQL → Prisma migrate → NestJS API → curl full flow`، و`Flutter analyze + test + build APK`.

## الأدوات والإصدارات (مُتحقَّق منها الآن)
Node v22.22.2 · npm 10.9.7 · PostgreSQL 16.13 · Java (JDK) 21 · Gradle 8.14.3 · Flutter 3.44.8 (stable) · Dart 3.12.2 · Android SDK: platforms 34/35/36، build-tools 34/35/36، NDK 28.2، CMake 3.22.1.

## Backend
- `npx prisma validate` → صالح · drift check (`migrate diff`) → **No difference** بين المهاجرات والمخطط.
- `npx prisma migrate deploy` → 3 مهاجرات مطبّقة (init + mvp_a_social + auth_session_hardening).
- `npm run build` (nest build) → **exit 0**.
- `npx jest src --runInBand` → **5/5 PASS** (بوابة العمر 18+).
- `npx jest --config ./test/jest-e2e.json --runInBand` → **26/26 PASS**:
  - `app.e2e-spec.ts` (10) · `mvp-a.e2e-spec.ts` (9) · `security.e2e-spec.ts` (7).
- الخادم الحي: `node dist/src/main.js` → أقلع على `:3000`.
- `GET http://localhost:3000/api/health` → **HTTP 200** `{"status":"ok","db":"up"}`.

## السيناريو الوظيفي الكامل (عبر الـ API الحي بـ curl — كله ✅)
1) تسجيل بالغ · 2) رفض قاصر <18 (**400**) · 3) تعديل الملف (**200**) · 4) الاكتشاف يُظهر الطرف الآخر · 5) إعجاب (لا مطابقة) · 6) إعجاب متبادل ⇒ **Match** · 7) محادثة: إرسال الطرفين (**201**) والخيط يعرض `mine` صحيحًا · 8) **إبلاغ** (201) ثم **حظر** (201) ⇒ الإرسال بعد الحظر **403** · 9) **تسجيل خروج** ⇒ التوكن القديم **401** · 10) إعادة دخول ⇒ توكن جديد **200** · 11) **حذف الحساب** ⇒ التوكن يفشل **فورًا 401**، وإعادة الدخول بعد الحذف **401**.

## اختبارات الأمان (security.e2e-spec.ts)
- التوكن يعمل قبل الحذف ويفشل فورًا بعده (profiles/discovery/matches كلها 401).
- تسجيل الخروج يُبطل الجلسة؛ إعادة الدخول تُصدر توكنًا صالحًا.
- المستخدم الموقوف: محجوب عن كل endpoint محمي، لا يستطيع المراسلة، ولا يسجّل الدخول؛ والطرف النشط لا يستطيع مراسلته (403).
- الإيقاف عبر الإشراف (تحديد بلاغ إلى ACTIONED) من طرف إلى طرف.
- دمج البلاغات المكررة (سجل واحد فقط).
- رفض التوكنات المزوّرة/غير الموقّعة (401).

## Flutter
- `flutter pub get` → OK.
- `flutter analyze` → **No issues found!**
- `flutter test` → **13/13 PASS**:
  - `api_client_test.dart` (7): تخزين التوكن، 401 يُفعّل onUnauthorized ويمسح التوكن، فشل الشبكة → ApiException، فك مطابقة، حظر/إبلاغ، تسجيل خروج محلي رغم خطأ الخادم، حذف الحساب.
  - `flows_test.dart` (4): دخول→الرئيسية، إعجاب→إشعار مطابقة، حظر يُزيل المرشح، تسجيل خروج→شاشة الدخول.
  - `widget_test.dart` (2): عرض شاشة الدخول، بوابة العمر في التسجيل.
- `flutter build apk --debug --split-per-abi` و`--release --split-per-abi` → **بُنيت بنجاح**.

## تحقّق إعداد شبكة Android (aapt2 على الـ APK المبني)
- Release: `network_security_config` → `cleartextTrafficPermitted=false` (HTTP مغلق). ✅
- Debug: `cleartextTrafficPermitted=true` (HTTP محلي مسموح). ✅
- صلاحية `INTERNET` موجودة في الاثنين. ✅

## مخرجات البناء (موجودة فعليًا في delivery/apks)
| الملف | الحجم (بايت) | SHA-256 |
|---|---|---|
| aurora-mvp-v1-arm64-v8a-debug.apk | 75,609,345 | `e4876fcc7a0ee477c13884327a508d6f825fc3f131082193c7d6ba3964c0f3e0` |
| aurora-mvp-v1-arm64-v8a-release.apk | 17,624,661 | `ae9a647ab9d2a0b2a9b6a32662d9ea9a7dd2aa6dffba4c69433182b84d30d4fe` |

> جميع نسخ APK موقّعة بمفتاح **Debug/اختباري** — ليست توقيع Google Play.

## قيود بيئية (لم أتمكن من التحقق منها هنا — بصدق)
1. **فتح التطبيق على محاكي/جهاز Android** — لا محاكي/شاشة/KVM؛ تم بناء APK والتحقق من منطق الشاشات عبر `flutter test` (تدفقات تشغّل الشاشات فعليًا مع عميل HTTP وهمي). **الاختبار النهائي على هاتف حقيقي ما زال مطلوبًا.**
2. **بناء/تشغيل Windows** — يتم عبر CI `windows-latest` (workflow جاهز).
3. **توقيع Release إنتاجي** — غير مُعدّ (لا أسرار).

## معيار الأمان
فحص أسرار على الملفات المتتبَّعة نظيف؛ لا `.env` حقيقي متتبَّع (فقط `.env.example`)؛ `git status` نظيف بعد الالتزامات.
