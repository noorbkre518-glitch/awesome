# تقرير مرحلة MVP-A — الشريحة الاجتماعية

**الفرع:** `feature/mvp-a-social` (منشعب من `feature/base-slice-foundation`) · **التاريخ:** 2026-07-23 · **الحالة:** منفّذ ومختبَر محليًا.

## النطاق المنفَّذ
فوق الشريحة الأساس: **الاستكشاف (Discovery)** واعٍ بالحظر، **Like / Super Like** مع **إنشاء Match تلقائيًا عند التبادل**، **المحادثة النصية** داخل المطابقة (تحقق العضوية + تعطيل عند وجود حظر). لا دفع/Coins/بث/لايف خاص.

## الملفات المُنشأة — الخادم (`services/api/src`)
| المجلد | الوظيفة |
|---|---|
| `discovery/` | `GET /api/discovery` — مرشحون يستثنون: النفس، المحذوفين، المحظورين (الاتجاهين)، ومن سبق الإعجاب بهم |
| `interactions/` | `POST /api/interactions/like` (LIKE/SUPER_LIKE) → Match عند التبادل (زوج مرتّب لضمان التفرد)؛ `GET /api/interactions/matches` |
| `messaging/` | `POST /api/messaging/send` و`GET /api/messaging/:matchId` — بفحص العضوية والحظر |

## الملفات المُنشأة — العميل (`apps/mobile/lib/src/screens`)
`home_screen.dart` (تبويبات: اكتشاف/مطابقات/ملفي)، `discover_screen.dart` (بطاقات + إعجاب/Super)، `matches_screen.dart` (قائمة → محادثة)، `chat_screen.dart` (فقاعات + إرسال). وسّعت `api_client.dart` بخمس دوال جديدة، وربطت الدخول/التسجيل بـ HomeScreen.

## المُعدَّل
`prisma/schema.prisma` (+Like/Match/Message + علاقات User)، `app.module.ts` (تسجيل 3 وحدات)، `docs/RUNBOOK_LOCAL_DEV.md` (5 مسارات جديدة)، `CHANGELOG.md` (v1.2.2)، `profile_screen.dart` (وضع embedded).

## الأدلة التنفيذية الحقيقية
- **الوحدات: 5/5 خضراء.**
- **e2e: 19/19 خضراء** (10 أساس + **9 MVP-A**) مقابل Postgres حقيقي: الاستكشاف يستثني النفس/المُعجَب بهم، A→B لا مطابقة، B→A مطابقة، الطرفان يريان المطابقة، تبادل رسائل بترتيب صحيح مع علم `mine`، غير المشارك C يُمنع (403)، الحظر يعطّل المراسلة (403)، منع الإعجاب بالنفس (400).
- **Flutter:** `analyze` = No issues found؛ `test` = 2/2 خضراء.
- **APK release مقسّم مبني** (arm64/v7a) — يُسلَّم.

## القيود (نفسها)
بناء Windows عبر CI فقط (مضيف Linux)؛ Gradle 8.14.3 محلي؛ Docker daemon يُعاد تشغيله عند الحاجة. لا دفع إلى GitHub (المستودع غير منشأ — 403).

## معايير النجاح (مُحقَّقة)
✅ ميزات اجتماعية تعمل طرفًا لطرف · ✅ 24 اختبارًا أخضر بأدلة · ✅ منطق الحظر مفروض في الاكتشاف والإعجاب والمراسلة · ✅ APK مبني · ✅ لا أسرار · ✅ لا نطاق مؤجَّل · ✅ فرع مستقل، لا عمل على main.
