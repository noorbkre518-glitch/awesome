# PAYMENTS AND BILLING — الدفع والفوترة (تخطيطي)

المرجع: الأقسام 12 (كامل الإضافات)، 13، 14 من [`PROJECT_MASTER_PLAN.md`](PROJECT_MASTER_PLAN.md).

## Payment Compliance Matrix
قرار دفع لكل (نظام × متجر × دولة المستخدم × دولة المنشئ × نوع معاملة) — لا تعميم. القالب: docs/PAYMENT_COMPLIANCE_MATRIX_TEMPLATE.md. التحكم عبر Feature Flags إقليمية.

## أنواع المعاملات
- A مشتريات رقمية عامة (Coins، هدايا، Boosts، اشتراكات، تذاكر، بث جماعي): StoreKit/Play Billing حيثما تفرضه سياسة المتجر.
- B جلسة 1:1 حقيقية: قد تؤهل كخدمة Person-to-Person في بعض المتاجر — قرار منفصل لكل متجر ودولة، لا افتراض تلقائي.
- C ويب: مزود مباشر/Marketplace مرخّص، فصل كامل عن الهاتف، لا CTA خارجية في أماكن ممنوعة.

## محرك الفوترة بالوقت
DB المالية Source of Truth؛ Ledger مزدوج القيد؛ حجز مسبق متدحرج؛ Billing Slice قابلة للضبط (15/30/60 ث)؛ Atomic Transactions؛ Idempotency لكل Slice؛ Heartbeat رباعي؛ نفاد الرصيد ⇒ إنهاء من الخادم وterminating؛ لا رصيد سالب؛ Fail-Safe عند تعطل Redis؛ رد المحجوز غير المستخدم.

## النزاعات والأرباح
State Machine ذات 17 حالة + Metadata محدودة (لا تسجيل جلسات) + Fraud Risk (قسم 12-هـ/و). أرباح المنشئين: Pending Creator Earnings / Settlement Reserve (ليست Escrow قبل موافقة قانونية)؛ مزود Marketplace مرخّص لKYC/Payouts/ضرائب/Reserves؛ مراجعة E-Money/Money Transmission لكل دولة. Coins: Closed-loop (قسم 14).
