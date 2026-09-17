# دفتر الديون (Debt Book)

تطبيق Flutter لإدارة الديون الشخصية مع مزامنة سحابية عبر Supabase.

## الميزات

- إدارة الأشخاص (إضافة/تعديل/حذف ناعم، بحث)
- إدارة الديون (إنشاء، دفعات، تسويات، إلغاء)
- خطة تقسيط متساوية
- دفتر أستاذ Append-Only
- تقارير CSV و PDF بدعم عربي
- مزامنة سحابية مع عزل مستخدمين (RLS)
- وضع Offline-first مع Outbox Pattern
- مصادقة Supabase (بريد + كلمة مرور)
- تذكيرات واتساب وإشعارات محلية
- قفل PIN + تشفير البيانات الحساسة
- دعم عربي/إنجليزي وثيم فاتح/داكن

## البنية المعمارية

- `packages/domain`: منطق الأعمال النقي (Entities, Usecases, Services)
- `apps/mobile`: تطبيق Flutter
  - `core/database`: قاعدة بيانات Drift (SQLite)
  - `core/cloud`: مزامنة Supabase + Outbox
  - `features`: واجهات وشاشات

## الإعداد

1. انسخ المستودع
2. شغّل `flutter pub get`
3. أنشئ مشروع Supabase وأضف المتغيرات في `core/cloud/supabase_config.dart`
4. نفّذ migrations في Supabase (أنشئ الجداول وأضف أعمدة `client_id`)
5. شغّل `flutter run`

## الاختبارات

- اختبارات الوحدة: `dart test` في `packages/domain`
- اختبارات التكامل: `flutter test` في `apps/mobile`