# ARCHITECTURE — البنية التقنية (تخطيطي)

المرجع التفصيلي: الأقسام 22–23 و12 (د) من [`PROJECT_MASTER_PLAN.md`](PROJECT_MASTER_PLAN.md).

## المكونات
- تطبيقا Android وiOS (أو إطار موحد — قرار لاحق في MVP-A) + لوحة إدارة ويب + موقع تعريفي.
- Backend موحد بخدمات: api، realtime، streaming، billing، payments، moderation، notifications، identity (انظر بنية `/services`).

## مبادئ معمارية ملزمة
1. قاعدة البيانات المالية هي المصدر الوحيد للحقيقة؛ Double-Entry Ledger append-only؛ Redis للأقفال القصيرة والتنسيق فقط (قسم 12-د).
2. خدمة الفوترة مستقلة قابلة للاختبار، Heartbeat رباعي (عميل ↔ Backend ↔ RTC ↔ فوترة)، والإنهاء قرار خادم دائمًا.
3. نظام الدفع Storefront-Aware وRegion-Aware عبر Feature Flags (قسم 12-أ).
4. فصل وثائق الهوية عن الأنظمة العامة؛ Tokens فقط (قسم 6).
5. لا رصيد سالب بنيويًا؛ Idempotency لكل عملية مالية؛ Fail-Safe عند تعطل التنسيق.
6. جميع الأوقات UTC + ISO 8601 + IANA TZ (قسم 19).

## نموذج البيانات
انظر القسم 23 من الخطة الأم (الجداول الأصلية + إضافات v1.1/v1.2). الأسماء تخطيطية وليست مخططًا نهائيًا.

## معايير القبول
`docs/ARCHITECTURE_ACCEPTANCE_CRITERIA.md` — لا يُعتبر التصميم مقبولًا قبل اجتيازها بأدلة.
