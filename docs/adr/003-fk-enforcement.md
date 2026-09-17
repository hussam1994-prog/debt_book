# ADR 003: تفعيل Foreign Keys في SQLite

**التاريخ:** 2026-09-17
**الحالة:** ✅ معتمد
**السياق:** Drift + SQLite + Foreign Keys

---

## السياق (Context)

اكتشفنا أن **قيود Foreign Keys لا تُفرَض** في قاعدة بيانات SQLite،
حتى مع تعريف `references()` في الجداول.

اختبار `recordPayment rolls back on failure` كان يفشل لأن الإدراج
بدين غير موجود كان **ينجح** بدلاً من أن يرمي استثناء.

---

## المشكلة (Problem)

1. **SQLite لا يفعّل FK افتراضياً** — يتطلب `PRAGMA foreign_keys = ON`
2. **`PRAGMA` غير دائم** — يُعاد ضبطه في كل اتصال جديد
3. **`MigrationStrategy.beforeOpen` لا يكفي** — يُنفّذ داخل معاملة،
   و SQLite يتجاهل PRAGMA داخل المعاملات
4. **`drift_dev` يولّد DDL بدون `REFERENCES`** رغم وجود `.references()`
   في الكود — بسبب تعارض إصدارات `analyzer` مع SDK 3.13

---

## القرار (Decision)

### 1. استخدام NativeDatabase.setup لتفعيل FK

```dart
AppDatabase.memory() : super(NativeDatabase.memory(
  setup: (db) => db.execute('PRAGMA foreign_keys = ON'),
));

2. تفعيل FK في _openConnection أيضاً
```dart

return NativeDatabase.createInBackground(
  file,
  setup: (db) => db.execute('PRAGMA foreign_keys = ON'),
);

3. الاحتفاظ بـ beforeOpen كطبقة ثانية
```dart

beforeOpen: (details) async {
  await customStatement('PRAGMA foreign_keys = ON');
},

4. ترقية drift و drift_dev إلى 2.35.0 + sqlite3 إلى 3.6.0

لأن الإصدارات الأقدم لا تولّد REFERENCES في DDL مع SDK 3.13.
النتائج (Consequences)
✅ الإيجابيات

    FK يُفرَض الآن في جميع الجداول (8 FK)

    اختبار recordPayment rolls back on failure ينجح

    سلامة البيانات مضمونة على مستوى SQLite

    لا حاجة لـ customConstraint (SQL خام)

    .references() يبقى في الكود — تجريد ORM كامل

⚠️ السلبيات

    حاجة لترقية sqlite3 إلى ^3.6.0 (كسر محتمل مع حزم قديمة)

    drift_dev 2.35+ فقط

    DDL في .g.dart أطول قليلاً

🔄 البدائل المرفوضة

    customConstraint: يخالف الفلسفة (SQL خام بدل ORM)

    الاعتماد على منطق Dart فقط: لا يحمي من الأخطاء المباشرة في SQL

    اختبار rollback بـ duplicate PK: يختبر سلوكاً آخر (ليس FK)

المراجع (References)

    Drift — Foreign Keys

    SQLite — PRAGMA foreign_keys

    lib/core/database/app_database.dart

    test/repositories/payment_repository_impl_test.dart

