# 📱 Debt Book — تطبيق Flutter

تطبيق Flutter الرئيسي لمشروع **دفتر الديون**.

## 🏗️ البنية الداخلية
lib/
├── main.dart ← نقطة البداية
├── app/ ← التطبيق والتنقل
├── core/ ← الخدمات الأساسية
│ ├── auth/ ← Google Sign-In
│ ├── cloud/ ← Supabase + Outbox + Realtime
│ ├── database/ ← Drift + Repositories
│ ├── notifications/ ← FCM + Local + Actions
│ ├── export/ ← PDF + Excel + CSV
│ ├── backup/ ← محلي + سحابي
│ ├── security/ ← PIN + Encryption
│ ├── sync/ ← WorkManager
│ ├── voice/ ← Speech to Text
│ ├── whatsapp/ ← 6 قوالب
│ ├── observability/ ← Logging + Metrics
│ ├── theme/ ← AppColors + Spacing
│ ├── widgets/ ← مكونات مشتركة
│ └── providers.dart ← جميع المزودات
├── data/ ← Repositories + Mappers
├── features/ ← الشاشات
└── l10n/ ← الترجمات
text


## 🚀 التشغيل

```bash
# تثبيت
flutter pub get

# توليد كود Drift
dart run build_runner build

# توليد l10n
flutter gen-l10n

# تشغيل
flutter run

# تحليل
flutter analyze

# اختبارات
flutter test

🔧 الإعداد
1. Supabase

lib/core/cloud/supabase_config.dart:
dart

class SupabaseConfig {
  static const String url = 'https://YOUR_PROJECT.supabase.co';
  static const String anonKey = 'YOUR_ANON_KEY';
}

2. Firebase (للإشعارات)
bash

flutterfire configure

3. توقيع Android

android/key.properties:
properties

storePassword=xxx
keyPassword=xxx
keyAlias=upload
storeFile=../release-key.jks

🧪 الاختبارات
الملف	الوصف
test/full_workflow_test.dart	دورة كاملة
test/integration/outbox_and_balance_test.dart	Outbox + الرصيد
test/repositories/payment_repository_impl_test.dart	Rollback + FK
test/people_page_test.dart	Widget
test/person_detail_page_test.dart	Widget
📦 البناء
bash

# APK للتطوير
flutter build apk --debug

# App Bundle للإنتاج
flutter build appbundle --release

🎨 الثيم

    الألوان: lib/core/theme/app_colors.dart

    التباعد: lib/core/theme/app_design.dart

    الثيم الكامل: lib/core/theme/app_theme.dart

🔗 روابط

    التوثيق الكامل

    المعمارية

text


**احفظ (Ctrl+S).**

---

### 📋 الخيار البديل: نسخة بدون code fences

إذا لم يعمل VS Code، استخدم notepad مع هذه النسخة المبسطة (بدون ` ``` `):

```bash
cd ~/Desktop/debt_book/apps/mobile
rm README.md
notepad README.md

الصق:
text

# 📱 Debt Book — تطبيق Flutter

تطبيق Flutter الرئيسي لمشروع دفتر الديون.

## 🏗️ البنية الداخلية

lib/
  main.dart              ← نقطة البداية
  app/                   ← التطبيق والتنقل
  core/                  ← الخدمات الأساسية
    auth/                ← Google Sign-In
    cloud/               ← Supabase + Outbox + Realtime
    database/            ← Drift + Repositories
    notifications/       ← FCM + Local + Actions
    export/              ← PDF + Excel + CSV
    backup/              ← محلي + سحابي
    security/            ← PIN + Encryption
    sync/                ← WorkManager
    voice/               ← Speech to Text
    whatsapp/            ← 6 قوالب
    observability/       ← Logging + Metrics
    theme/               ← AppColors + Spacing
    widgets/             ← مكونات مشتركة
    providers.dart       ← جميع المزودات
  data/                  ← Repositories + Mappers
  features/              ← الشاشات
  l10n/                  ← الترجمات

## 🚀 التشغيل

  flutter pub get
  dart run build_runner build
  flutter gen-l10n
  flutter run
  flutter analyze
  flutter test

## 🔧 الإعداد

### 1. Supabase

في lib/core/cloud/supabase_config.dart:

  class SupabaseConfig {
    static const String url = 'https://YOUR_PROJECT.supabase.co';
    static const String anonKey = 'YOUR_ANON_KEY';
  }

### 2. Firebase

  flutterfire configure

### 3. توقيع Android

في android/key.properties:

  storePassword=xxx
  keyPassword=xxx
  keyAlias=upload
  storeFile=../release-key.jks

## 🧪 الاختبارات

- test/full_workflow_test.dart — دورة كاملة
- test/integration/outbox_and_balance_test.dart — Outbox + الرصيد
- test/repositories/payment_repository_impl_test.dart — Rollback + FK
- test/people_page_test.dart — Widget
- test/person_detail_page_test.dart — Widget

## 📦 البناء

  flutter build apk --debug
  flutter build appbundle --release

## 🎨 الثيم

- الألوان: lib/core/theme/app_colors.dart
- التباعد: lib/core/theme/app_design.dart
- الثيم الكامل: lib/core/theme/app_theme.dart

## 🔗 روابط

- التوثيق الكامل: ../../docs/README.md
- المعمارية: ../../docs/architecture.md