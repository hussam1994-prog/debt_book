<div align="center">

# 📒 دفتر الديون — Debt Book

**تطبيق Flutter لإدارة الديون الشخصية — Offline-First بمزامنة موثوقة ومعايير 2026**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Drift](https://img.shields.io/badge/Drift-2.35-4A90E2)](https://drift.simonbinder.eu)
[![Supabase](https://img.shields.io/badge/Supabase-2.x-3ECF8E?logo=supabase)](https://supabase.com)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

</div>

---

## 🎯 نظرة عامة

**دفتر الديون** تطبيق شخصي لإدارة الديون والعملات بين الأفراد، مبني بـ Flutter و Drift (SQLite محلي) و Supabase (سحابي). يتبع فلسفة **Offline-First** — يعمل بالكامل بدون إنترنت، ثم يزامن سحابياً عند توفّر الاتصال.

## ✨ الميزات

### 🔐 الأمان والمصادقة
- تسجيل دخول عبر **Google Sign-In** + بريد/كلمة مرور
- **PIN** للدخول السريع (flutter_secure_storage)
- **RLS Policies** على جميع الجداول السحابية
- **FLAG_SECURE** على Android (منع لقطات الشاشة)
- **Supabase Vault** لتخزين Service Role Key

### 💾 البيانات
- **Offline-First** مع **Outbox Pattern** كامل
- **دفتر أستاذ Append-Only** — لا حذف/تحديث، التصحيح بقيد عكسي
- **رصيد اشتقاقي** يُحسب من القيود (لا يُخزّن)
- **Conflict Resolution** عبر `client_id` + Idempotency
- **Batch Processing** مع **Deduplication**
- **Exponential Backoff + Jitter** عند الفشل

### ☁️ المزامنة
- **Delta Sync** (جلب التغييرات فقط)
- **Realtime Subscriptions** لجميع الجداول
- **Background Sync** (workmanager)
- **Connection Awareness** (توقف عند Offline، مزامنة فورية عند العودة)
- **Sync Dashboard** (إحصائيات + إعادة محاولة)

### 🔔 الإشعارات
- **FCM Push Notifications** (6 أنواع)
- **Local Notifications** (تذكيرات الاستحقاق + الملخص الأسبوعي)
- **أزرار تفاعلية** على الإشعارات (واتساب، عرض، تم)
- **Quiet Hours** (ساعات الهدوء)
- **قنوات منفصلة** لكل نوع

### 🎨 الواجهة
- **Material 3** (فاتح + داكن)
- **دعم عربي/إنجليزي** كامل (RTL/LTR)
- **Onboarding** بـ 7 شرائح
- **Skeleton Loading** + **Hero Animations** + **AnimatedListItem**
- **Tags ملونة** للأشخاص (8 ألوان)

### 📊 الميزات الوظيفية
- إدارة الأشخاص (CRUD + Soft Delete + بحث صوتي)
- إدارة الديون (إنشاء/دفعات/تسويات/عكس/إلغاء)
- **التقسيط** (CreateInstallments + MarkInstallmentsPaid)
- **دفتر أستاذ** Timeline رأسي
- **إحصائيات شهرية** (Bar Chart + Top 5 Debtors)
- **تقارير** PDF + Excel + CSV + واتساب
- **رؤى ذكية** (SmartInsightsService)
- **بحث صوتي** (عربي + إنجليزي)
- **نسخ احتياطي** محلي + سحابي

---

## 🏗️ البنية المعمارية

المشروع **Monorepo** يتبع **Clean Architecture**:

```
debt_book/
├── apps/mobile/          ← تطبيق Flutter
├── packages/domain/      ← منطق أعمال نقي
├── docs/                 ← التوثيق
└── scripts/              ← أدوات
```

### الطبقات (Layers)

```
┌──────────────────────────────────────────────┐
│  features/     ← UI + Providers              │
├──────────────────────────────────────────────┤
│  data/         ← Repositories + Mappers      │
├──────────────────────────────────────────────┤
│  core/         ← DB + Cloud + Notifications  │
├──────────────────────────────────────────────┤
│  domain/       ← Pure Business Logic         │
│                  (No Flutter deps)           │
└──────────────────────────────────────────────┘
```

### التقنيات المستخدمة

| الطبقة | التقنية |
|--------|---------|
| UI | Flutter + Material 3 |
| State | Riverpod 2.x |
| Routing | GoRouter 14.x |
| Local DB | Drift 2.35 (SQLite) |
| Cloud | Supabase (PostgreSQL + Auth + Realtime) |
| Push | Firebase Cloud Messaging |
| Local Notif | flutter_local_notifications 17.x |
| Background | Workmanager 0.10.10 |
| Voice | speech_to_text 7.x |
| Reports | pdf 3.x + excel 4.x |

---

## 📦 التثبيت والتشغيل

### المتطلبات
- Flutter **3.44+**
- Dart **3.13+**
- Android SDK / Xcode
- حساب Supabase

### الخطوات

```bash
# 1) استنساخ
git clone <repo-url>
cd debt_book

# 2) تثبيت اعتماديات domain
cd packages/domain && flutter pub get && cd ../..

# 3) تثبيت اعتماديات التطبيق
cd apps/mobile && flutter pub get

# 4) تهيئة Supabase في lib/core/cloud/supabase_config.dart

# 5) تهيئة Firebase (للإشعارات)
#    أضف google-services.json إلى android/app/
#    أو استخدم: flutterfire configure

# 6) توليد كود Drift
dart run build_runner build

# 7) تشغيل
flutter run
```

---

## 🧪 الاختبارات

```bash
# اختبارات domain (32 اختبار)
cd packages/domain
flutter test

# اختبارات integration + widget (6 اختبارات)
cd apps/mobile
flutter test

# تشغيل الكل
cd ~/Desktop/debt_book
(cd packages/domain && flutter test) && (cd apps/mobile && flutter test)
```

**التغطية الحالية:**
- ✅ 32 اختبار domain (Money, BalanceCalculator, LedgerIntegrityChecker, UseCases)
- ✅ 6 اختبار integration + widget

---

## 📚 التوثيق

- [docs/README.md](docs/README.md) — فهرس شامل
- [docs/architecture.md](docs/architecture.md) — معمارية مفصّلة
- [docs/testing.md](docs/testing.md) — دليل الاختبارات
- [docs/deployment.md](docs/deployment.md) — النشر على Google Play
- [docs/adr/](docs/adr/) — قرارات معمارية

---

## 🔄 دورة التطوير

```bash
# توليد كود Drift
dart run build_runner build

# توليد l10n
flutter gen-l10n

# تحليل
flutter analyze

# اختبار
flutter test

# بناء release
flutter build appbundle --release
```

---

## 🤝 المساهمة

اقرأ [CONTRIBUTING.md](CONTRIBUTING.md) قبل إرسال Pull Request.

**قواعد أساسية:**
- ✅ كل تعديل = اختبار + توثيق
- ✅ احترم Clean Architecture (domain نقي)
- ✅ لا مكتبات جديدة دون تبرير
- ✅ كل قرار معماري = ADR

---

## 📄 الرخصة

MIT — راجع [LICENSE](LICENSE)

---

## 👤 المؤلف

**Debt Book Team** — 2026

<div align="center">

**⭐ إذا أعجبك المشروع، لا تنسَ النجمة! ⭐**

</div>

