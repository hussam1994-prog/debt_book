# Changelog

جميع التغييرات المهمة في هذا المشروع موثّقة هنا.

التنسيق يتبع [Keep a Changelog](https://keepachangelog.com/)،
والإصدارات تتبع [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

### Added
- تنظيف شامل لـ `debugPrint` (تم تحويلها إلى `LoggingService`)
- توثيق كامل: README + CHANGELOG + ADRs
- تفعيل Foreign Keys في SQLite (PRAGMA + REFERENCES)
- مزوّد موحّد `notificationServiceProvider` مع تهيئة تلقائية

### Changed
- ترقية `drift` و `drift_dev` إلى 2.35.0
- ترقية `sqlite3` إلى 3.6.0
- ترقية `analyzer` إلى 13.x
- `SyncService` يستقبل `LoggingService` عبر constructor
- `FCMService` و `NotificationService` يستخدمان `LoggingService`

### Fixed
- **FK Enforcement**: إصلاح جذري لمشكلة عدم فرض Foreign Keys
  - إضافة `PRAGMA foreign_keys = ON` في `NativeDatabase.setup`
  - إصلاح DDL لتوليد `REFERENCES` تلقائياً
- إصلاح `unreachable_switch_case` في `FCMService._buildActions`
- إصلاح import غير مستخدم في `notification_action_handler.dart`
- إصلاح اختبارات integration (rollback + FK)
- إصلاح اختبارات widget (Supabase + l10n)
- إزالة `debugPrint` من مسارات حرجة (كانت تسبب ضجيجاً)

### Removed
- حذف مجلد `-p` العرضي
- استبعاد `debt_book.sqlite` من git

---

## [1.0.0] - 2026-XX-XX

### Added
#### المصادقة والأمان
- Google Sign-In (Silent + Switch + Disconnect)
- بريد/كلمة مرور عبر Supabase Auth
- PIN للدخول السريع
- RLS Policies على جميع الجداول
- FLAG_SECURE على Android
- Safe Clear Data (نسخة + تحقق + Outbox)

#### المزامنة
- Outbox Pattern مع Debounce (2s)
- Batch Processing + Deduplication
- Delta Sync + Idempotency
- Realtime Subscriptions
- Background Sync (workmanager)
- Sync Dashboard

#### الإشعارات
- FCM Push (6 أنواع)
- Local Notifications (timezone)
- أزرار تفاعلية
- Quiet Hours
- ملخص أسبوعي

#### الميزات الوظيفية
- إدارة الأشخاص + Tags
- إدارة الديون + دفعات + تسويات
- التقسيط
- دفتر أستاذ Append-Only
- لوحة إحصائيات شهرية
- تقارير PDF/Excel/CSV/واتساب
- رؤى ذكية
- بحث صوتي (عربي/إنجليزي)
- نسخ احتياطي محلي + سحابي

#### الاختبارات
- 32 اختبار domain
- 6 اختبار integration + widget

### Tech Stack
- Flutter 3.44+, Dart 3.13+
- Drift 2.35, Supabase 2.x, Riverpod 2.x, GoRouter 14.x

---

## [0.1.0] - 2025-XX-XX

### Added
- الإعداد الأولي للمشروع
- هيكل monorepo
- نموذج domain أساسي