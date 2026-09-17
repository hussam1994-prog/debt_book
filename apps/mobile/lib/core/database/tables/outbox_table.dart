// lib/core/database/tables/outbox_table.dart
//
// جدول Outbox: يسجل كل عملية كتابة محلية (إضافة/تعديل/حذف) قبل رفعها للسحابة.
// كل صف يمثل "نية" (intent) لتغيير يجب أن يُطبّق على Supabase لاحقًا.
//
// ملاحظات تصميمية:
// - client_id هو idempotency key: UUID يُنشأ محليًا عند إنشاء العملية،
//   ويُرسل مع الطلب للسحابة. لو تكرر الإرسال (مثلاً بسبب انقطاع شبكة بعد نجاح الرفع)،
//   يتجاهله السيرفر بدل ما يكرر البيانات (عبر UNIQUE constraint أو upsert على client_id).
// - retry_count + next_retry_at يدعمان Exponential Backoff.
// - status يفصل بين: pending / in_flight / failed / synced
//   (بدل الاعتماد فقط على synced_at nullable) لتفادي حالات السباق (race conditions)
//   لو أكثر من Timer شغال بنفس الوقت.

import 'package:drift/drift.dart';

/// أنواع العمليات المدعومة على مستوى Outbox
enum OutboxOperation { insert, update, delete }

/// حالة عنصر الـ Outbox
enum OutboxStatus { pending, inFlight, failed, synced }

@DataClassName('OutboxItem')
class OutboxTable extends Table {
  @override
  String get tableName => 'outbox';

  /// المعرف المحلي التلقائي (autoincrement) - لا علاقة له بالسحابة
  IntColumn get id => integer().autoIncrement()();

  /// idempotency key - UUID يُنشأ عند إنشاء العملية ولا يتغير أبدًا
  TextColumn get clientId => text().unique()();

  /// نوع الكيان: 'person' | 'debt' | 'payment' | 'ledger_entry' | 'installment'
  TextColumn get entityType => text()();

  /// المعرف المحلي/السحابي للكيان المتأثر
  TextColumn get entityId => text()();

  /// نوع العملية: insert / update / delete
  TextColumn get operation => textEnum<OutboxOperation>()();

  /// الحمولة الكاملة (JSON) اللازمة لتنفيذ العملية على السحابة
  TextColumn get payloadJson => text()();

  /// حالة العنصر الحالية
  TextColumn get status =>
      textEnum<OutboxStatus>().withDefault(const Constant('pending'))();

  /// عدد محاولات الرفع الفاشلة
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// آخر رسالة خطأ (لأغراض التشخيص وعرضها للمستخدم عند الحاجة)
  TextColumn get lastError => text().nullable()();

  /// متى يُسمح بمحاولة رفع جديدة (لدعم exponential backoff)
  DateTimeColumn get nextRetryAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// وقت إنشاء العملية محليًا (يُستخدم أيضًا كترتيب أولوية الرفع - FIFO)
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// وقت تأكيد المزامنة الناجحة من السيرفر (null إن لم تكتمل بعد)
  DateTimeColumn get syncedAt => dateTime().nullable()();

  // ملاحظة: لا يجوز تعريف primaryKey هنا يدويًا، لأن id.autoIncrement()
  // يجعل هذا العمود المفتاح الأساسي تلقائيًا بـ Drift. تعريفه مرة ثانية
  // يسبب الخطأ: "Tables can't override primaryKey and use autoIncrement()".
}