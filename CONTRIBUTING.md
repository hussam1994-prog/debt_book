# 🤝 دليل المساهمة في Debt Book

شكراً لاهتمامك بالمساهمة في **دفتر الديون**!

---

## 📋 قبل البدء

1. اقرأ [README.md](README.md)
2. اقرأ [docs/README.md](docs/README.md)
3. اقرأ [docs/adr/](docs/adr/)

---

## 🏗️ البنية
debt_book/
├── apps/mobile/ ← تطبيق Flutter
├── packages/domain/ ← منطق أعمال نقي
├── docs/ ← التوثيق
└── scripts/ ← أدوات

---

## 🔄 دورة التطوير

### 1. Fork & Clone

```bash
git clone https://github.com/YOUR_USERNAME/debt_book.git
cd debt_book

2. الإعداد
bash

cd packages/domain && flutter pub get && cd ../..
cd apps/mobile && flutter pub get
dart run build_runner build
flutter gen-l10n

3. أنشئ فرعاً
bash

git checkout -b feature/my-feature

4. اعمل على التعديل

القواعد الصارمة:
#	القاعدة
1	لا تُعد اختراع ما تم إنجازه
2	احترم Clean Architecture (Domain نقي)
3	Repositories تسجل في Outbox
4	Providers في providers.dart
5	Routes في router.dart
6	لا setState إلا للـ UI المحلي
7	كل ميزة = اختبار
8	لا مكتبات جديدة دون تبرير
9	كل قرار معماري = ADR
10	dartdoc للدوال المعقدة
5. الاختبارات
bash

cd packages/domain && flutter test
cd apps/mobile && flutter test
flutter analyze

6. Commit

اتبع Conventional Commits:
bash

git commit -m "feat: add multi-currency support"
git commit -m "fix: resolve FK enforcement"
git commit -m "docs: update README"
git commit -m "test: add PaymentRepository tests"

الأنواع: feat, fix, docs, test, refactor, chore.
7. Push & PR
bash

git push origin feature/my-feature

✅ معايير قبول PR

    ✅ جميع الاختبارات تنجح

    ✅ flutter analyze نظيف

    ✅ Clean Architecture

    ✅ اختبارات جديدة

    ✅ توثيق محدّث

    ✅ ADR جديد (إن لزم)

🐛 الإبلاغ عن الأخطاء

افتح Issue على GitHub مع:

    وصف المشكلة

    خطوات إعادة الإنتاج

    السلوك المتوقع

    السلوك الفعلي

    لقطة شاشة

    البيئة (Flutter version, Device, OS)

شكراً لمساهمتك! ❤️
text


**Ctrl+S** → أغلق.

---

### 📄 3. `docs/privacy/index.html`

```bash
cd ~/Desktop/debt_book
mkdir -p docs/privacy
code docs/privacy/index.html

الصق:
html

<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>سياسة الخصوصية — دفتر الديون</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Tahoma, sans-serif;
      max-width: 800px;
      margin: 0 auto;
      padding: 24px;
      line-height: 1.8;
      color: #333;
      background: #fafafa;
    }
    h1 { color: #1E88E5; border-bottom: 2px solid #1E88E5; padding-bottom: 12px; }
    h2 { color: #0D47A1; margin-top: 32px; }
    h3 { color: #1565C0; }
    a { color: #1E88E5; }
    .last-update { background: #e3f2fd; padding: 12px; border-right: 4px solid #1E88E5; margin: 20px 0; }
    ul { padding-right: 24px; }
    code { background: #f5f5f5; padding: 2px 6px; border-radius: 3px; font-family: 'Courier New', monospace; }
    footer { margin-top: 60px; padding-top: 20px; border-top: 1px solid #ddd; text-align: center; color: #666; font-size: 0.9em; }
  </style>
</head>
<body>

<h1>سياسة الخصوصية — دفتر الديون (Debt Book)</h1>

<div class="last-update">
  <strong>آخر تحديث:</strong> 17 سبتمبر 2026
</div>

<p>نحن في <strong>دفتر الديون</strong> نأخذ خصوصيتك على محمل الجد.</p>

<h2>1. البيانات التي نجمعها</h2>

<h3>1.1 البيانات التي تُدخلها بنفسك</h3>
<ul>
  <li>بيانات الأشخاص: الاسم، الهاتف، البريد، ملاحظات.</li>
  <li>بيانات الديون: المبالغ، التواريخ، الأوصاف.</li>
  <li>بيانات الدفعات: المبالغ، الطرق، الملاحظات.</li>
  <li>المرفقات: التي تضيفها يدوياً.</li>
</ul>

<h3>1.2 البيانات التي تُجمع تلقائياً</h3>
<ul>
  <li>بيانات الحساب: البريد ومعرّف المستخدم عند تسجيل الدخول.</li>
  <li>بيانات الجهاز: النوع، النظام، إصدار التطبيق.</li>
  <li>رموز الإشعارات (FCM Token).</li>
  <li>سجلات الأخطاء (بدون بياناتك الشخصية).</li>
</ul>

<h3>1.3 لا نجمع</h3>
<ul>
  <li>❌ جهات الاتصال</li>
  <li>❌ الرسائل النصية</li>
  <li>❌ الموقع الجغرافي</li>
  <li>❌ الصور (إلا التي ترفعها كمرفقات)</li>
</ul>

<h2>2. استخدام البيانات</h2>

<ul>
  <li>✅ تشغيل التطبيق</li>
  <li>✅ مزامنة بين الأجهزة</li>
  <li>✅ إرسال التنبيهات</li>
  <li>✅ النسخ الاحتياطي</li>
  <li>✅ إصلاح الأخطاء</li>
</ul>

<p><strong>لا نبيع بياناتك ولا نشاركها لأغراض تسويقية.</strong></p>

<h2>3. التخزين والحماية</h2>

<h3>3.1 محلي</h3>
<ul>
  <li>SQLite + Drift مع تشفير</li>
  <li>PIN اختياري</li>
  <li>FLAG_SECURE لمنع لقطات الشاشة</li>
</ul>

<h3>3.2 سحابي</h3>
<ul>
  <li>Supabase (PostgreSQL) مع تشفير كامل</li>
  <li>RLS على جميع الجداول</li>
  <li>HTTPS/TLS 1.3</li>
</ul>

<h2>4. حقوقك</h2>

<ul>
  <li>📖 الوصول لبياناتك</li>
  <li>✏️ التصحيح</li>
  <li>🗑️ الحذف النهائي</li>
  <li>📤 التصدير (PDF/Excel/CSV)</li>
  <li>🔕 إيقاف الإشعارات</li>
</ul>

<h2>5. الأطفال</h2>

<p>التطبيق غير موجّه للأطفال تحت 13 عاماً.</p>

<h2>6. التواصل</h2>

<p>📧 <a href="mailto:privacy@debtbook.app">privacy@debtbook.app</a></p>

<footer>
  <p>© 2026 Debt Book. جميع الحقوق محفوظة.</p>
</footer>

</body>
</html>