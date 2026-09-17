# Changelog — Debt Book Mobile

جميع التغييرات المهمة في تطبيق الموبايل موثّقة هنا.

---

## [Unreleased]

### Added
- `notificationServiceProvider` مع `initialize()` تلقائي
- `FakeSyncService` لاختبارات Widget
- اختبارات Widget (people + person detail)

### Changed
- ترقية `drift` / `drift_dev` إلى 2.35.0
- ترقية `sqlite3` إلى 3.6.0
- `SyncService` يستقبل `logger` عبر provider
- `FCMService` / `NotificationService` يستخدمان `LoggingService`

### Fixed
- **FK في SQLite**: إضافة `PRAGMA foreign_keys = ON` في `NativeDatabase.setup`
- **DDL**: الآن يولّد `REFERENCES` تلقائياً
- `unreachable_switch_case` في `FCMService._buildActions`
- اختبارات rollback (FK enforcement)
- اختبارات Widget (Supabase + l10n)

### Removed
- 25 `debugPrint` مؤقتة من الملفات الحرجة

---

## [1.0.0] - 2026-XX-XX

### Added

#### المصادقة
- Google Sign-In
- بريد/كلمة مرور عبر Supabase
- PIN للدخول السريع

#### المزامنة
- Outbox Pattern + Debounce
- Realtime Subscriptions
- Background Sync (workmanager)
- Sync Dashboard

#### الإشعارات
- FCM Push (6 أنواع)
- Local Notifications
- أزرار تفاعلية
- Quiet Hours

#### الميزات الوظيفية
- إدارة الأشخاص + الديون
- التقسيط
- دفتر أستاذ Append-Only
- تقارير PDF/Excel/CSV
- بحث صوتي
- نسخ احتياطي (محلي + سحابي)

#### الاختبارات
- 32 اختبار domain
- 6 اختبار integration + widget
