# PRIVACY ARCHITECTURE — بنية الخصوصية (تخطيطي)

المرجع: الأقسام 6، 11 (ج v1.2)، 12-هـ، 24 من [`PROJECT_MASTER_PLAN.md`](PROJECT_MASTER_PLAN.md).

## المبادئ
Data Minimization، Purpose Limitation، Retention Limits، فصل وثائق الهوية (Tokens فقط)، عدم بيع البيانات الشخصية.

## اللايف الخاص
لا مشاهدة بشرية روتينية؛ تدخل فقط بمسوغ (بلاغ/خطر/قاصر/طلب قانوني/عطل)؛ كل وصول إداري مسجل (من، لماذا، متى، ماذا رأى، ماذا فعل)؛ لا تسجيل افتراضي للجلسات؛ Metadata محدودة مشفرة للنزاعات بمدد احتفاظ.
لا يوصف النظام بأنه End-to-End Encrypted ما دامت المعالجة والتدخل الأمني على الخادم قائمين.

## النقل الدولي
Data Residency and Transfer Matrix (قسم 24-أ + docs/DATA_RESIDENCY_AND_TRANSFER_MATRIX_TEMPLATE.md): GDPR ينظّم النقل خارج EEA بآليات (Adequacy/SCCs/TIA) ولا يفرض توطينًا مطلقًا؛ السعودية وفق PDPL ولوائحه مع مختص محلي. DPA مع كل معالج + قائمة Subprocessors + DPIA حيث تنطبق.

## الحذف
مسار الحذف ذو 10 خطوات مع Tombstones ومنع عودة البيانات بعد Disaster Recovery (قسم 24-ب)، مع حق تنزيل نسخة من البيانات.
