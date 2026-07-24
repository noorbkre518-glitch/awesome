# CHANGELOG

## v1.3.0 — 2026-07-24 — MVP PRODUCTION READINESS
- أمان وجلسات (P0): الحارس يعيد التحقق من حالة الحساب في DB لكل طلب محمي؛ `tokenVersion` يُبطل التوكن فورًا عند تسجيل الخروج وحذف الحساب؛ إيقاف المستخدم (`isSuspended`)؛ حذف جدول Session غير المستخدم؛ دمج البلاغات المكررة؛ Rate limiting؛ CORS قابل للضبط؛ فرض `JWT_SECRET` في الإنتاج؛ رفع `qs` لإغلاق تحذير DoS.
- واجهة Flutter (P1): حظر/إبلاغ من الواجهة (اكتشاف + محادثة)؛ تسجيل خروج حقيقي؛ معالجة 401 عامة (العودة للدخول)؛ حالات تحميل/فراغ/خطأ/شبكة.
- Android (P4): إزالة cleartext العام؛ network-security-config (Release: HTTPS فقط، Debug: HTTP محلي).
- CI: إصلاح `docs-quality.yml` (إزالة بوابة "لا كود تطبيق")؛ `prisma validate` + build في `ci-api.yml`.
- اختبارات: Backend **5 وحدة + 26 e2e** (منها 7 أمان)؛ Flutter **13** (analyze نظيف)؛ APK debug+release (arm64) مبنيان ومُتحقَّق من إعداد cleartext فيهما. فرع `finish/mvp-production-readiness`. التفصيل: `FINAL_MVP_REPORT.md`.

## v1.2.2 — 2026-07-23 — MVP-A SOCIAL SLICE
- إضافة الاستكشاف (Discovery) الواعي بالحظر، وLike/Super Like مع إنشاء Match عند التبادل، والمحادثة النصية داخل المطابقة (تحقق العضوية + تعطيل عند الحظر).
- جداول Prisma: Like/Match/Message. شاشات Flutter: Home/Discover/Matches/Chat.
- اختبارات: 24 خضراء (5 وحدة + 19 e2e مقابل Postgres حقيقي). فرع feature/mvp-a-social.


## v1.2.1 — 2026-07-23 — SCOPE + FOUNDATION
- إضافة Windows/Microsoft Store رسميًا لنطاق المشروع (D-005) — القسم 2 وROADMAP.
- اعتماد حزمة التقنية Flutter + NestJS + PostgreSQL + Prisma (D-006).
- بدء فرع feature/base-slice-foundation: الشريحة الأساس (خادم + عميل قابلان للتشغيل، دون دفع/بث/لايف خاص).

## v1.2 — 2026-07-23 — FINAL PLANNING BASELINE
- تأسيس المستودع الدائم للمشروع (planning only — لا كود تطبيق).
- PROJECT_MASTER_PLAN.md v1.2: الأقسام الأصلية 1–34 كاملة + إضافات v1.1 المعتمدة + إضافات v1.2 + الأقسام الجديدة 35–41 (وصول، حقوق، تشغيل، متاجر، مزودون، MVP، حوكمة).
- استبدال صيغة حماية القاصرين في القسم 10 بالصيغة الكاملة بقرار صاحب المشروع.
- إضافة وثائق الجذر الموضوعية وقوالب docs/ وسجلات القرارات والمخاطر.
- التفصيل: docs/CHANGELOG_v1.2.md.

## v1.1 — 2026-07-23 — VERIFIED CORRECTIONS
- تصحيحات المراجعة الخارجية المعتمدة (دفع، فوترة، نزاعات، التفاف، حظر، تسريب، بيانات، مناطق زمنية، خطر المتاجر). التفصيل: docs/CHANGELOG_v1.2.md (القسم v1.1).

## v1.0
- الخطة الأم الأصلية (34 قسمًا) من صاحب المشروع.
