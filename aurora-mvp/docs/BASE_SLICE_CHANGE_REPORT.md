# تقرير مرحلة الشريحة الأساس — base-slice

**الفرع:** `feature/base-slice-foundation` · **التاريخ:** 2026-07-23 · **الحالة:** منفّذ ومختبَر محليًا.

## النطاق المنفَّذ (وفق الموافقة)
نسخة اجتماعية أساسية قابلة للتشغيل: تسجيل/دخول، بوابة عمر 18+، ملف شخصي (عرض/تحرير)، حظر، إبلاغ، حذف حساب، لوحة بلاغات للمشرف، فحص صحة.
**مُستبعَد عمدًا:** الدفع، Coins، الأرباح، اللايف الخاص، البث، الاستكشاف/المطابقة/المحادثة (الأخيرة للمرحلة 2).

## الملفات المُعدَّلة (وثائق — بموافقتك على النص)
| الملف | التغيير | السبب |
|---|---|---|
| `PROJECT_MASTER_PLAN.md` | القسم 2: إضافة سطر تطبيق Windows/Microsoft Store | إضافة Windows للنطاق (D-005) |
| `ROADMAP.md` | صف «منصات الهدف» | توثيق النطاق v1.2.1 |
| `docs/DECISION_LOG.md` | D-005 (Windows)، D-006 (حزمة التقنية) | حوكمة القرارات (قسم 41) |
| `CHANGELOG.md` | إدخال v1.2.1 | سجل التغييرات |
| `.gitignore` | تجاهل node_modules/dist/build/gradle caches/.env | منع رفع المولّدات والأسرار |
| `apps/mobile/README.md` | استبدله Flutter بوصفه الافتراضي | إنشاء مشروع Flutter (README التخطيطي حُفظ في apps/mobile/docs/PLANNING_README.md) |

## الملفات المُنشأة — الخادم (`services/api`)
| الملف | الوظيفة |
|---|---|
| `prisma/schema.prisma` | نماذج User/Profile/Session/Block/Report + Enums |
| `src/main.ts`, `src/app.module.ts` | إقلاع، بادئة /api، ValidationPipe، CORS |
| `src/common/age.ts` (+ `.spec.ts`) | بوابة العمر 18+ (مصدر وحيد) + 5 اختبارات وحدة |
| `src/auth/*` | register/login (Argon2 + JWT)، JwtGuard، DTOs، بوابة عمر خادمية |
| `src/users/*` | حذف الحساب (معاملة ذرّية + إلغاء الجلسات)، حظر، إبلاغ |
| `src/profiles/*` | قراءة/تحديث الملف الشخصي |
| `src/moderation/*` | قائمة/تحديث البلاغات (ADMIN/MODERATOR فقط) |
| `src/health/*` | فحص صحة + اتصال DB |
| `src/prisma/*` | PrismaService/Module |
| `test/app.e2e-spec.ts` | 10 اختبارات e2e (HTTP حقيقي + Postgres) |
| `package.json`, `tsconfig.json`, `nest-cli.json`, `jest.config.js`, `.env.example` | تهيئة |

## الملفات المُنشأة — العميل (`apps/mobile`)
| الملف | الوظيفة |
|---|---|
| `lib/main.dart` | جذر التطبيق + الثيم الداكن |
| `lib/src/api/api_client.dart` | عميل REST (base URL حسب المنصة: Android 10.0.2.2، غيره localhost) |
| `lib/src/screens/login_screen.dart` | شاشة الدخول |
| `lib/src/screens/register_screen.dart` | التسجيل + بوابة عمر 18+ (منتقي تاريخ + تأكيد) |
| `lib/src/screens/profile_screen.dart` | عرض/تحرير الملف + خروج + حذف حساب مؤكَّد |
| `test/widget_test.dart` | اختبارا widget (عرض الدخول + بوابة العمر) |
| `pubspec.yaml` | + حزمة http |
| `android/settings.gradle.kts`, `gradle-wrapper.properties` | AGP 8.7.3 + Kotlin 2.1.0 + Gradle 8.14.3 (لملاءمة البيئة) |

## البنية التحتية والـ CI
| الملف | الوظيفة |
|---|---|
| `infrastructure/docker-compose.dev.yml` | Postgres 16 للتطوير |
| `.github/workflows/ci-api.yml` | Node 22 + Postgres service → unit + e2e |
| `.github/workflows/ci-flutter.yml` | Android (APK) على ubuntu + Windows build على windows-latest |
| `docs/RUNBOOK_LOCAL_DEV.md` | أوامر التشغيل الدقيقة |

## نتائج الاختبارات (أدلة تنفيذية حقيقية)
- **وحدات الخادم:** `5 passed` (بوابة العمر — قبل/بعد الميلاد، رفض 17، قبول 18 اليوم).
- **e2e الخادم:** `10 passed` مقابل Postgres حقيقي: health، رفض <18، تسجيل بالغ، رفض تكرار البريد، دخول صحيح، رفض كلمة خاطئة، منع وصول غير مصادق، قراءة/تحديث الملف، إبلاغ + حظر، حذف حساب + إبطال الدخول.
- **Flutter:** `flutter analyze` = No issues found؛ `flutter test` = 2 passed.
- **APK:** `flutter build apk --debug` نجح — `app-debug.apk` (~140MB) SHA-256 مُسلَّم.

## قيود بيئية حقيقية (بلا تجميل)
1. **بناء Windows:** مستحيل محليًا (المضيف Linux) — يتم عبر CI job `windows-latest`. غير مُنجَز هنا.
2. **Gradle 9.1.0:** تنزيله محجوب بسياسة البروكسي (403 على github.com)؛ استُخدم Gradle 8.14.3 المثبّت محليًا مع AGP 8.7.3 (تبعيات AGP من google()/mavenCentral المسموحين). هذا سبب تثبيت إصدارات AGP/Gradle الأقل.
3. **Docker daemon** لا يبقى حيًّا بين استدعاءات الأوامر في هذه البيئة؛ أُعيد تشغيله عند الحاجة، وPostgres قابل للتشغيل عبر compose أو نسخة أصلية.

## معايير النجاح (مُحقَّقة)
✅ تشغيل محلي موثّق · ✅ اختبارات خضراء بأدلة · ✅ APK مبني ومُسلَّم · ✅ لا أسرار في الشجرة · ✅ لا دفع/بث/لايف · ✅ لا عمل على main.
