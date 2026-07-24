# SECURITY — الأمن (تخطيطي)

المرجع: الأقسام 24 و27 (إضافات v1.1) و12-ج من [`PROJECT_MASTER_PLAN.md`](PROJECT_MASTER_PLAN.md).

## الضوابط الملزمة
- تشفير أثناء النقل وأثناء التخزين؛ إدارة أسرار خارج المستودع (لا مفاتيح في GitHub — `.env.example` أسماء فقط).
- مصادقة ثنائية، حماية كلمات المرور، منع التخمين، حماية API، Rate limiting.
- RBAC وLeast Privilege؛ Audit Logs لكل إجراء إداري؛ تسجيل دخول الموظفين.
- اكتشاف الحسابات المخترقة، تنبيه جهاز جديد، جلسات قابلة للإلغاء.
- أمن الدفع: Server-side receipt verification، Webhook signatures، Idempotency، منع إعادة استخدام الإيصالات.
- سلسلة التوريد: فحص Dependencies، Secret Scanning، SAST، DAST.
- اختبار اختراق قبل الإطلاق؛ Incident Response (انظر OPERATIONS_AND_INCIDENT_RESPONSE.md).

## الإبلاغ عن ثغرة
في مرحلة التخطيط: افتح Issue خاصًا بعنوان يبدأ بـ [SECURITY] دون تفاصيل استغلال علنية، أو راسل صاحب المستودع مباشرة.
